import 'package:flutter/material.dart';

import '../models/library_entry.dart';
import '../models/work.dart';
import '../services/library_store.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';
import 'chapter_reader_page.dart';

class WorkDetailPage extends StatefulWidget {
  const WorkDetailPage({
    super.key,
    required this.apiClient,
    required this.work,
  });

  final UjikomApiClient apiClient;
  final WorkSummary work;

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  final LibraryStore _libraryStore = LibraryStore();
  late Future<WorkDetail> _future;
  bool _isBookmarked = false;
  ReadingHistoryEntry? _latestHistory;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _loadLibraryState();
  }

  Future<WorkDetail> _load() {
    return widget.apiClient.fetchWorkDetail(widget.work.id);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
    await _loadLibraryState();
  }

  Future<void> _loadLibraryState() async {
    if (widget.apiClient.hasAuthToken) {
      try {
        final bookmarks = await widget.apiClient.fetchBookmarks();
        final history = await widget.apiClient.fetchHistory();
        if (!mounted) {
          return;
        }

        final matchingHistory =
            history.where((item) => item.work.id == widget.work.id);

        setState(() {
          _isBookmarked =
              bookmarks.any((item) => item.work.id == widget.work.id);
          _latestHistory = matchingHistory.isEmpty
              ? null
              : ReadingHistoryEntry(
                  workId: matchingHistory.first.work.id,
                  workTitle: matchingHistory.first.work.title,
                  workType: matchingHistory.first.work.type,
                  workCoverUrl: matchingHistory.first.work.coverUrl,
                  chapterId: matchingHistory.first.chapter.id,
                  chapterNumber: matchingHistory.first.chapter.chapterNumber,
                  chapterTitle: matchingHistory.first.chapter.title,
                  readAtIso:
                      matchingHistory.first.lastReadAt?.toIso8601String() ??
                          DateTime.now().toIso8601String(),
                );
        });
        return;
      } catch (_) {
        // Fall back to local storage when remote sync is unavailable.
      }
    }

    final bookmarks = await _libraryStore.loadBookmarkIds();
    final history = await _libraryStore.loadHistory();
    if (!mounted) {
      return;
    }

    final matchingEntries =
        history.where((item) => item.workId == widget.work.id);

    setState(() {
      _isBookmarked = bookmarks.contains(widget.work.id);
      _latestHistory = matchingEntries.isEmpty ? null : matchingEntries.first;
    });
  }

  Future<void> _toggleBookmark() async {
    if (widget.apiClient.hasAuthToken) {
      if (_isBookmarked) {
        await widget.apiClient.removeBookmark(widget.work.id);
      } else {
        await widget.apiClient.addBookmark(widget.work.id);
      }
    } else {
      await _libraryStore.toggleBookmark(widget.work.id);
    }
    await _loadLibraryState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<WorkDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              ),
            );
          }

          final detail = snapshot.requireData;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar.large(
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xFF0F1419),
                  foregroundColor: const Color(0xFFE8EAED),
                  title: Text(detail.title),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (detail.coverUrl != null &&
                            detail.coverUrl!.isNotEmpty)
                          NetworkCover(
                            imageUrl: detail.coverUrl!,
                            fit: BoxFit.cover,
                            errorWidget:
                                const ColoredBox(color: Color(0xFF1A1F2E)),
                          )
                        else
                          const ColoredBox(color: Color(0xFF1A1F2E)),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.78),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  expandedHeight: 300,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetaChip(label: detail.type.toUpperCase()),
                            _MetaChip(
                                label: '${detail.chapters.length} chapter'),
                            if (detail.author != null)
                              _MetaChip(label: detail.author!),
                          ],
                        ),
                        if (detail.genres.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            detail.genres.join(' • '),
                            style: const TextStyle(
                              color: Color(0xFF48C9B0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: _toggleBookmark,
                              icon: Icon(
                                _isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                              ),
                              label: Text(
                                _isBookmarked ? 'Tersimpan' : 'Simpan Bookmark',
                              ),
                            ),
                            if (_latestHistory != null)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => ChapterReaderPage(
                                        apiClient: widget.apiClient,
                                        workId: detail.id,
                                        chapterId: _latestHistory!.chapterId,
                                      ),
                                    ),
                                  ).then((_) => _loadLibraryState());
                                },
                                icon: const Icon(Icons.history_rounded),
                                label: Text(
                                  'Lanjut Ch ${_latestHistory!.chapterNumber}',
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          detail.description?.trim().isNotEmpty == true
                              ? detail.description!
                              : 'Belum ada deskripsi untuk work ini.',
                          style: const TextStyle(
                            height: 1.75,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Daftar Chapter',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE8EAED),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (detail.chapters.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Belum ada chapter yang tersedia.'),
                            ),
                          ),
                        for (final chapter in detail.chapters) ...[
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              title: Text(
                                chapter.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE8EAED),
                                ),
                              ),
                              subtitle: Text(
                                'Chapter ${chapter.chapterNumber}'
                                '${chapter.hasTextContent ? ' • tersedia teks' : ''}',
                                style: const TextStyle(
                                  color: Color(0xFF9AA0A6),
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChapterReaderPage(
                                      apiClient: widget.apiClient,
                                      workId: detail.id,
                                      chapterId: chapter.id,
                                    ),
                                  ),
                                ).then((_) => _loadLibraryState());
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFF20473E),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.white70,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE8EAED)),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
