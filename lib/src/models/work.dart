class WorkSummary {
  const WorkSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.coverUrl,
    required this.author,
    required this.genres,
    required this.chaptersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String type;
  final String status;
  final String? coverUrl;
  final String? author;
  final List<String> genres;
  final int chaptersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isComic => type.toLowerCase() == 'comic';

  factory WorkSummary.fromJson(Map<String, dynamic> json) {
    final rawGenres = json['genres'] as List<dynamic>? ?? const [];

    return WorkSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      coverUrl: json['cover_url'] as String?,
      author: json['author'] as String?,
      genres: rawGenres.map((item) => item.toString()).toList(),
      chaptersCount: json['chapters_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
    );
  }
}

class WorkChapter {
  const WorkChapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.hasTextContent,
    required this.createdAt,
  });

  final int id;
  final String title;
  final int chapterNumber;
  final bool hasTextContent;
  final DateTime? createdAt;

  factory WorkChapter.fromJson(Map<String, dynamic> json) {
    return WorkChapter(
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      chapterNumber: json['chapter_number'] as int? ?? 0,
      hasTextContent: json['has_text_content'] as bool? ?? false,
      createdAt: _parseDate(json['created_at'] as String?),
    );
  }
}

class WorkDetail extends WorkSummary {
  const WorkDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.status,
    required super.coverUrl,
    required super.author,
    required super.genres,
    required super.chaptersCount,
    required super.createdAt,
    required super.updatedAt,
    required this.chapters,
  });

  final List<WorkChapter> chapters;

  factory WorkDetail.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'] as List<dynamic>? ?? const [];

    return WorkDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? '-',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      coverUrl: json['cover_url'] as String?,
      author: json['author'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      chaptersCount: json['chapters_count'] as int? ?? 0,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
      chapters: rawChapters
          .map((item) => WorkChapter.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber)),
    );
  }
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
