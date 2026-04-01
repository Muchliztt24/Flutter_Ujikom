import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../models/work.dart';
import '../services/ujikom_api_client.dart';
import '../widgets/network_cover.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _AsyncScaffold<List<FaqItem>>(
      title: 'FAQ',
      subtitle: 'Jawaban singkat langsung dari API Laravel.',
      future: apiClient.fetchFaq(),
      builder: (items) => items
          .map(
            (item) => _InfoCard(
              title: item.question,
              body: item.answer,
            ),
          )
          .toList(),
    );
  }
}

class NewsPage extends StatelessWidget {
  const NewsPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _AsyncScaffold<List<NewsItem>>(
      title: 'News',
      subtitle: 'Sorotan dan pembaruan terbaru dari backend Nokomi.',
      future: apiClient.fetchNews(),
      builder: (items) => items
          .map(
            (item) => _InfoCard(
              title: item.title,
              body: item.summary,
            ),
          )
          .toList(),
    );
  }
}

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    if (!apiClient.hasAuthToken) {
      return const _AuthRequiredPage(
        title: 'Bookmarks',
        subtitle: 'Login dulu untuk melihat bookmark yang tersimpan di akunmu.',
      );
    }

    return _AsyncScaffold<List<BookmarkEntry>>(
      title: 'Bookmarks',
      subtitle: 'Bookmark akunmu langsung dari API Laravel.',
      future: apiClient.fetchBookmarks(),
      builder: (items) {
        if (items.isEmpty) {
          return const [
            _InfoCard(
              title: 'Belum ada bookmark',
              body: 'Karya yang kamu simpan akan muncul di sini.',
            ),
          ];
        }

        return items
            .map(
              (entry) => _WorkRow(
                work: entry.work,
                trailingText: entry.lastChapterRead == null
                    ? null
                    : 'Terakhir di ch ${entry.lastChapterRead}',
              ),
            )
            .toList();
      },
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    if (!apiClient.hasAuthToken) {
      return const _AuthRequiredPage(
        title: 'Riwayat Baca',
        subtitle: 'Login dulu untuk melihat progres baca dari akunmu.',
      );
    }

    return _AsyncScaffold<List<HistoryEntry>>(
      title: 'Riwayat Baca',
      subtitle: 'Progress baca yang tersimpan di server.',
      future: apiClient.fetchHistory(),
      builder: (items) {
        if (items.isEmpty) {
          return const [
            _InfoCard(
              title: 'Riwayat masih kosong',
              body: 'Chapter yang kamu baca akan muncul di sini.',
            ),
          ];
        }

        return items.map((entry) => _HistoryRow(entry: entry)).toList();
      },
    );
  }
}

