import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../state/project_store.dart';
import 'scanner_screen.dart';

enum _Filter { all, inProgress, completed }

enum _Sort { date, name, pageCount }

class ProjectManagerScreen extends StatefulWidget {
  const ProjectManagerScreen({super.key});

  @override
  State<ProjectManagerScreen> createState() => _ProjectManagerScreenState();
}

class _ProjectManagerScreenState extends State<ProjectManagerScreen> {
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.date;

  List<Project> _filterAndSort(List<Project> input) {
    final filtered = input.where((p) {
      switch (_filter) {
        case _Filter.completed:
          return p.completionRatio >= 1.0 && p.totalPageCount > 0;
        case _Filter.inProgress:
          return p.completionRatio < 1.0 || p.totalPageCount == 0;
        case _Filter.all:
          return true;
      }
    }).toList();

    switch (_sort) {
      case _Sort.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
      case _Sort.pageCount:
        filtered.sort((a, b) => b.totalPageCount.compareTo(a.totalPageCount));
      case _Sort.date:
        filtered.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    }
    return filtered;
  }

  Future<void> _rename(Project project) async {
    final controller = TextEditingController(text: project.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await context.read<ProjectStore>().renameProject(project.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();
    final projects = _filterAndSort(store.projects);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.date, child: Text('Sort: Date')),
              PopupMenuItem(value: _Sort.name, child: Text('Sort: Name')),
              PopupMenuItem(
                  value: _Sort.pageCount, child: Text('Sort: Page count')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('All')),
                ButtonSegment(
                    value: _Filter.inProgress, label: Text('In progress')),
                ButtonSegment(
                    value: _Filter.completed, label: Text('Completed')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ),
        ),
      ),
      body: store.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projects.isEmpty
              ? const _EmptyManagerState()
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (_, i) => _ProjectCard(
                    project: projects[i],
                    onTap: () {
                      context.read<ProjectStore>().setActive(projects[i]);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ScannerScreen(),
                        ),
                      );
                    },
                    onRename: () => _rename(projects[i]),
                    onDelete: () =>
                        context.read<ProjectStore>().deleteProject(projects[i].id),
                  ),
                ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Project project;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cover = project.pages.isNotEmpty ? project.pages.first.imagePath : null;
    final dateFmt = DateFormat.yMMMd();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onRename,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cover != null && File(cover).existsSync()
                  ? Image.file(File(cover), fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.menu_book_outlined, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${project.approvedPageCount}/${project.totalPageCount} pages • ${(project.completionRatio * 100).round()}%',
                    style: const TextStyle(fontSize: 11),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateFmt.format(project.lastModified),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete project?'),
                              content: Text(
                                'This will permanently remove "${project.name}".',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) onDelete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyManagerState extends StatelessWidget {
  const _EmptyManagerState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No projects yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap "Scan New Book" on Home to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
