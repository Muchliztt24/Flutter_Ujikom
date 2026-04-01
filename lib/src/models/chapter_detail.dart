class ChapterImage {
  const ChapterImage({
    required this.id,
    required this.pageNumber,
    required this.imageUrl,
  });

  final int id;
  final int pageNumber;
  final String imageUrl;

  factory ChapterImage.fromJson(Map<String, dynamic> json) {
    return ChapterImage(
      id: json['id'] as int,
      pageNumber: json['page_number'] as int? ?? 0,
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class ChapterDetail {
  const ChapterDetail({
    required this.id,
    required this.workId,
    required this.workTitle,
    required this.title,
    required this.chapterNumber,
    required this.textContent,
    required this.images,
  });

  final int id;
  final int workId;
  final String workTitle;
  final String title;
  final int chapterNumber;
  final String? textContent;
  final List<ChapterImage> images;

  bool get hasImages => images.isNotEmpty;

  bool get hasTextContent =>
      textContent != null && textContent!.trim().isNotEmpty;

  factory ChapterDetail.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];
    return ChapterDetail(
      id: json['id'] as int,
      workId: json['work_id'] as int? ?? 0,
      workTitle: json['work_title'] as String? ?? '-',
      title: json['title'] as String? ?? '-',
      chapterNumber: json['chapter_number'] as int? ?? 0,
      textContent: json['text_content'] as String?,
      images: rawImages
          .map((item) => ChapterImage.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber)),
    );
  }
}
