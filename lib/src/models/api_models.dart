import 'work.dart';

class ApiPageMeta {
  const ApiPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.from,
    required this.to,
  });

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  factory ApiPageMeta.fromJson(Map<String, dynamic> json) {
    return ApiPageMeta(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      from: json['from'] as int?,
      to: json['to'] as int?,
    );
  }
}

class ApiPaginatedList<T> {
  const ApiPaginatedList({
    required this.items,
    required this.meta,
  });

  final List<T> items;
  final ApiPageMeta meta;
}

class GenreItem {
  const GenreItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.worksCount,
  });

  final int id;
  final String name;
  final String? icon;
  final int worksCount;

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '-',
      icon: json['icon'] as String?,
      worksCount: json['works_count'] as int? ?? 0,
    );
  }
}

class FaqItem {
  const FaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question'] as String? ?? '-',
      answer: json['answer'] as String? ?? '-',
    );
  }
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.summary,
  });

  final String title;
  final String summary;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] as String? ?? '-',
      summary: json['summary'] as String? ?? '-',
    );
  }
}

class PublicUserSummary {
  const PublicUserSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
  });

  final int id;
  final String name;
  final String role;
  final String? avatar;

  factory PublicUserSummary.fromJson(Map<String, dynamic> json) {
    return PublicUserSummary(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '-',
      role: json['role'] as String? ?? 'user',
      avatar: json['avatar'] as String?,
    );
  }
}

class ChapterSummary {
  const ChapterSummary({
    required this.id,
    required this.workId,
    required this.title,
    required this.chapterNumber,
    required this.hasTextContent,
    required this.excerpt,
    required this.imagesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.workTitle,
  });

  final int id;
  final int workId;
  final String title;
  final int chapterNumber;
  final bool hasTextContent;
  final String? excerpt;
  final int imagesCount;
  final int commentsCount;
  final DateTime? createdAt;
  final String? workTitle;

  factory ChapterSummary.fromJson(Map<String, dynamic> json) {
    final work = json['work'] as Map<String, dynamic>?;
    return ChapterSummary(
      id: json['id'] as int? ?? 0,
      workId: json['work_id'] as int? ?? 0,
      title: json['title'] as String? ?? '-',
      chapterNumber: json['chapter_number'] as int? ?? 0,
      hasTextContent: json['has_text_content'] as bool? ?? false,
      excerpt: json['excerpt'] as String?,
      imagesCount: json['images_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at'] as String?),
      workTitle: work?['title'] as String?,
    );
  }
}

class ChapterComment {
  const ChapterComment({
    required this.id,
    required this.chapterId,
    required this.content,
    required this.user,
    required this.createdAt,
  });

  final int id;
  final int chapterId;
  final String content;
  final PublicUserSummary? user;
  final DateTime? createdAt;

  factory ChapterComment.fromJson(Map<String, dynamic> json) {
    return ChapterComment(
      id: json['id'] as int? ?? 0,
      chapterId: json['chapter_id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      user: json['user'] is Map<String, dynamic>
          ? PublicUserSummary.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at'] as String?),
    );
  }
}

class BookmarkEntry {
  const BookmarkEntry({
    required this.work,
    required this.lastChapterRead,
  });

  final WorkSummary work;
  final int? lastChapterRead;

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) {
    return BookmarkEntry(
      work: WorkSummary.fromJson(json['work'] as Map<String, dynamic>),
      lastChapterRead: json['last_chapter_read'] as int?,
    );
  }
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.lastReadAt,
    required this.work,
    required this.chapter,
  });

  final int id;
  final DateTime? lastReadAt;
  final WorkSummary work;
  final ChapterSummary chapter;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as int? ?? 0,
      lastReadAt: _parseDate(json['last_read_at'] as String?),
      work: WorkSummary.fromJson(json['work'] as Map<String, dynamic>),
      chapter: ChapterSummary.fromJson(json['chapter'] as Map<String, dynamic>),
    );
  }
}

class CollectionHistoryEntry {
  const CollectionHistoryEntry({
    required this.lastReadAt,
    required this.work,
    required this.chapter,
  });

  final DateTime? lastReadAt;
  final WorkSummary? work;
  final ChapterSummary? chapter;

