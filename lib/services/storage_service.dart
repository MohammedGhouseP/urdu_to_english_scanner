import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project_model.dart';

/// Persists projects as JSON files under the app's documents directory.
/// One file per project keeps reads/writes cheap and avoids a single
/// monolithic database. Swap to Hive boxes when projects exceed a few hundred.
class StorageService {
  static const _projectsDir = 'projects';

  Future<Directory> _projectsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_projectsDir');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _fileFor(String projectId) async {
    final dir = await _projectsDirectory();
    return File('${dir.path}/$projectId.json');
  }

  Future<void> saveProject(Project project) async {
    project.lastModified = DateTime.now();
    final file = await _fileFor(project.id);
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  Future<Project?> loadProject(String id) async {
    final file = await _fileFor(id);
    if (!file.existsSync()) return null;
    final raw = await file.readAsString();
    if (raw.isEmpty) return null;
    return Project.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<List<Project>> loadAllProjects() async {
    final dir = await _projectsDirectory();
    final files = dir.listSync().whereType<File>().where(
          (f) => f.path.endsWith('.json'),
        );
    final projects = <Project>[];
    for (final f in files) {
      try {
        final raw = await f.readAsString();
        if (raw.isEmpty) continue;
        projects.add(Project.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt files rather than failing the whole load.
        continue;
      }
    }
    projects.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return projects;
  }

  Future<void> deleteProject(String id) async {
    final file = await _fileFor(id);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Where Scanner Screen should copy raw scans to (so deleting the original
  /// from gallery / cache doesn't break the project).
  Future<Directory> scansDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/scans');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> exportsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/exports');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
