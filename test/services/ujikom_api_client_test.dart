import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_ujikom/src/models/api_models.dart';
import 'package:flutter_ujikom/src/services/ujikom_api_client.dart';

void main() {
  group('UjikomApiClient admin CRUD', () {
    test('fetchAdminUsers parses users, roles, and pagination meta', () async {
      late http.Request capturedRequest;

      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-admin',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 11,
                  'name': 'Admin QA',
                  'email': 'admin.qa@example.test',
                  'role': 'admin',
                  'role_id': 1,
                  'works_count': 3,
                  'bookmarks_count': 2,
                  'comments_count': 1,
                }
              ],
              'roles': [
                {'id': 1, 'name': 'admin'},
                {'id': 2, 'name': 'uploader'},
              ],
              'meta': {
                'current_page': 1,
                'last_page': 1,
                'per_page': 15,
                'total': 1,
                'from': 1,
                'to': 1,
              },
            }),
            200,
          );
        }),
      );

      final response = await client.fetchAdminUsers(query: 'admin', role: 'admin');

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.path, '/ujikom/public/api/admin/users');
      expect(capturedRequest.url.queryParameters['q'], 'admin');
      expect(capturedRequest.url.queryParameters['role'], 'admin');
      expect(capturedRequest.headers['Authorization'], 'Bearer token-admin');
      expect(response.users, hasLength(1));
      expect(response.users.first.name, 'Admin QA');
      expect(response.roles.map((role) => role.name), ['admin', 'uploader']);
      expect(response.meta.total, 1);
    });

    test('updateAdminUser sends PATCH and parses updated user', () async {
      late http.Request capturedRequest;

      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-admin',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'data': {
                'id': 4,
                'name': 'Uploader Baru',
                'email': 'uploader.baru@example.test',
                'role': 'user',
                'role_id': 3,
                'works_count': 0,
                'bookmarks_count': 0,
                'comments_count': 0,
              }
            }),
            200,
          );
        }),
      );

      final updatedUser = await client.updateAdminUser(
        userId: 4,
        name: 'Uploader Baru',
        email: 'uploader.baru@example.test',
        roleId: 3,
      );

      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

      expect(capturedRequest.method, 'PATCH');
      expect(capturedRequest.url.path, '/ujikom/public/api/admin/users/4');
      expect(body, {
        'name': 'Uploader Baru',
        'email': 'uploader.baru@example.test',
        'role_id': 3,
      });
      expect(updatedUser.role, 'user');
      expect(updatedUser.email, 'uploader.baru@example.test');
    });

    test('genre CRUD endpoints use the expected verbs and paths', () async {
      final requests = <http.Request>[];
      final responses = <String>[
        jsonEncode({
          'data': {
            'id': 7,
            'name': 'Regression Genre Mobile',
            'works_count': 0,
          }
        }),
        jsonEncode({
          'data': {
            'id': 7,
            'name': 'Regression Genre Mobile Updated',
            'works_count': 0,
          }
        }),
        jsonEncode({'message': 'Genre berhasil dihapus.'}),
      ];

      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-admin',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(responses[requests.length - 1], 200);
        }),
      );

      final created = await client.createAdminGenre('Regression Genre Mobile');
      final updated = await client.updateAdminGenre(
        genreId: 7,
        name: 'Regression Genre Mobile Updated',
      );
      await client.deleteAdminGenre(7);

      expect(created.name, 'Regression Genre Mobile');
      expect(updated.name, 'Regression Genre Mobile Updated');
      expect(requests.map((request) => request.method), ['POST', 'PATCH', 'DELETE']);
      expect(requests.map((request) => request.url.path), [
        '/ujikom/public/api/admin/genres',
        '/ujikom/public/api/admin/genres/7',
        '/ujikom/public/api/admin/genres/7',
      ]);
    });
  });

  group('UjikomApiClient uploader CRUD', () {
    test('fetchUploaderChapters parses work and chapter list', () async {
      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-uploader',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/ujikom/public/api/uploader/works/12/chapters');
          return http.Response(
            jsonEncode({
              'work': {
                'id': 12,
                'title': 'Mobile CRUD Comic Revised',
                'description': 'desc',
                'type': 'comic',
                'status': 'draft',
                'genres': ['Action'],
                'chapters_count': 1,
              },
              'data': [
                {
                  'id': 50,
                  'work_id': 12,
                  'title': 'Kickoff Mobile Chapter',
                  'chapter_number': 91,
                  'has_text_content': true,
                  'images_count': 0,
                  'comments_count': 0,
                }
              ],
            }),
            200,
          );
        }),
      );

      final response = await client.fetchUploaderChapters(12);

      expect(response.work.title, 'Mobile CRUD Comic Revised');
      expect(response.chapters, hasLength(1));
      expect(response.chapters.first.chapterNumber, 91);
    });

    test('chapter CRUD uses JSON endpoints and parses detail response', () async {
      final requests = <http.Request>[];
      final responses = <String>[
        jsonEncode({
          'data': {
            'id': 60,
            'work_id': 12,
            'title': 'Kickoff Mobile Chapter',
            'work_title': 'Mobile CRUD Comic Revised',
            'chapter_number': 91,
            'text_content': 'Create content',
            'images': [],
          }
        }),
        jsonEncode({
          'data': {
            'id': 60,
            'work_id': 12,
            'title': 'Kickoff Mobile Chapter Updated',
            'work_title': 'Mobile CRUD Comic Revised',
            'chapter_number': 92,
            'text_content': 'Updated content',
            'images': [],
          }
        }),
        jsonEncode({'message': 'Chapter berhasil dihapus.'}),
      ];

      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-uploader',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(responses[requests.length - 1], 200);
        }),
      );

      final created = await client.createUploaderChapter(
        workId: 12,
        chapterNumber: 91,
        title: 'Kickoff Mobile Chapter',
        textContent: 'Create content',
      );
      final updated = await client.updateUploaderChapter(
        workId: 12,
        chapterId: 60,
        chapterNumber: 92,
        title: 'Kickoff Mobile Chapter Updated',
        textContent: 'Updated content',
      );
      await client.deleteUploaderChapter(workId: 12, chapterId: 60);

      expect(created.chapterNumber, 91);
      expect(updated.title, 'Kickoff Mobile Chapter Updated');
      expect(requests.map((request) => request.method), ['POST', 'PATCH', 'DELETE']);
      expect(requests.map((request) => request.url.path), [
        '/ujikom/public/api/uploader/works/12/chapters',
        '/ujikom/public/api/uploader/works/12/chapters/60',
        '/ujikom/public/api/uploader/works/12/chapters/60',
      ]);
    });

    test('fetchUploaderChapterImages parses chapter detail and images', () async {
      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-uploader',
        httpClient: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/ujikom/public/api/uploader/chapters/60/images');
          return http.Response(
            jsonEncode({
              'chapter': {
                'id': 60,
                'work_id': 12,
                'title': 'Kickoff Mobile Chapter Updated',
                'work_title': 'Mobile CRUD Comic Revised',
                'chapter_number': 92,
                'text_content': 'Updated content',
                'images': [
                  {
                    'id': 101,
                    'page_number': 10,
                    'image_url': 'http://localhost/storage/chapters/page-10.png',
                  }
                ],
              },
              'data': [
                {
                  'id': 101,
                  'chapter_id': 60,
                  'page_number': 10,
                  'image_url': 'http://localhost/storage/chapters/page-10.png',
                  'chapter': {'title': 'Kickoff Mobile Chapter Updated'},
                }
              ],
            }),
            200,
          );
        }),
      );

      final response = await client.fetchUploaderChapterImages(60);

      expect(response.chapter.title, 'Kickoff Mobile Chapter Updated');
      expect(response.images, hasLength(1));
      expect(response.images.first.pageNumber, 10);
      expect(response.images.first.chapterTitle, 'Kickoff Mobile Chapter Updated');
    });

    test('throws ApiException with validation message when API returns errors', () async {
      final client = UjikomApiClient(
        baseUrl: 'http://localhost/ujikom/public/api',
        authToken: 'token-uploader',
        httpClient: MockClient((_) async {
          return http.Response(
            jsonEncode({
              'message': 'The given data was invalid.',
              'errors': {
                'genre_ids': ['Pilih minimal satu genre.'],
              },
            }),
            422,
          );
        }),
      );

      expect(
        () => client.fetchUploaderWorks(status: 'draft'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Pilih minimal satu genre.',
          ),
        ),
      );
    });
  });

  test('ChapterImageItem can read nested work title from chapter payload', () {
    final image = ChapterImageItem.fromJson({
      'id': 101,
      'chapter_id': 60,
      'page_number': 10,
      'image_url': 'http://localhost/storage/chapters/page-10.png',
      'chapter': {
        'title': 'Kickoff Mobile Chapter Updated',
        'work': {
          'title': 'Mobile CRUD Comic Revised',
        },
      },
    });

    expect(image.workTitle, 'Mobile CRUD Comic Revised');
    expect(image.chapterTitle, 'Kickoff Mobile Chapter Updated');
  });
}
