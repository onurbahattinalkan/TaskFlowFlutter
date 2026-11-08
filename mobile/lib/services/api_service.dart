import 'package:dio/dio.dart';

import '../models/json_dates.dart';
import '../models/project.dart';
import 'api_client.dart';
import 'api_exception.dart';
import '../models/auth_user.dart';

// Uygulamanın API ile konuştuğu tek yer.
// Ekranlar bu sınıfın metotlarını çağırır; adresler ve JSON dönüşümü burada.
class ApiService {
  final Dio _dio;

  // Varsayılan olarak ortak Dio nesnesi; testte farklı bir Dio verilebilir
  ApiService({Dio? dio}) : _dio = dio ?? ApiClient.dio;




  // ---------- Kimlik doğrulama ----------

  // POST /api/auth/login (giriş e-posta ile)
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _send(() => _dio.post('/api/auth/login', data: {
          'email': email,
          'password': password,
        }));
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // POST /api/auth/register (kayıt olan doğrudan giriş yapmış sayılır)
  Future<AuthResponse> register({
    required String fullName,
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _send(() => _dio.post('/api/auth/register', data: {
          'fullName': fullName,
          'userName': userName,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }));
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }




  // ---------- Projeler ----------

  // GET /api/projects (isteğe bağlı ekip filtresi)
  Future<List<Project>> getProjects({int? teamId}) async {
    final response = await _send(() => _dio.get(
          '/api/projects',
          queryParameters: teamId == null ? null : {'teamId': teamId},
        ));

    final list = response.data as List<dynamic>;
    return list
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // GET /api/projects/{id}
  Future<Project> getProject(int id) async {
    final response = await _send(() => _dio.get('/api/projects/$id'));
    return Project.fromJson(response.data as Map<String, dynamic>);
  }

  // POST /api/projects
  Future<Project> createProject({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required int teamId,
  }) async {
    final response = await _send(() => _dio.post('/api/projects', data: {
          'name': name,
          'description': description,
          'startDate': formatDateOnly(startDate),
          'endDate': formatDateOnly(endDate),
          'teamId': teamId,
        }));
    return Project.fromJson(response.data as Map<String, dynamic>);
  }

  // PUT /api/projects/{id} (ekip değiştirilemez, teamId gönderilmez)
  Future<Project> updateProject(
    int id, {
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _send(() => _dio.put('/api/projects/$id', data: {
          'name': name,
          'description': description,
          'startDate': formatDateOnly(startDate),
          'endDate': formatDateOnly(endDate),
        }));
    return Project.fromJson(response.data as Map<String, dynamic>);
  }

  // DELETE /api/projects/{id}
  Future<void> deleteProject(int id) async {
    await _send(() => _dio.delete('/api/projects/$id'));
  }

  // ---------- Ortak ----------

  // Her isteği sarar: Dio hatasını Türkçe ApiException'a çevirir
  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}