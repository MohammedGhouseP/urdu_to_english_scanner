import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/project_model.dart';
import '../state/project_store.dart';
import '../utils/app_theme.dart';
import 'project_manager_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProjectStore>();

    final totalPages = store.projects
        .fold<int>(0, (sum, p) => sum + p.totalPageCount);
    final completedBooks =
        store.projects.where((p) => p.completionRatio >= 1.0 && p.totalPageCount > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urdu Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'My Projects',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProjectManagerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan, translate, design.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Turn Urdu books into editable Roman English manuscripts.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),
              _ActionCard(
                icon: Icons.document_scanner_outlined,
                label: 'Scan New Book',
                onTap: () {
                  context.read<ProjectStore>().startNewProject();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScannerScreen()),
                  );
                },
                primary: true,
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.collections_bookmark_outlined,
                label: 'My Projects',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProjectManagerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _StatTile(
                    label: 'Pages scanned',
                    value: totalPages.toString(),
                    icon: Icons.menu_book_outlined,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    label: 'Books completed',
                    value: completedBooks.toString(),
                    icon: Icons.auto_stories_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Recent projects',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (store.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (store.projects.isEmpty)
                _EmptyRecent()
              else
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.projects.take(8).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final project = store.projects[i];
                      return _ProjectMiniCard(
                        project: project,
                        onTap: () {
                          context.read<ProjectStore>().setActive(project);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ScannerScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: primary ? cs.primary : cs.surface,
          border: Border.all(
            color: primary ? cs.primary : AppTheme.gold.withOpacity(0.6),
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary ? cs.onPrimary : cs.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  color: primary ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: primary ? cs.onPrimary : cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMiniCard extends StatelessWidget {
  const _ProjectMiniCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstImage = project.pages.isNotEmpty ? project.pages.first.imagePath : null;
    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 100,
                child: firstImage != null && File(firstImage).existsSync()
                    ? Image.file(File(firstImage), fit: BoxFit.cover)
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.menu_book_outlined, size: 36),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
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
                      '${project.totalPageCount} pages',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'No projects yet — start by scanning a page.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
