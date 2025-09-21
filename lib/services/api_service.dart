// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;
  String? token; // setel saat login
  ApiService({required this.baseUrl, this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _normalize(res);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String address,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'password': password,
      }),
    );
    return _normalize(res);
  }

  Map<String, dynamic> _normalize(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? {}
          : (jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      body = {'raw': res.body};
    }

    final ok = res.statusCode >= 200 && res.statusCode < 300;
    // Selalu sediakan kunci berikut agar UI tidak null
    return {
      'success': ok,
      'statusCode': res.statusCode,
      'message':
          (body['message'] ?? body['error'] ?? (ok ? 'OK' : 'Request gagal'))
              .toString(),
      'token': body['token'], // kalau ada
      'data': body, // seluruh payload asli
    };
  }

  Future<ComplaintsPage> fetchMyComplaints({int page = 1}) async {
    final uri = Uri.parse('$baseUrl/me/complaints?page=$page');
    final res = await http.get(uri, headers: _headers);

    final code = res.statusCode;
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (code < 200 || code >= 300) {
      final msg = body['message']?.toString() ?? 'Gagal memuat pengaduan';
      throw Exception('$code $msg');
    }
    return ComplaintsPage.fromJson(body as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String content,
    required String category,
  }) async {
    final uri = Uri.parse('$baseUrl/complaints');
    final res = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'content': content,
        'category': category,
      }),
    );

    final code = res.statusCode;
    final body = res.body.isEmpty ? {} : jsonDecode(res.body);
    if (code < 200 || code >= 300) {
      final msg = body is Map
          ? (body['message']?.toString() ?? 'Gagal membuat pengaduan')
          : 'Gagal membuat pengaduan';
      throw Exception('$code $msg');
    }
    return body as Map<String, dynamic>;
  }
}

// ====== MODELS ======
class ComplaintsPage {
  final int currentPage;
  final int lastPage;
  final int total;
  final List<Complaint> items;

  ComplaintsPage({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.items,
  });

  factory ComplaintsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>? ?? [])
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
    return ComplaintsPage(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      total: json['total'] ?? list.length,
      items: list,
    );
  }
}

class Complaint {
  final int id;
  final String title;
  final String content;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? handlerName;

  Complaint({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    required this.createdAt,
    this.handlerName,
  });

  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
    id: j['id'] as int,
    title: (j['title'] ?? '-') as String,
    content: (j['content'] ?? '-') as String,
    category: (j['category'] ?? '-') as String,
    status: (j['status'] ?? '-') as String,
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    handlerName: j['handler'] != null
        ? (j['handler']['name']?.toString())
        : null,
  );
}
