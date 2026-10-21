import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
  MockApi({
    this.latency = const Duration(milliseconds: 250),
    Future<List<Map<String, dynamic>>> Function()? programLoader,
  }) : _programLoader = programLoader ?? _defaultLoader;

  static const baseUrl = 'https://mock.excelerate.local/api';
  static const invitationCode = 'EXCEL2026';

  static List<Map<String, dynamic>>? _cachedPrograms;

  /// Reads the programs asset ahead of time for tests that cannot wait on file I/O.
  static Future<void> preloadPrograms() async =>
      _cachedPrograms = await loadMockPrograms();

  static Future<List<Map<String, dynamic>>> _defaultLoader() async =>
      _cachedPrograms ?? await loadMockPrograms();

  final Duration latency;
  final Future<List<Map<String, dynamic>>> Function() _programLoader;
  List<Map<String, dynamic>>? _programs;
  Set<String> _defaultRegistered = {};
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
        return _json(await _programsFor(account));
      case 'GET /announcements':
        return _json([
          for (final announcement in mockAnnouncements)
            if (announcement['audience'] == 'all' ||
                announcement['audience'] == account.role.name)
              announcement,
        ]);
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
      final program = (await _programsFor(account))
          .where((p) => p['id']?.toString() == segments[1])
          .firstOrNull;
      if (program == null) return _error(404, 'Program not found.');
      if (segments.length == 2 && request.method == 'GET') {
        return _json(program);
      }
      if (segments.length == 3 &&
          segments[2] == 'register' &&
          request.method == 'POST') {
        if (admin) {
          return _error(403, 'Admins cannot register for programs.');
        }
        _registrationsFor(account).add(segments[1]);
        return _json({...program, 'is_registered': true});
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

  Future<List<Map<String, dynamic>>> _loadPrograms() async {
    final loaded = _programs;
    if (loaded != null) return loaded;
    final data = await _programLoader();
    _defaultRegistered = {
      for (final json in data)
        if (json['is_registered'] == true && json['id'] != null)
          json['id'].toString(),
    };
    return _programs = data;
  }

  Set<String> _registrationsFor(_Account account) => _registrations.putIfAbsent(
      account.id,
      () => account.role == UserRole.learner ? {..._defaultRegistered} : {});

  Future<List<Map<String, dynamic>>> _programsFor(_Account account) async {
    final programs = await _loadPrograms();
    final registered = _registrationsFor(account);
    return [
      for (final json in programs)
        {...json, 'is_registered': registered.contains(json['id']?.toString())},
    ];
  }

  Map<String, dynamic> _body(http.Request request) => request.body.isEmpty
      ? <String, dynamic>{}
      : jsonDecode(request.body) as Map<String, dynamic>;

  http.Response _json(Object? body, [int status = 200]) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  http.Response _error(int status, String message) =>
      _json({'message': message}, status);
}
