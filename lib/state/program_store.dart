import 'package:flutter/foundation.dart';

import '../models/program.dart';
import '../services/program_repository.dart';

enum LoadStatus { idle, loading, loaded, error }

/// The single source of truth for program data.
///
/// The listing, the details loader and the details screen all read from this
/// store, so a registration made on one screen shows on the others without
/// each screen keeping its own copy.
class ProgramStore extends ChangeNotifier {
  ProgramStore(this._repository);

  final ProgramRepository _repository;

  List<Program> _programs = const [];
  int _skipped = 0;
  LoadStatus _listStatus = LoadStatus.idle;
  String? _listError;

  String? _selectedId;
  Program? _selected;
  LoadStatus _selectedStatus = LoadStatus.idle;
  ProgramException? _selectedFailure;

  final Set<String> _registering = {};
  final Map<String, Program> _extra = {};
  bool _disposed = false;

  List<Program> get programs => _programs;

  /// Records the server returned that could not be read.
  int get skipped => _skipped;
  LoadStatus get listStatus => _listStatus;
  String? get listError => _listError;

  Program? get selected => _selected;
  LoadStatus get selectedStatus => _selectedStatus;
  ProgramException? get selectedFailure => _selectedFailure;

  bool isRegistering(String id) => _registering.contains(id);

  /// The freshest copy of [id] the store knows about: from the list, the
  /// selected program, or a registration made on a screen opened directly by id.
  Program? lookup(String id) =>
      programById(id) ?? (_selected?.id == id ? _selected : null) ?? _extra[id];

  Program? programById(String id) {
    for (final program in _programs) {
      if (program.id == id) return program;
    }
    return null;
  }

  /// Loads the list. The first load shows a spinner and reports failure. Later
  /// loads, or any call with [silent] set, refresh quietly: the current list
  /// stays on screen and a failed refresh does not replace it with an error.
  Future<void> loadPrograms({bool silent = false}) async {
    if (_listStatus == LoadStatus.loading) return; // already running
    final quiet = silent || _listStatus == LoadStatus.loaded;
    if (!quiet) {
      _listStatus = LoadStatus.loading;
      _listError = null;
      _notify();
    }
    try {
      final result = await _repository.fetchPrograms();
      _programs = result.programs;
      _skipped = result.skipped;
      _listStatus = LoadStatus.loaded;
      _listError = null;
      _syncSelectedFromList();
    } catch (error) {
      if (!quiet) {
        _listError =
            _messageOf(error, 'Unable to load this page. Please try again.');
        _listStatus = LoadStatus.error;
      }
    }
    _notify();
  }

  /// Makes [id] the selected program. A copy already in the list is shown
  /// straight away, then refreshed from the server.
  Future<void> selectProgram(String id) async {
    _selectedId = id;
    _selected = programById(id);
    _selectedFailure = null;
    _selectedStatus =
        _selected != null ? LoadStatus.loaded : LoadStatus.loading;
    _notify();
    try {
      final fresh = await _repository.fetchProgram(id);
      if (_selectedId != id) return; // the user moved on to another program
      _store(fresh);
      _selectedStatus = LoadStatus.loaded;
      _selectedFailure = null;
    } catch (error) {
      if (_selectedId != id) return;
      if (_selected == null) {
        _selectedStatus = LoadStatus.error;
        _selectedFailure = error is ProgramException
            ? error
            : const ProgramException(ProgramFailure.unavailable,
                'Unable to load this program. Please try again.');
      }
      // With a cached copy on screen, a failed refresh keeps showing it.
    }
    _notify();
  }

  /// Registers for [id]. Errors are rethrown so the calling form can show them
  /// (see SubmissionController). A second call for the same program while one
  /// is running is ignored.
  Future<void> register(String id) async {
    if (!_registering.add(id)) return;
    _notify();
    try {
      final updated = await _repository.register(id);
      _store(updated);
    } on ProgramException catch (error) {
      if (error.code == ProgramErrorCode.alreadyRegistered) {
        // Reconcile all screens through shared state, rather than local flags.
        final known = lookup(id);
        if (known != null) {
          _store(known.copyWith(isRegistered: true));
        } else {
          try {
            _store(await _repository.fetchProgram(id));
          } catch (_) {
            // Keep the original duplicate error if this read cannot complete.
          }
        }
      }
      rethrow;
    } finally {
      _registering.remove(id);
      _notify();
    }
  }

  void _store(Program program) {
    final index = _programs.indexWhere((p) => p.id == program.id);
    if (index >= 0) {
      _programs = [..._programs]..[index] = program;
    } else {
      _extra[program.id] = program;
    }
    if (_selectedId == program.id) _selected = program;
  }

  void _syncSelectedFromList() {
    final id = _selectedId;
    if (id == null) return;
    final match = programById(id);
    if (match != null) _selected = match;
  }

  static String _messageOf(Object error, String fallback) =>
      error is ProgramException ? error.message : fallback;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
