import 'package:flutter/foundation.dart';

import '../models/project_model.dart';
import '../models/scanned_page_model.dart';
import '../services/storage_service.dart';

/// Holds the list of saved projects + the currently-active project being
/// scanned/edited. The active project lives in memory until the user lands on
/// a screen that triggers `persist()` (e.g. approving a page, finalizing a
/// design, returning to home).
class ProjectStore extends ChangeNotifier {
  ProjectStore(this._storage);

  final StorageService _storage;

  List<Project> _projects = [];
  Project? _active;
  bool _loading = false;

  List<Project> get projects => List.unmodifiable(_projects);
  Project? get active => _active;
  bool get isLoading => _loading;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _projects = await _storage.loadAllProjects();
    _loading = false;
    notifyListeners();
  }

  Project startNewProject({String? name}) {
    final project = Project(name: name ?? _autoName());
    _active = project;
    _projects = [project, ..._projects];
    notifyListeners();
    return project;
  }

  String _autoName() {
    final now = DateTime.now();
    return 'Project ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void setActive(Project project) {
    _active = project;
    notifyListeners();
  }

  void clearActive() {
    _active = null;
    notifyListeners();
  }

  /// Notify listeners that the active project's metadata (theme/layout/
  /// settings) was mutated in place.
  void touchActive() {
    final project = _active;
    if (project == null) return;
    project.lastModified = DateTime.now();
    notifyListeners();
  }

  void addPage(ScannedPage page) {
    final project = _active;
    if (project == null) return;
    page.pageNumber = project.pages.length + 1;
    project.pages.add(page);
    project.lastModified = DateTime.now();
    notifyListeners();
  }

  void removePage(String pageId) {
    final project = _active;
    if (project == null) return;
    project.pages.removeWhere((p) => p.id == pageId);
    for (var i = 0; i < project.pages.length; i++) {
      project.pages[i].pageNumber = i + 1;
    }
    project.lastModified = DateTime.now();
    notifyListeners();
  }

  void replacePage(ScannedPage updated) {
    final project = _active;
    if (project == null) return;
    final i = project.pages.indexWhere((p) => p.id == updated.id);
    if (i == -1) return;
    project.pages[i] = updated;
    project.lastModified = DateTime.now();
    notifyListeners();
  }

  void approvePage(String pageId) {
    final project = _active;
    if (project == null) return;
    final i = project.pages.indexWhere((p) => p.id == pageId);
    if (i == -1) return;
    project.pages[i].isApproved = true;
    project.lastModified = DateTime.now();
    notifyListeners();
  }

  Future<void> persist() async {
    final project = _active;
    if (project == null) return;
    await _storage.saveProject(project);
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) {
      _projects = [project, ..._projects];
    } else {
      _projects[i] = project;
    }
    notifyListeners();
  }

  Future<void> renameProject(String id, String newName) async {
    final p = _projects.firstWhere((p) => p.id == id, orElse: () => _active!);
    p.name = newName;
    p.lastModified = DateTime.now();
    await _storage.saveProject(p);
    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await _storage.deleteProject(id);
    _projects.removeWhere((p) => p.id == id);
    if (_active?.id == id) _active = null;
    notifyListeners();
  }
}
