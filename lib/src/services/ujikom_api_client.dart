import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/api_models.dart';
import '../models/auth_user.dart';
import '../models/chapter_detail.dart';
import '../models/work.dart';

class UjikomApiClient {
  UjikomApiClient({
    required String baseUrl,
    this.authToken,
    http.Client? httpClient,
  })  : _baseUrl = _normalizeBaseUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final String? authToken;
  final http.Client _httpClient;

  bool get hasAuthToken => authToken != null && authToken!.isNotEmpty;

  UjikomApiClient copyWith({
    String? baseUrl,
    String? authToken,
  }) {
    return UjikomApiClient(
      baseUrl: baseUrl ?? _baseUrl,
      authToken: authToken ?? this.authToken,
      httpClient: _httpClient,
    );
  }

  Future<HomeFeed> fetchHome({
    int? genreId,
    int perPage = 12,
  }) async {
    final json = await _getJson(
      '/home',
      queryParameters: {
        if (genreId != null) 'genre': '$genreId',
        'per_page': '$perPage',
      },
    );

    final rawGenres = json['genres'] as List<dynamic>? ?? const [];
    final rawData = json['data'] as List<dynamic>? ?? const [];
    final selectedGenreJson = json['selected_genre'] as Map<String, dynamic>?;

    return HomeFeed(
      items: rawData
          .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ApiPageMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
      genres: rawGenres
          .map((item) => GenreItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedGenre: selectedGenreJson == null
          ? null
          : GenreItem.fromJson(selectedGenreJson),
    );
  }

  Future<List<WorkSummary>> fetchWorks({
    String? query,
    String? type,
    int? genreId,
  }) async {
    final json = await _getJson(
      '/works',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (genreId != null) 'genre_id': '$genreId',
      },
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];

    return rawData
        .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<WorkSummary>> searchWorks({
    String? query,
    String? type,
    int? genreId,
  }) async {
    final json = await _getJson(
      '/search',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        if (genreId != null) 'genre_id': '$genreId',
      },
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];

    return rawData
        .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<GenreItem>> fetchGenres() async {
    final json = await _getJson('/genres');
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => GenreItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WorkDetail> fetchWorkDetail(int workId) async {
    final json = await _getJson('/works/$workId');
    return WorkDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ChapterDetail> fetchChapter({
    required int workId,
    required int chapterId,
  }) async {
    final json = await _getJson('/works/$workId/chapters/$chapterId');
    return ChapterDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<FaqItem>> fetchFaq() async {
    final json = await _getJson('/faq');
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<NewsItem>> fetchNews() async {
    final json = await _getJson('/news');
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CollectionBundle> fetchCollection() async {
    final path = hasAuthToken ? '/me/collection' : '/collection';
    final json = await _getJson(path, requiresAuth: hasAuthToken);
    return CollectionBundle.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<NotificationBundle> fetchNotifications() async {
    final path = hasAuthToken ? '/me/notifications' : '/notifications';
    final json = await _getJson(path, requiresAuth: hasAuthToken);
    return NotificationBundle.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<BookmarkEntry>> fetchBookmarks() async {
    final json = await _getJson('/bookmarks', requiresAuth: true);
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => BookmarkEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addBookmark(
    int workId, {
    int? lastChapterRead,
  }) async {
    await _postJson(
      '/works/$workId/bookmark',
      requiresAuth: true,
      body: {
        if (lastChapterRead != null) 'last_chapter_read': lastChapterRead,
      },
    );
  }

  Future<void> removeBookmark(int workId) async {
    await _deleteJson('/works/$workId/bookmark', requiresAuth: true);
  }

  Future<List<HistoryEntry>> fetchHistory() async {
    final json = await _getJson('/history', requiresAuth: true);
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> storeReadingProgress({
    required int workId,
    required int chapterId,
  }) async {
    await _postJson(
      '/works/$workId/chapters/$chapterId/progress',
      requiresAuth: true,
    );
  }

  Future<List<ChapterComment>> fetchChapterComments(int chapterId) async {
    final json = await _getJson('/chapters/$chapterId/comments');
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => ChapterComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChapterComment> postChapterComment({
    required int chapterId,
    required String content,
  }) async {
    final json = await _postJson(
      '/chapters/$chapterId/comments',
      requiresAuth: true,
      body: {'content': content},
    );
    return ChapterComment.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteComment(int commentId) async {
    await _deleteJson('/comments/$commentId', requiresAuth: true);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(json);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _postJson(
      '/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    return AuthSession.fromJson(json);
  }

  Future<AuthUser> fetchMe() async {
    final json = await _getJson('/me', requiresAuth: true);
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> updateMe({
    required String name,
    required String email,
  }) async {
    final json = await _patchJson(
      '/me',
      requiresAuth: true,
      body: {
        'name': name,
        'email': email,
      },
    );
    return AuthUser.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _postJson('/logout', requiresAuth: true);
  }

  Future<AdminDashboardData> fetchAdminDashboard() async {
    final json = await _getJson('/admin/dashboard', requiresAuth: true);
    return AdminDashboardData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<RoleOption>> fetchAdminRoles() async {
    final json = await _getJson('/admin/roles', requiresAuth: true);
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => RoleOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminUsersResponse> fetchAdminUsers({
    String? query,
    String? role,
    int? roleId,
    int perPage = 15,
  }) async {
    final json = await _getJson(
      '/admin/users',
      requiresAuth: true,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (role != null && role.isNotEmpty) 'role': role,
        if (roleId != null) 'role_id': '$roleId',
        'per_page': '$perPage',
      },
    );

    final users = (json['data'] as List<dynamic>? ?? const [])
        .map((item) => AdminUserItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .map((item) => RoleOption.fromJson(item as Map<String, dynamic>))
        .toList();

    return AdminUsersResponse(
      users: users,
      roles: roles,
      meta: ApiPageMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Future<AdminUserItem> updateAdminUser({
    required int userId,
    required String name,
    required String email,
    required int roleId,
  }) async {
    final json = await _patchJson(
      '/admin/users/$userId',
      requiresAuth: true,
      body: {
        'name': name,
        'email': email,
        'role_id': roleId,
      },
    );
    return AdminUserItem.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<GenreItem>> fetchAdminGenres({
    String? query,
  }) async {
    final json = await _getJson(
      '/admin/genres',
      requiresAuth: true,
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => GenreItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GenreItem> createAdminGenre(String name) async {
    final json = await _postJson(
      '/admin/genres',
      requiresAuth: true,
      body: {'name': name},
    );
    return GenreItem.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<GenreItem> updateAdminGenre({
    required int genreId,
    required String name,
  }) async {
    final json = await _patchJson(
      '/admin/genres/$genreId',
      requiresAuth: true,
      body: {'name': name},
    );
    return GenreItem.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAdminGenre(int genreId) async {
    await _deleteJson('/admin/genres/$genreId', requiresAuth: true);
  }

  Future<WorksPageResponse> fetchAdminWorks({
    String? status,
    String? type,
    String? query,
  }) async {
    final path = status == 'pending' ? '/admin/works/pending' : '/admin/works';
    final json = await _getJson(
      path,
      requiresAuth: true,
      queryParameters: {
        if (status != null && status != 'pending' && status.isNotEmpty)
          'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return WorksPageResponse(
      items: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ApiPageMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
      summary: WorksSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Future<List<ChapterSummary>> fetchAdminChapters({
    int? workId,
    String? type,
    String? query,
  }) async {
    final json = await _getJson(
      '/admin/chapters',
      requiresAuth: true,
      queryParameters: {
        if (workId != null) 'work_id': '$workId',
        if (type != null && type.isNotEmpty) 'type': type,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => ChapterSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteAdminChapter(int chapterId) async {
    await _deleteJson('/admin/chapters/$chapterId', requiresAuth: true);
  }

  Future<List<ChapterImageItem>> fetchAdminChapterImages({
    int? workId,
    int? chapterId,
  }) async {
    final json = await _getJson(
      '/admin/chapter-images',
      requiresAuth: true,
      queryParameters: {
        if (workId != null) 'work_id': '$workId',
        if (chapterId != null) 'chapter_id': '$chapterId',
      },
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => ChapterImageItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteAdminChapterImage(int imageId) async {
    await _deleteJson('/admin/chapter-images/$imageId', requiresAuth: true);
  }

  Future<void> approveAdminWork(int workId) async {
    await _postJson('/admin/works/$workId/approve', requiresAuth: true);
  }

  Future<void> rejectAdminWork(int workId) async {
    await _postJson('/admin/works/$workId/reject', requiresAuth: true);
  }

  Future<void> deleteAdminWork(int workId) async {
    await _deleteJson('/admin/works/$workId', requiresAuth: true);
  }

  Future<UploaderDashboardData> fetchUploaderDashboard() async {
    final json = await _getJson('/uploader/dashboard', requiresAuth: true);
    return UploaderDashboardData.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<WorksPageResponse> fetchUploaderWorks({
    String? status,
    String? type,
    String? query,
  }) async {
    final json = await _getJson(
      '/uploader/works',
      requiresAuth: true,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return WorksPageResponse(
      items: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => WorkSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ApiPageMeta.fromJson(
          json['meta'] as Map<String, dynamic>? ?? const {}),
      summary: WorksSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Future<WorkSummary> createUploaderWork({
    required String title,
    required String originalAuthor,
    required String type,
    required List<int> genreIds,
    String? description,
    String? coverPath,
  }) async {
    final json = await _sendMultipart(
      path: '/uploader/works',
      requiresAuth: true,
      fields: {
        'title': title,
        'original_author': originalAuthor,
        'type': type,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        ..._arrayFields('genre_ids', genreIds.map((e) => '$e').toList()),
      },
      files: [
        if (coverPath != null && coverPath.isNotEmpty)
          _MultipartFileSpec(field: 'cover', path: coverPath),
      ],
    );
    return WorkSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<WorkSummary> updateUploaderWork({
    required int workId,
    required String title,
    required String originalAuthor,
    required String type,
    required List<int> genreIds,
    String? description,
    String? coverPath,
  }) async {
    final json = await _sendMultipart(
      path: '/uploader/works/$workId',
      requiresAuth: true,
      methodOverride: 'PATCH',
      fields: {
        'title': title,
        'original_author': originalAuthor,
        'type': type,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        ..._arrayFields('genre_ids', genreIds.map((e) => '$e').toList()),
      },
      files: [
        if (coverPath != null && coverPath.isNotEmpty)
          _MultipartFileSpec(field: 'cover', path: coverPath),
      ],
    );
    return WorkSummary.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUploaderWork(int workId) async {
    await _deleteJson('/uploader/works/$workId', requiresAuth: true);
  }

  Future<void> submitUploaderWork(int workId) async {
    await _postJson('/uploader/works/$workId/submit', requiresAuth: true);
  }

  Future<UploaderChaptersResponse> fetchUploaderChapters(int workId) async {
    final json = await _getJson(
      '/uploader/works/$workId/chapters',
      requiresAuth: true,
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return UploaderChaptersResponse(
      work: WorkSummary.fromJson(json['work'] as Map<String, dynamic>),
      chapters: rawData
          .map((item) => ChapterSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ChapterDetail> fetchUploaderChapter({
    required int workId,
    required int chapterId,
  }) async {
    final json = await _getJson(
      '/uploader/works/$workId/chapters/$chapterId',
      requiresAuth: true,
    );
    return ChapterDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ChapterDetail> createUploaderChapter({
    required int workId,
    required int chapterNumber,
    String? title,
    String? textContent,
  }) async {
    final json = await _postJson(
      '/uploader/works/$workId/chapters',
      requiresAuth: true,
      body: {
        'chapter_number': chapterNumber,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (textContent != null) 'text_content': textContent,
      },
    );
    return ChapterDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<ChapterDetail> updateUploaderChapter({
    required int workId,
    required int chapterId,
    required int chapterNumber,
    String? title,
    String? textContent,
  }) async {
    final json = await _patchJson(
      '/uploader/works/$workId/chapters/$chapterId',
      requiresAuth: true,
      body: {
        'chapter_number': chapterNumber,
        'title': title?.trim(),
        'text_content': textContent,
      },
    );
    return ChapterDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUploaderChapter({
    required int workId,
    required int chapterId,
  }) async {
    await _deleteJson(
      '/uploader/works/$workId/chapters/$chapterId',
      requiresAuth: true,
    );
  }

  Future<ChapterImagesResponse> fetchUploaderChapterImages(int chapterId) async {
    final json = await _getJson(
      '/uploader/chapters/$chapterId/images',
      requiresAuth: true,
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return ChapterImagesResponse(
      chapter: ChapterDetail.fromJson(json['chapter'] as Map<String, dynamic>),
      images: rawData
          .map((item) => ChapterImageItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<ChapterImageItem>> createUploaderChapterImages({
    required int chapterId,
    required List<String> imagePaths,
  }) async {
    final json = await _sendMultipart(
      path: '/uploader/chapters/$chapterId/images',
      requiresAuth: true,
      files: imagePaths
          .where((path) => path.isNotEmpty)
          .map((path) => _MultipartFileSpec(field: 'images[]', path: path))
          .toList(),
    );
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return rawData
        .map((item) => ChapterImageItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChapterImageItem> updateUploaderChapterImage({
    required int chapterId,
    required int imageId,
    required int pageNumber,
    String? imagePath,
  }) async {
    final json = await _sendMultipart(
      path: '/uploader/chapters/$chapterId/images/$imageId',
      requiresAuth: true,
      methodOverride: 'PATCH',
      fields: {
        'page_number': '$pageNumber',
      },
      files: [
        if (imagePath != null && imagePath.isNotEmpty)
          _MultipartFileSpec(field: 'image', path: imagePath),
      ],
    );
    return ChapterImageItem.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUploaderChapterImage({
    required int chapterId,
    required int imageId,
  }) async {
    await _deleteJson(
      '/uploader/chapters/$chapterId/images/$imageId',
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool requiresAuth = false,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
    final response = await _httpClient.get(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _patchJson(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.patch(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
      body: body == null ? null : jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _deleteJson(
    String path, {
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.delete(
      uri,
      headers: _headers(requiresAuth: requiresAuth),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _sendMultipart({
    required String path,
    required bool requiresAuth,
    Map<String, String>? fields,
    List<_MultipartFileSpec> files = const [],
    String? methodOverride,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    request.headers.addAll(_multipartHeaders(requiresAuth: requiresAuth));
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (methodOverride != null && methodOverride.isNotEmpty) {
      request.fields['_method'] = methodOverride;
    }

    for (final file in files) {
      request.files.add(await http.MultipartFile.fromPath(file.field, file.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  Map<String, String> _headers({bool requiresAuth = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (requiresAuth && authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Map<String, String> _multipartHeaders({bool requiresAuth = false}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (requiresAuth && authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] as String?;
        final errors = decoded['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            throw ApiException(firstError.first.toString());
          }
        }
        throw ApiException(
          message ??
              'Request gagal (${response.statusCode}). Pastikan API Laravel aktif dan token valid.',
        );
      }

      throw ApiException(
        'Request gagal (${response.statusCode}). Pastikan API Laravel aktif dan token valid.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ApiException(
        'Response API tidak sesuai format yang diharapkan.',
      );
    }

    return decoded;
  }

  Map<String, String> _arrayFields(String key, List<String> values) {
    final fields = <String, String>{};
    for (var index = 0; index < values.length; index++) {
      fields['$key[$index]'] = values[index];
    }
    return fields;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return ApiConfigDefaults.fallbackBaseUrl;
    }

    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}

class ApiConfigDefaults {
  static const fallbackBaseUrl = 'http://localhost/ujikom/public/api';
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _MultipartFileSpec {
  const _MultipartFileSpec({
    required this.field,
    required this.path,
  });

  final String field;
  final String path;
}
