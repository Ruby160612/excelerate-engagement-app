import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../models/program.dart';
import '../models/user.dart';
import 'mock_data.dart';

class _Account {
  _Account({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = UserRole.learner,
    this.profileCompleted = false,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  bool profileCompleted;

  Map<String, dynamic> toJson() => AppUser(
        id: id,
        name: name,
        email: email,
        role: role,
        profileCompleted: profileCompleted,
      ).toJson();
}

/// In-memory stand-in for the backend, used only when USE_MOCK is set.
class MockApi {
  MockApi({this.latency = const Duration(milliseconds: 250)}) {
    final registeredIds = [
      for (final json in mockPrograms)
        if (json['is_registered'] == true) json['id'] as String,
    ];
    for (final account in _accounts.values) {
      _registrations[account.id] = {
        if (account.role == UserRole.learner) ...registeredIds,
      };
    }
  }

  static const baseUrl = 'https://mock.excelerate.local/api';
  static const invitationCode = 'EXCEL2026';

  final Duration latency;
  final Map<String, _Account> _accounts = {
    'learner@example.com': _Account(
      id: 'u-learner',
      name: 'Ada Learner',
      email: 'learner@example.com',
      password: 'learner123',
    ),
    'member@example.com': _Account(
      id: 'u-member',
      name: 'Kofi Member',
      email: 'member@example.com',
      password: 'member123',
      profileCompleted: true,
    ),
    'admin@example.com': _Account(
      id: 'u-admin',
      name: 'Zainab Admin',
      email: 'admin@example.com',
      password: 'admin123',
      role: UserRole.admin,
      profileCompleted: true,
    ),
  };
  final Map<String, _Account> _tokens = {};
  final Map<String, Set<String>> _registrations = {};
  var _nextId = 1;

  http.Client get client => MockClient(_handle);

  Future<http.Response> _handle(http.Request request) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final path = request.url.path.replaceFirst(RegExp(r'^/api'), '');
    final route = '${request.method} $path';

    switch (route) {
      case 'POST /auth/login':
        return _login(_body(request));
      case 'POST /auth/signup':
        return _signup(_body(request));
    }

    final account = _authenticate(request);
    if (account == null) return _error(401, 'Please sign in again.');
    final admin = account.role == UserRole.admin;

    switch (route) {
      case 'GET /auth/me':
        return _json(account.toJson());
      case 'PUT /profiles/me':
        account.profileCompleted = true;
        return _json({'user_id': account.id, ..._body(request)});
      case 'POST /profiles/me/cv':
        return http.Response('', 204);
      case 'GET /programs':
        return _json([for (final p in _programsFor(account)) p.toJson()]);
      case 'GET /assessments/me':
      case 'GET /badges/me':
      case 'GET /applications/me':
        return _json([]);
      case 'GET /applications':
        return admin ? _json([]) : _error(403, 'Admins only.');
      case 'POST /opportunities':
      case 'POST /interviews':
        return admin ? _json({}, 201) : _error(403, 'Admins only.');
    }

    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (segments.length >= 2 && segments.first == 'programs') {
      final program =
          _programsFor(account).where((p) => p.id == segments[1]).firstOrNull;
      if (program == null) return _error(404, 'Program not found.');
      if (segments.length == 2 && request.method == 'GET') {
        return _json(program.toJson());
      }
      if (segments.length == 3 &&
          segments[2] == 'register' &&
          request.method == 'POST') {
        if (admin) {
          return _error(403, 'Admins cannot register for programs.');
        }
        _registrations[account.id]!.add(program.id);
        return _json(program.copyWith(isRegistered: true).toJson());
      }
    }
    if (request.method == 'PUT' && segments.firstOrNull == 'applications') {
      return admin ? _json({}) : _error(403, 'Admins only.');
    }
    return _error(404, 'Not found.');
  }

  http.Response _login(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final account = _accounts[email];
    if (account == null || account.password != body['password']) {
      return _error(401, 'Invalid email or password.');
    }
    return _session(account);
  }

  http.Response _signup(Map<String, dynamic> body) {
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    if (body['invitation_code'] != invitationCode) {
      return _error(400, 'Invalid invitation code.');
    }
    if (_accounts.containsKey(email)) {
      return _error(409, 'An account with this email already exists.');
    }
    final account = _Account(
      id: 'u-new-${_nextId++}',
      name: (body['name'] as String? ?? '').trim(),
      email: email,
      password: body['password'] as String? ?? '',
    );
    _accounts[email] = account;
    _registrations[account.id] = {};
    return _session(account);
  }

  http.Response _session(_Account account) {
    final token = 'mock-token-${_nextId++}-${account.id}';
    _tokens[token] = account;
    return _json({'token': token, 'user': account.toJson()});
  }

  _Account? _authenticate(http.Request request) {
    final header = request.headers['Authorization'] ?? '';
    return header.startsWith('Bearer ')
        ? _tokens[header.substring('Bearer '.length)]
        : null;
  }

  List<Program> _programsFor(_Account account) => [
        for (final json in mockPrograms)
          Program.fromJson(json).copyWith(
            isRegistered:
                _registrations[account.id]?.contains(json['id']) ?? false,
          ),
      ];

  Map<String, dynamic> _body(http.Request request) => request.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(request.body) as Map<String, dynamic>;

  http.Response _json(Object? body, [int status = 200]) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  http.Response _error(int status, String message) =>
      _json({'message': message}, status);
}
