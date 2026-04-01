import 'package:flutter/material.dart';

import '../models/chapter_detail.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';

class ChapterReaderPage extends StatefulWidget {
  const ChapterReaderPage({
    super.key,
    required this.apiClient,
    required this.workId,
    required this.chapterId,
  });

  final UjikomApiClient apiClient;
  final int workId;
  final int chapterId;

  @override
  State<ChapterReaderPage> createState() => _ChapterReaderPageState();
}

class _ChapterReaderPageState extends State<ChapterReaderPage> {
  late Future<ChapterDetail> _future;
  bool _immersive = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ChapterDetail> _load() {
    return widget.apiClient.fetchChapter(
      workId: widget.workId,
      chapterId: widget.chapterId,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChapterDetail>(
      future: _future,
      builder: (context, snapshot) {
        final chapter = snapshot.data;
        final hasImages = chapter?.hasImages ?? false;
        final useDarkReader = hasImages || _immersive;

        return Theme(
          data: Theme.of(context).copyWith(
            scaffoldBackgroundColor: useDarkReader
                ? const Color(0xFF020617)
                : const Color(0xFFF8FAFC),
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
                  backgroundColor: useDarkReader
                      ? const Color(0xFF020617)
                      : Colors.transparent,
                  foregroundColor:
                      useDarkReader ? Colors.white : const Color(0xFF0F172A),
                ),
          ),
          child: Scaffold(
            appBar: _immersive
                ? null
                : AppBar(
                    title: Text(chapter?.title ?? 'Baca Chapter'),
                    actions: [
                      IconButton(
                        onPressed: () =>
                            setState(() => _immersive = !_immersive),
                        icon: Icon(
                          useDarkReader
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                        ),
                        tooltip: 'Mode fokus',
                      ),
                    ],
                  ),
            body: _buildBody(snapshot),
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<ChapterDetail> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _ErrorState(
        message: snapshot.error.toString(),
        onRetry: _refresh,
      );
    }

    final chapter = snapshot.requireData;

    return GestureDetector(
      onTap: chapter.hasImages
          ? () => setState(() => _immersive = !_immersive)
          : null,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (!_immersive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _HeaderCard(chapter: chapter),
                ),
              ),
            if (chapter.hasImages)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, _immersive ? 12 : 16, 12, 16),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final image = chapter.images[index];
                    return _ImagePage(
                      image: image,
                      immersive: _immersive,
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemCount: chapter.images.length,
                ),
              ),
            if (chapter.hasTextContent)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _TextReaderCard(
                    title: chapter.title,
                    content: chapter.textContent!,
                  ),
                ),
              ),
            if (!chapter.hasImages && !chapter.hasTextContent)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                          'Chapter ini belum memiliki gambar maupun konten teks.'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.chapter});

  final ChapterDetail chapter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter.workTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF0F766E),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              chapter.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Chapter ${chapter.chapterNumber}'),
                _InfoChip(label: '${chapter.images.length} halaman'),
                _InfoChip(
                    label: chapter.hasTextContent ? 'Ada teks' : 'Tanpa teks'),
              ],
            ),
            if (chapter.hasImages) ...[
              const SizedBox(height: 12),
              const Text(
                'Tip: tap area reader untuk masuk atau keluar dari mode fokus.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImagePage extends StatelessWidget {
  const _ImagePage({
    required this.image,
    required this.immersive,
  });

  final ChapterImage image;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(immersive ? 10 : 22),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.topLeft,
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: NetworkCover(
                imageUrl: image.imageUrl,
                fit: BoxFit.fitWidth,
                errorWidget: Container(
                  height: 220,
                  color: const Color(0xFF1E293B),
                  alignment: Alignment.center,
                  child: Text(
                    'Gagal memuat halaman ${image.pageNumber}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Hal. ${image.pageNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextReaderCard extends StatelessWidget {
  const _TextReaderCard({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              content,
              style: const TextStyle(
                height: 1.85,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFDCFCE7),
      labelStyle: const TextStyle(
        color: Color(0xFF166534),
        fontWeight: FontWeight.w600,
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
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
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