class CollectionPage extends StatelessWidget {
  const CollectionPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _AsyncScaffold<CollectionBundle>(
      title: 'Collection',
      subtitle: 'Bookmark, progres baca, dan rekomendasi dari API Laravel.',
      future: apiClient.fetchCollection(),
      builder: (bundle) => [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MiniStat(
              label: bundle.isGuest ? 'Mode' : 'Bookmark',
              value:
                  bundle.isGuest ? 'Guest' : '${bundle.bookmarkedWorks.length}',
            ),
            _MiniStat(
              label: 'Riwayat',
              value: '${bundle.recentHistory.length}',
            ),
            _MiniStat(
              label: 'Rekomendasi',
              value: '${bundle.recommendedWorks.length}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _SectionTitle('Lanjutkan Membaca'),
        if (bundle.recentHistory.isEmpty)
          const _InfoCard(
            title: 'Belum ada riwayat',
            body: 'Progress baca akunmu akan muncul di sini.',
          )
        else
          ...bundle.recentHistory
              .map((entry) => _CollectionHistoryRow(entry: entry)),
        const _SectionTitle('Karya Rekomendasi'),
        if (bundle.recommendedWorks.isEmpty)
          const _InfoCard(
            title: 'Belum ada rekomendasi',
            body: 'Daftar rekomendasi akan muncul saat data tersedia.',
          )
        else
          ...bundle.recommendedWorks.map((work) => _WorkRow(work: work)),
        const _SectionTitle('Genre Pilihan'),
        if (bundle.highlightGenres.isEmpty)
          const _InfoCard(
            title: 'Belum ada genre unggulan',
            body: 'Genre populer akan muncul di sini.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: bundle.highlightGenres
                .map(
                  (genre) => Chip(
                    label: Text('${genre.name} • ${genre.worksCount}'),
                    backgroundColor: const Color(0xFF1A1F2E),
                    side: const BorderSide(color: Color(0xFF2D3748)),
                    labelStyle: const TextStyle(color: Color(0xFFE8EAED)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class GenrePage extends StatelessWidget {
  const GenrePage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _AsyncScaffold<List<GenreItem>>(
      title: 'Genre',
      subtitle: 'Semua genre yang tersedia dari API Laravel.',
      future: apiClient.fetchGenres(),
      builder: (items) {
        if (items.isEmpty) {
          return const [
            _InfoCard(
              title: 'Genre belum tersedia',
              body: 'Data genre akan muncul saat backend mengirimkannya.',
            ),
          ];
        }

        return [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map(
                  (item) => Chip(
                    label: Text('${item.name} • ${item.worksCount}'),
                    backgroundColor: const Color(0xFF1A1F2E),
                    side: const BorderSide(color: Color(0xFF2D3748)),
                    labelStyle: const TextStyle(color: Color(0xFFE8EAED)),
                  ),
                )
                .toList(),
          ),
        ];
      },
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.apiClient,
  });

  final UjikomApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return _AsyncScaffold<NotificationBundle>(
      title: 'Notifications',
      subtitle: apiClient.hasAuthToken
          ? 'Update akun dan karya dari API Laravel.'
          : 'Rilisan terbaru untuk pengunjung.',
      future: apiClient.fetchNotifications(),
      builder: (bundle) => [
        const _SectionTitle('Rilisan Terbaru'),
        if (bundle.latestReleases.isEmpty)
          const _InfoCard(
            title: 'Belum ada rilisan',
            body: 'Karya terbaru akan muncul di sini.',
          )
        else
          ...bundle.latestReleases.map((work) => _WorkRow(work: work)),
        const _SectionTitle('Update Chapter'),
        if (bundle.chapterUpdates.isEmpty)
          const _InfoCard(
            title: 'Belum ada update chapter',
            body: 'Update chapter karya yang kamu ikuti akan muncul di sini.',
          )
        else
          ...bundle.chapterUpdates.map((entry) => _ChapterRow(entry: entry)),
        if (apiClient.hasAuthToken) ...[
          const _SectionTitle('Creator Feed'),
          if (bundle.creatorFeed.isEmpty)
            const _InfoCard(
              title: 'Belum ada interaksi baru',
              body: 'Komentar pembaca pada karya milikmu akan muncul di sini.',
            )
          else
            ...bundle.creatorFeed.map((entry) => _CommentRow(entry: entry)),
        ],
      ],
    );
  }
}

class _AsyncScaffold<T> extends StatelessWidget {
  const _AsyncScaffold({
    required this.title,
    required this.subtitle,
    required this.future,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final Future<T> future;
  final List<Widget> Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorBody(message: snapshot.error.toString());
          }

          final children = builder(snapshot.requireData);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE8EAED),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9AA0A6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              ...children
                  .expand((child) => [child, const SizedBox(height: 14)]),
            ],
          );
        },
      ),
    );
  }
}

class _AuthRequiredPage extends StatelessWidget {
  const _AuthRequiredPage({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE8EAED),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF9AA0A6), height: 1.5),
          ),
          const SizedBox(height: 22),
          const _InfoCard(
            title: 'Perlu login',
            body: 'Fitur ini memakai endpoint akun sehingga butuh sesi login.',
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

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
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8EAED),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF9AA0A6),
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFFE8EAED),
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9AA0A6)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE8EAED),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.work,
    this.trailingText,
  });

  final WorkSummary work;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2D3748)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 96,
              child: work.coverUrl != null && work.coverUrl!.isNotEmpty
                  ? NetworkCover(
                      imageUrl: work.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: const Color(0xFF20473E)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  work.title,
                  style: const TextStyle(
                    color: Color(0xFFE8EAED),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  work.author ?? '-',
                  style: const TextStyle(color: Color(0xFF48C9B0)),
                ),
                const SizedBox(height: 6),
                Text(
                  trailingText ??
                      (work.description?.trim().isNotEmpty == true
                          ? work.description!
                          : 'Belum ada deskripsi.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF9AA0A6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: entry.work.title,
      body:
          'Chapter ${entry.chapter.chapterNumber} • ${entry.chapter.title}\n${entry.lastReadAt?.toLocal() ?? '-'}',
    );
  }
}

class _CollectionHistoryRow extends StatelessWidget {
  const _CollectionHistoryRow({required this.entry});

  final CollectionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: entry.work?.title ?? 'Riwayat',
      body:
          'Chapter ${entry.chapter?.chapterNumber ?? '-'} • ${entry.chapter?.title ?? '-'}\n${entry.lastReadAt?.toLocal() ?? '-'}',
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.entry});

  final ChapterSummary entry;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: entry.workTitle == null
          ? entry.title
          : '${entry.workTitle} • ${entry.title}',
      body:
          'Chapter ${entry.chapterNumber} • ${entry.imagesCount} gambar • ${entry.commentsCount} komentar',
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.entry});

  final ChapterComment entry;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: entry.user?.name ?? 'Komentar',
      body: entry.content,
    );
  }
}