  factory CollectionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CollectionHistoryEntry(
      lastReadAt: _parseDate(json['last_read_at'] as String?),
      work: json['work'] is Map<String, dynamic>
          ? WorkSummary.fromJson(json['work'] as Map<String, dynamic>)
          : null,
      chapter: json['chapter'] is Map<String, dynamic>
          ? ChapterSummary.fromJson(json['chapter'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CollectionBundle {
  const CollectionBundle({
    required this.isGuest,
    required this.bookmarkedWorks,
    required this.recentHistory,
    required this.recommendedWorks,
    required this.novels,
    required this.comics,
    required this.featuredWorks,
    required this.highlightGenres,
  });

  final bool isGuest;
  final List<WorkSummary> bookmarkedWorks;
  final List<CollectionHistoryEntry> recentHistory;
  final List<WorkSummary> recommendedWorks;
  final List<WorkSummary> novels;
  final List<WorkSummary> comics;
  final List<WorkSummary> featuredWorks;
  final List<GenreItem> highlightGenres;

  factory CollectionBundle.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    }

    return CollectionBundle(
      isGuest: json['is_guest'] as bool? ?? false,
      bookmarkedWorks: mapList('bookmarked_works', WorkSummary.fromJson),
      recentHistory: mapList('recent_history', CollectionHistoryEntry.fromJson),
      recommendedWorks: mapList('recommended_works', WorkSummary.fromJson),
      novels: mapList('novels', WorkSummary.fromJson),
      comics: mapList('comics', WorkSummary.fromJson),
      featuredWorks: mapList('featured_works', WorkSummary.fromJson),
      highlightGenres: mapList('highlight_genres', GenreItem.fromJson),
    );
  }
}

class NotificationBundle {
  const NotificationBundle({
    required this.latestReleases,
    required this.chapterUpdates,
    required this.creatorFeed,
  });

  final List<WorkSummary> latestReleases;
  final List<ChapterSummary> chapterUpdates;
  final List<ChapterComment> creatorFeed;

  factory NotificationBundle.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[key] as List<dynamic>? ?? const [];
      return raw.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    }

    return NotificationBundle(
      latestReleases: mapList('latest_releases', WorkSummary.fromJson),
      chapterUpdates: mapList('chapter_updates', ChapterSummary.fromJson),
      creatorFeed: mapList('creator_feed', ChapterComment.fromJson),
    );
  }
}

class HomeFeed {
  const HomeFeed({
    required this.items,
    required this.meta,
    required this.genres,
    required this.selectedGenre,
  });

  final List<WorkSummary> items;
  final ApiPageMeta meta;
  final List<GenreItem> genres;
  final GenreItem? selectedGenre;
}

class RoleOption {
  const RoleOption({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory RoleOption.fromJson(Map<String, dynamic> json) {
    return RoleOption(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '-',
    );
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalWorks,
    required this.pendingWorks,
    required this.approvedWorks,
    required this.draftWorks,
    required this.usersCount,
    required this.genresCount,
    required this.chaptersCount,
    required this.chapterImagesCount,
    required this.recentUsers,
  });

  final int totalWorks;
  final int pendingWorks;
  final int approvedWorks;
  final int draftWorks;
  final int usersCount;
  final int genresCount;
  final int chaptersCount;
  final int chapterImagesCount;
  final List<PublicUserSummary> recentUsers;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final works = json['works'] as Map<String, dynamic>? ?? const {};
    final rawRecentUsers = json['recent_users'] as List<dynamic>? ?? const [];
    return AdminDashboardData(
      totalWorks: works['total'] as int? ?? 0,
      pendingWorks: works['pending'] as int? ?? 0,
      approvedWorks: works['approved'] as int? ?? 0,
      draftWorks: works['draft'] as int? ?? 0,
      usersCount: json['users'] as int? ?? 0,
      genresCount: json['genres'] as int? ?? 0,
      chaptersCount: json['chapters'] as int? ?? 0,
      chapterImagesCount: json['chapter_images'] as int? ?? 0,
      recentUsers: rawRecentUsers
          .map((item) =>
              PublicUserSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AdminUserItem {
  const AdminUserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.role,
    required this.roleId,
    required this.createdAt,
    required this.worksCount,
    required this.bookmarksCount,
    required this.commentsCount,
  });

  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;
  final int? roleId;
  final DateTime? createdAt;
  final int worksCount;
  final int bookmarksCount;
  final int commentsCount;

  factory AdminUserItem.fromJson(Map<String, dynamic> json) {
    return AdminUserItem(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '-',
      email: json['email'] as String? ?? '-',
      avatar: json['avatar'] as String?,
      role: json['role'] as String? ?? 'user',
      roleId: json['role_id'] as int?,
      createdAt: _parseDate(json['created_at'] as String?),
      worksCount: json['works_count'] as int? ?? 0,
      bookmarksCount: json['bookmarks_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
    );
  }
}

class AdminUsersResponse {
  const AdminUsersResponse({
    required this.users,
    required this.roles,
    required this.meta,
  });

  final List<AdminUserItem> users;
  final List<RoleOption> roles;
  final ApiPageMeta meta;
}

class WorksSummary {
  const WorksSummary({
    required this.total,
    required this.draft,
    required this.pending,
    required this.approved,
  });

  final int total;
  final int draft;
  final int pending;
  final int approved;

  factory WorksSummary.fromJson(Map<String, dynamic> json) {
    return WorksSummary(
      total: json['total'] as int? ?? 0,
      draft: json['draft'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      approved: json['approved'] as int? ?? 0,
    );
  }
}

class WorksPageResponse {
  const WorksPageResponse({
    required this.items,
    required this.meta,
    required this.summary,
  });

  final List<WorkSummary> items;
  final ApiPageMeta meta;
  final WorksSummary summary;
}

class UploaderDashboardData {
  const UploaderDashboardData({
    required this.summary,
    required this.recentWorks,
    required this.genres,
  });

  final WorksSummary summary;
  final List<WorkSummary> recentWorks;
  final List<GenreItem> genres;

  factory UploaderDashboardData.fromJson(Map<String, dynamic> json) {
    final rawRecentWorks = json['recent_works'] as List<dynamic>? ?? const [];
    final rawGenres = json['genres'] as List<dynamic>? ?? const [];
    return UploaderDashboardData(
      summary: WorksSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? const {}),
      recentWorks: rawRecentWorks
          .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      genres: rawGenres
          .map((item) => GenreItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
