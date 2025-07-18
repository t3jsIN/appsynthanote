// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'project_detail_screen.dart';
import 'package:flutter/foundation.dart';

// Enhanced Project Studio Screen
class ProjectStudioScreen extends StatefulWidget {
  const ProjectStudioScreen({super.key});

  @override
  State<ProjectStudioScreen> createState() => _ProjectStudioScreenState();
}

class _ProjectStudioScreenState extends State<ProjectStudioScreen> {
  List<ProjectStudio> projects = [];
  final TextEditingController _searchController = TextEditingController();
  List<ProjectStudio> filteredProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getStringList('projects') ?? [];
      setState(() {
        projects = projectsJson
            .map((projectStr) {
              try {
                return ProjectStudio.fromJson(jsonDecode(projectStr));
              } catch (e) {
                return null;
              }
            })
            .where((project) => project != null)
            .cast<ProjectStudio>()
            .toList();
        _applyFilters();
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _saveProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson =
          projects.map((project) => jsonEncode(project.toJson())).toList();
      await prefs.setStringList('projects', projectsJson);
    } catch (e) {
      print('Error saving projects: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredProjects = List.from(projects);
      } else {
        final searchTerm = _searchController.text.toLowerCase();
        filteredProjects = projects.where((project) {
          return project.title.toLowerCase().contains(searchTerm) ||
              project.tags
                  .any((tag) => tag.toLowerCase().contains(searchTerm)) ||
              (project.mood?.toLowerCase().contains(searchTerm) ?? false);
        }).toList();
      }

      // Sort by updated date (newest first)
      filteredProjects.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  void _createNewProject() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController bpmController = TextEditingController();
        final TextEditingController keyController = TextEditingController();
        final TextEditingController moodController = TextEditingController();
        String selectedPhase = 'Idea Phase';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFF9C27B0).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create New Project',
                      style: TextStyle(
                        color: Color(0xFFF8F8F8),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Color(0xFFF8F8F8)),
                      decoration: InputDecoration(
                        labelText: 'Project Title',
                        labelStyle: const TextStyle(color: Color(0xFF9C27B0)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF9C27B0), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bpmController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Color(0xFFF8F8F8)),
                            decoration: InputDecoration(
                              labelText: 'BPM',
                              labelStyle:
                                  const TextStyle(color: Color(0xFF9C27B0)),
                              filled: true,
                              fillColor: const Color(0xFF2C2C2C),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF9C27B0), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showKeyPickerInDialog(
                                setDialogState, keyController),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2C),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                keyController.text.isEmpty
                                    ? 'Key'
                                    : keyController.text,
                                style: TextStyle(
                                  color: keyController.text.isEmpty
                                      ? const Color(0xFF9C27B0)
                                      : const Color(0xFFF8F8F8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: moodController,
                      style: const TextStyle(color: Color(0xFFF8F8F8)),
                      decoration: InputDecoration(
                        labelText: 'Mood',
                        labelStyle: const TextStyle(color: Color(0xFF9C27B0)),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF9C27B0), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Starting Phase',
                            style: TextStyle(
                                color: Color(0xFF9C27B0),
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  final TextEditingController customController =
                                      TextEditingController();
                                  return Container(
                                    height: 400,
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2C2C2C),
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Select Starting Phase',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFFF8F8F8)),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: customController,
                                          style: const TextStyle(
                                              color: Color(0xFFF8F8F8)),
                                          decoration: InputDecoration(
                                            hintText:
                                                'Type custom phase (e.g., "Recording")...',
                                            hintStyle: const TextStyle(
                                                color: Color(0xFFB0B0B0)),
                                            filled: true,
                                            fillColor: const Color(0xFF3C3C3C),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text('Or choose from presets:',
                                            style: TextStyle(
                                                color: Color(0xFFB0B0B0),
                                                fontSize: 14)),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: ListView(
                                            children: [
                                              'Idea Phase',
                                              'Breakdown Phase',
                                              'Build Phase',
                                              'Drop Phase',
                                              'Mix Phase',
                                              'Master Phase',
                                              'Working Phase'
                                            ]
                                                .map((phase) => ListTile(
                                                      title: Text(phase,
                                                          style: const TextStyle(
                                                              color: Color(
                                                                  0xFFF8F8F8))),
                                                      onTap: () {
                                                        setDialogState(() {
                                                          selectedPhase = phase;
                                                        });
                                                        Navigator.pop(context);
                                                      },
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF9C27B0),
                                              foregroundColor: Colors.white),
                                          onPressed: () {
                                            if (customController
                                                .text.isNotEmpty) {
                                              String customPhase =
                                                  customController.text.trim();
                                              // Don't auto-add "Phase"
                                              setDialogState(() {
                                                selectedPhase = customPhase;
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                          child: const Text('Use Custom Phase'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF3C3C3C),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedPhase,
                                      style: const TextStyle(
                                          color: Color(0xFFF8F8F8))),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Color(0xFFB0B0B0)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: Color(0xFFB0B0B0))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            String projectTitle = titleController.text.trim();
                            if (projectTitle.isEmpty) {
                              projectTitle = 'Untitled Project';
                            }

                            if (!projectTitle.toLowerCase().endsWith('.flp')) {
                              projectTitle += '.flp';
                            }

                            final newProject = ProjectStudio(
                              title: projectTitle,
                              bpm: bpmController.text.isEmpty
                                  ? null
                                  : int.tryParse(bpmController.text),
                              key: keyController.text.isEmpty
                                  ? null
                                  : keyController.text,
                              mood: moodController.text.isEmpty
                                  ? null
                                  : moodController.text,
                            );

                            final initialPhase = ProjectPhaseEntry(
                              id: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              name: selectedPhase,
                              timestamp: DateTime.now(),
                            );

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ProjectDetailScreen(
                                  project: newProject,
                                  initialPhase: initialPhase,
                                  onSave: (updatedProject) {
                                    setState(() {
                                      projects.insert(0, updatedProject);
                                    });
                                    _applyFilters();
                                    _saveProjects();
                                  },
                                ),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: animation.drive(Tween(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero)
                                        .chain(CurveTween(
                                            curve: Curves.easeInOutCubic))),
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 300),
                              ),
                            );
                          },
                          child: const Text('Create'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showKeyPickerInDialog(
      StateSetter setDialogState, TextEditingController keyController) {
    final keys = [
      'C',
      'C#',
      'Db',
      'D',
      'D#',
      'Eb',
      'E',
      'F',
      'F#',
      'Gb',
      'G',
      'G#',
      'Ab',
      'A',
      'A#',
      'Bb',
      'B',
      'Cm',
      'C#m',
      'Dbm',
      'Dm',
      'D#m',
      'Ebm',
      'Em',
      'Fm',
      'F#m',
      'Gbm',
      'Gm',
      'G#m',
      'Abm',
      'Am',
      'A#m',
      'Bbm',
      'Bm'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      builder: (context) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('Select Key',
                  style: TextStyle(
                      color: Color(0xFFF8F8F8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2,
                  ),
                  itemCount: keys.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          keyController.text = keys[index];
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(8)),
                        child: Center(
                            child: Text(keys[index],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFB0B0B0),
                      size: 20,
                    ),
                  ),
                  const Text(
                    'Project Studio',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF8F8F8),
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _createNewProject,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9C27B0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFFF8F8F8)),
                decoration: InputDecoration(
                  hintText: 'Search projects, tags, moods...',
                  hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB0B0B0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                          child: const Icon(
                            Icons.clear,
                            color: Color(0xFFB0B0B0),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF9C27B0),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _applyFilters();
                },
              ),
            ),

            const SizedBox(height: 20),

            // Projects List
            Expanded(
              child: filteredProjects.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: Color(0xFF9C27B0),
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No projects yet',
                            style: TextStyle(
                              color: Color(0xFFF8F8F8),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Create your first project to start organizing',
                            style: TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        return _buildProjectCard(
                            filteredProjects[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProjectColor(String projectId) {
    final colors = [
      const Color(0xFF6C5CE7), // Vibrant Purple
      const Color(0xFF74B9FF), // Sky Blue
      const Color(0xFF00B894), // Mint Green
      const Color(0xFFFF7675), // Coral Pink
      const Color(0xFFFD79A8), // Hot Pink
      const Color(0xFFE17055), // Orange Red
      const Color(0xFF00CEC9), // Turquoise
      const Color(0xFFF39C12), // Orange
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF3498DB), // Blue
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE74C3C), // Red
      const Color(0xFF2ECC71), // Green
      const Color(0xFFFF6B6B), // Light Red
      const Color(0xFF4ECDC4), // Light Teal
      const Color(0xFF45B7D1), // Light Blue
      const Color(0xFF96CEB4), // Light Green
      const Color(0xFFFECA57), // Yellow
      const Color(0xFFFF9FF3), // Light Pink
      const Color(0xFF54A0FF), // Bright Blue
    ];

    return colors[projectId.hashCode.abs() % colors.length];
  }

  Widget _buildProjectCard(ProjectStudio project, int index) {
    final projectColor = _getProjectColor(project.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProjectDetailScreen(
              project: project,
              onSave: (updatedProject) {
                setState(() {
                  final index = projects.indexWhere((p) => p.id == project.id);
                  if (index != -1) {
                    projects[index] = updatedProject;
                  }
                });
                _applyFilters();
                _saveProjects();
              },
              onDelete: () {
                setState(() {
                  projects.removeWhere((p) => p.id == project.id);
                });
                _applyFilters();
                _saveProjects();
              },
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOutCubic)),
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              projectColor,
              projectColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: projectColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: project.isCompleted
                        ? const Color(0xFF4CAF50) // Green dot (keep this)
                        : const Color(0xFF9C27B0)
                            .withOpacity(0.0), // Purple dot transparent
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.displayTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  project.currentPhase.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (project.statusUpdates.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                project.statusUpdates.last.status,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFB0B0B0),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (project.bpm != null) ...[
                  const Icon(
                    Icons.speed,
                    color: Colors.white, // ← CHANGED TO WHITE
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${project.bpm} BPM',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white, // ← CHANGED TO WHITE
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (project.key != null) ...[
                  const Icon(
                    Icons.music_note,
                    color: Colors.white, // ← CHANGED TO WHITE
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    project.key!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white, // ← CHANGED TO WHITE
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(project.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white, // ← CHANGED TO WHITE
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
