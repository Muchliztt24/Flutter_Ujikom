class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.workId,
    required this.workTitle,
    required this.workType,
    required this.workCoverUrl,
    required this.chapterId,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.readAtIso,
  });

  final int workId;
  final String workTitle;
  final String workType;
  final String? workCoverUrl;
  final int chapterId;
  final int chapterNumber;
  final String chapterTitle;
  final String readAtIso;

  DateTime get readAt => DateTime.tryParse(readAtIso) ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'work_id': workId,
      'work_title': workTitle,
      'work_type': workType,
      'work_cover_url': workCoverUrl,
      'chapter_id': chapterId,
      'chapter_number': chapterNumber,
      'chapter_title': chapterTitle,
      'read_at_iso': readAtIso,
    };
  }

  factory ReadingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReadingHistoryEntry(
      workId: json['work_id'] as int,
      workTitle: json['work_title'] as String? ?? '-',
      workType: json['work_type'] as String? ?? 'novel',
      workCoverUrl: json['work_cover_url'] as String?,
      chapterId: json['chapter_id'] as int,
      chapterNumber: json['chapter_number'] as int? ?? 0,
      chapterTitle: json['chapter_title'] as String? ?? '-',
      readAtIso:
          json['read_at_iso'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
