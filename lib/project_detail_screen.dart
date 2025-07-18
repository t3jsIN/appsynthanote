// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously, unused_local_variable

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'voice_recorder.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectStudio project;
  final Function(ProjectStudio) onSave;
  final VoidCallback? onDelete;
  final ProjectPhaseEntry? initialPhase;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.onSave,
    this.onDelete,
    this.initialPhase,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late ProjectStudio project;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bpmController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();
  List<Note> availableNotes = [];
  List<ProjectPhaseEntry> projectPhases = [];
  int _globalOrderCounter = 1;

  @override
  void initState() {
    super.initState();
    project = widget.project;
    itemOrders = project.itemOrders; // CRITICAL: Use project's saved orders
    _titleController.text = project.title;
    _bpmController.text = project.bpm?.toString() ?? '';
    _keyController.text = project.key ?? '';
    _moodController.text = project.mood ?? '';

    // Load notes FIRST, then initialize phases
    _loadAvailableNotes().then((_) {
      _initializePhases();
      _cleanupDuplicatePhaseStatuses();
      _restoreOrderCounter();
    });
  }

  void _restoreOrderCounter() {
    if (itemOrders.isNotEmpty) {
      _globalOrderCounter =
          itemOrders.values.reduce((a, b) => a > b ? a : b) + 1;
    }
  }

// Track ALL items with their order numbers - USE PROJECT'S itemOrders
  late Map<String, int> itemOrders;
  // Predefined status options from your paste
  final List<String> predefinedStatuses = [
    // IDEA PHASE
    'No idea yet',
    'Random hum stuck in head',
    'Inspired by another track',
    'Inspired by sample',
    'Inspired by movie/game scene',
    'Melody idea only',
    'Chord progression idea',
    'Perc loop only',
    'Vocal hook idea',
    'Riff recorded on phone',
    'Built on sample',
    'Trying to remake a track',
    'Made while jamming',
    'Built on one sound',
    'Copied from YouTube tutorial',
    'Feeling the vibe',
    'Not vibing with it anymore',
    'Too similar to another project',
    'Idea, but no energy',
    'Just testing sounds',
    'Too scattered',
    'Stuck in loop hell',
    'Doesn\'t sound unique',
    'Needs direction',
    'Idea fire but not buildable',
    'Saved from old session',
    'Made under influence lol',
    'One shot banger',
    'One night idea',
    'Just wanted to make something today',

    // INTRO SECTION
    'No intro yet',
    'Basic intro done',
    'Atmospheric intro works',
    'Too long intro',
    'Too short intro',
    'Not smooth enough',
    'Not engaging',
    'Intro too empty',
    'Intro too full',
    'Intro slaps',
    'Intro boring',
    'Intro transitions weird',
    'Perfect cinematic intro',
    'Good risers',
    'Needs more impact',
    'Weak sound selection in intro',
    'Needs vocal tag or ID',
    'Intro confuses genre',
    'Cool textures in intro',

    // BUILD-UP
    'No build-up',
    'Simple build-up done',
    'Build-up too flat',
    'Great energy',
    'Needs tension',
    'Too chaotic',
    'Bad transition to drop',
    'Automation not hitting',
    'Needs more movement',
    'Build-up melody weak',
    'Build-up saves the song',
    'Build-up repetitive',
    'Build-up too long',
    'Short build-up',
    'Build-up > drop',
    'Build-up feels generic',
    'Needs FX/riser boost',
    'Build-up snare pattern weak',
    'Buildup is stronger than drop',

    // BREAKDOWN
    'No breakdown',
    'Breakdown added',
    'Breakdown weak',
    'Breakdown emotional',
    'Breakdown fire',
    'Breakdown too long',
    'Breakdown vibe unmatched',
    'Breakdown doesn\'t fit rest',
    'Breakdown too quiet',
    'Breakdown best part',
    'Breakdown makes it cinematic',
    'Needs vocal or pad layer',
    'Too empty breakdown',
    'Breakdown transition janky',
    'Breakdown changes genre',

    // DROP (Main)
    'No drop yet',
    'Drop idea only',
    'Drop sucks',
    'Drop decent',
    'Drop is fire',
    'Drop sounds thin',
    'Drop is muddy',
    'Drop too empty',
    'Drop overcompressed',
    'Drop bouncy af',
    'Drop doesn\'t slap',
    'Drop energy too low',
    'Drop ruins build-up',
    'Drop is god-tier',
    'Drop + vocal hits perfect',
    'Drop needs better drums',
    'Melody is weak in drop',
    'Drop sounds like other track',
    'Wrong key or harmony',
    'Drop is better than rest',
    'Drop needs sub bass fix',
    'Drop rhythm off',
    'Drop feels lazy',
    'Experimental drop works',
    'Drop transition is bad',
    'Drop too harsh',
    'Drop saved the track',
    'Stuck at drop',
    'Drop missing something',
    'Needs more reese',
    'Needs more sidechain pump',
    'Drop needs better stabs',
    'Drop lacks pressure',
    'Need more stereo impact in drop',
    'Kick doesn\'t punch through drop',

    // SECOND DROP
    'No second drop',
    'Second drop idea only',
    'Second drop better than first',
    'Second drop worse',
    'Second drop flips it up',
    'Second drop is fire',
    'Second drop boring',
    'Repetitive second drop',
    'Second drop ruined flow',
    'Second drop surprise',
    'Second drop genre switch',
    'Second drop unfinished',
    'Needs second drop variation',
    'Second drop unnecessary',
    'Second drop perfect climax',

    // MIXING / MASTERING / SOUND QUALITY
    'Kick not centered',
    'Stereo image too wide',
    'Stereo image too narrow',
    'EQ curve needs work',
    'Low mids are muddy',
    'Highs too sharp',
    'Needs midrange saturation',
    'Mix lacks glue',
    'Limiter killing dynamics',
    'Mix lacks warmth',
    'Sub leaking into stereo',
    'Too much stereo reverb',
    'Drums lack presence',
    'Clipping in master',
    'Mix feels sterile',
    'Translation issues across devices',
    'Needs transient shaping',
    'Needs more analog feel',
    'Too many overlapping frequencies',
    'Lacks punch after master',
    'Needs multiband compression',
    'Mix sounds boxy',
    'Snare too bright',
    'Vocal overcompressed',
    'Too much stereo spread on hats',

    // GENRE / VIBE - TECHNO
    'Melodic techno direction',
    'Afterlife style',
    'Mind Against vibes',
    'Deep hypnotic groove',
    'Dark industrial techno',
    'Analog techno intent',
    'Cinematic breakdown',
    'Atmospheric techno build',
    '4AM warehouse feel',
    'Needs more tension',
    'Track needs breathers',
    'Too driving — pull back',
    'Not driving enough',
    'Needs better techno stab',
    'Need rave stab',
    'Add Reese bass',
    'Need FM growl bass',
    'Too EDM sounding',
    'Techno drums not hitting',
    'Kick lacks character for techno',
    'Need gritty industrial FX',
    'Need Berlin warehouse feel',
    'Needs analog saturation',
    'Build for sunrise',
    'Too cold — add warmth',
    'Missing tribal percussion layer',
    'Too clean — dirty it up',

    // MORE SOUND DESIGN / FX / MOVEMENT
    'Needs pump',
    'Needs more swing',
    'Automation too linear',
    'Modulation missing',
    'Envelope shaping weak',
    'Bassline lacks modulation',
    'Needs doppler FX',
    'Glitch FX layer needed',
    'Transition FX weak',
    'Add tape stop moment',
    'Noise risers not enough',
    'Too dry — needs reverb tail',
    'Not enough stereo movement',
    'Filter automation missing',
    'Needs shimmer on pad',
    'FX drowning everything',
    'Need granular resample moment',

    // EXTRA INSTRUMENTATION IDEAS
    'Need better melody',
    'Melody too basic',
    'Need tribal drums',
    'Needs arp variation',
    'Stabs too flat',
    'Need cinematic strings',
    'Want bell plucks',
    'Add ambient guitar',
    'Need darker pads',
    'Want modular synth feel',
    'Try distorted vocal chops',
    'Add field texture',
    'Layer claps with foley',
    'Try reversed pad layer',
    'Missing tension drones',
    'Try evolving background sound',
    'Need rhythmic noise layer',
    'Try dubby chords',
  ];
// This is now handled in the code above
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $url'),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid link: $url'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  void _initializePhases() {
    // Restore phases from project model
    projectPhases = List.from(project.phases);

    if (projectPhases.isEmpty) {
      // Add initial phase if provided
      if (widget.initialPhase != null) {
        projectPhases.add(widget.initialPhase!);
        itemOrders['phase:${widget.initialPhase!.id}'] = 1;
      }
    } else {
      // DON'T restore phase orders - they should keep original order from project.phases
// Just restore the counter
      if (projectPhases.isNotEmpty) {
        // Find the highest existing order number
        int maxOrder = 0;
        // Check all existing itemOrders that might be saved in the project
        _globalOrderCounter = projectPhases.length + 1;
      }
      _globalOrderCounter++; // Set counter for next items
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bpmController.dispose();
    _keyController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableNotes() async {
    try {
      // Always try Firebase first on web, then fallback to local
      if (kIsWeb) {
        await FirebaseService.initialize();
        final firebaseNotes = await FirebaseService.loadNotes();
        if (firebaseNotes.isNotEmpty) {
          setState(() {
            availableNotes = firebaseNotes;
          });
          return;
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList('notes') ?? [];
      setState(() {
        availableNotes = notesJson
            .map((noteStr) {
              try {
                return Note.fromJson(jsonDecode(noteStr));
              } catch (e) {
                return null;
              }
            })
            .where((note) => note != null)
            .cast<Note>()
            .toList();
      });
    } catch (e) {}
  }

  void _saveProject() {
// Notes are now stored as full objects, no validation needed!
    // The full note data is always available in project.attachedNotes
    // If notes aren't loaded, DON'T validate - keep all attached notes

    // Save phases and orders
    project.phases = projectPhases;
    project.itemOrders = itemOrders;

    // Save to parent widget and storage
    widget.onSave(project);
    _saveProjectToStorage();

    // Show save confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project saved!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFFF8F8F8),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        project.isCompleted = !project.isCompleted;
                        if (project.isCompleted) {
                          project.completedAt = DateTime.now();
                        } else {
                          project.completedAt = null;
                        }
                      });

                      // Save immediately when checkbox is toggled
                      await _saveProjectToStorage();

                      // Call the parent callback to update the list
                      widget.onSave(project);
                    },
                    child: Icon(
                      project.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: project.isCompleted
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF8F8F8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(),
                    child: const Icon(Icons.delete_outline,
                        color: Color(0xFFFF6B6B), size: 20),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _saveProject,
                    child: const Icon(Icons.save,
                        color: Color(0xFF9C27B0), size: 20),
                  ),
                ],
              ),
            ),

            // Project Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                project.displayTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8F8F8),
                ),
              ),
            ),

            // BPM, Key, Mood
            if (project.bpm != null ||
                project.key != null ||
                project.mood != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    if (project.bpm != null) ...[
                      Text('${project.bpm} BPM',
                          style: const TextStyle(
                              color: Color(0xFF9C27B0), fontSize: 14)),
                      const SizedBox(width: 16),
                    ],
                    if (project.key != null) ...[
                      Text(project.key!,
                          style: const TextStyle(
                              color: Color(0xFF9C27B0), fontSize: 14)),
                      const SizedBox(width: 16),
                    ],
                    if (project.mood != null)
                      Text(project.mood!,
                          style: const TextStyle(
                              color: Color(0xFF9C27B0), fontSize: 14)),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Main Content - NO HORIZONTAL LINES
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCleanTimeline(),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(0, 0, 0, 0),
              Color.fromARGB(3, 104, 58, 183)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _showAddOptions,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _cleanupDuplicatePhaseStatuses() {
    // Remove any "Phase:" status updates that are duplicates
    project.statusUpdates.removeWhere(
        (status) => status.status.startsWith('Phase:') && status.isCustom);
  }

  // HELPER METHOD TO SAVE PROJECT TO STORAGE
  Future<void> _saveProjectToStorage() async {
    try {
      // Update project with current phases and items
      project.statusUpdates = project.statusUpdates;
      project.itemOrders = itemOrders; // CRITICAL: Save current orders
      project.feedbacks = project.feedbacks;
      project.references = project.references;
      project.todoList = project.todoList;
      project.simpleNotes = project.simpleNotes;

      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getStringList('projects') ?? [];
      final projects = projectsJson
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

      // Update this project
      final index = projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        projects[index] = project;
      }

      // Save updated list
      final updatedProjectsJson =
          projects.map((project) => jsonEncode(project.toJson())).toList();
      await prefs.setStringList('projects', updatedProjectsJson);
    } catch (e) {}
  }

  Widget _buildCleanTimeline() {
    final allItems = _getAllTimelineItems();

    if (allItems.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // VERTICAL TIMELINE LINE - CALCULATED HEIGHT
        Positioned(
          left: 5, // Position line behind the dots
          top: 3,
          child: Container(
            width: 2,
            height: (allItems.length * 120.0) +
                20, // Longer line to reach last panel
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                  Color.fromARGB(255, 255, 255, 255),
                ],
              ),
            ),
          ),
        ),

        // TIMELINE ITEMS
        ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildTimelineItem(item, index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    switch (item['type']) {
      case 'phase':
        return _buildPhaseCard(item['data']);
      case 'note':
        return _buildNoteCard(item['data']);
      case 'status':
        return _buildStatusCard(item['data']);
      case 'feedback':
        return _buildFeedbackCard(item['data']);
      case 'reference':
        return _buildReferenceCard(item['data']);
      case 'task':
        return _buildTaskCard(item['data']);
      case 'simplenote':
        return _buildSimpleNoteCard(item['data']);
      default:
        return const SizedBox.shrink();
    }
  }

  String _limitPhaseText(String text) {
    final words = text.split(' ');
    if (words.length > 5) {
      return '${words.take(5).join(' ')}...';
    }
    return text;
  }

  Color _getStickyNoteColor(String noteId) {
    final stickyColors = [
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFF5722), // Red Orange
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFFFC107), // Amber
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF009688), // Teal
    ];

    return stickyColors[noteId.hashCode.abs() % stickyColors.length];
  }

  Widget _buildSimpleNoteCard(SimpleNote simpleNote) {
    final stickyColor = _getStickyNoteColor(simpleNote.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 16, right: 16),
            decoration: BoxDecoration(
              color: stickyColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: stickyColor,
                borderRadius: BorderRadius.circular(0), // No rounded borders
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with NOTE label and close button only
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: const Text(
                            'NOTE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              itemOrders.remove('simplenote:${simpleNote.id}');
                              project.simpleNotes.remove(simpleNote);
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area with grey background
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color:
                          Color(0xFF424242), // Grey background like sticky note
                    ),
                    child: Text(
                      simpleNote.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard(ProjectPhaseEntry phase) {
    final colors = [
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF2196F3), // Blue
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFCDDC39), // Lime
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFFC107), // Amber
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF5722), // Deep Orange
    ];

    // Use phase ID to get consistent color
    final phaseColor = colors[phase.id.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: phaseColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Black cell with phase name
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _limitPhaseText(phase.name).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Line from center of black cell to timestamp
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // Timestamp at the end of line
              Text(
                _formatTimestamp(phase.timestamp),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 8),

              // Close button
              GestureDetector(
                onTap: () {
                  setState(() {
                    itemOrders.remove('phase:${phase.id}');
                    projectPhases.removeWhere((p) => p.id == phase.id);
                  });
                },
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 16, right: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5C97E),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C97E),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getNoteTypeLabel(note.type),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF8F8F8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            itemOrders.remove('note:${note.id}');
                            project.attachedNotes
                                .removeWhere((n) => n.id == note.id);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF121212),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF121212),
                      height: 1.3,
                    ),
                  ),
                  if (note.shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      note.shortDescription,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF121212),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF121212).withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      note.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF121212),
                        height: 1.5,
                      ),
                    ),
                  ),
                  // ADD VOICE NOTES PLAYBACK FOR MUSIC NOTES
                  if (note.type == NoteType.music && note.musicSections != null)
                    ...note.musicSections!
                        .where(
                            (section) => section.voiceNotes?.isNotEmpty == true)
                        .map(
                          (section) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                '${section.type} Voice Notes:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF121212),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...section.voiceNotes!.map(
                                (voiceNote) => VoiceNotePlayerWidget(
                                  voiceNote: voiceNote,
                                  onDelete: () {
                                    // Read-only in project view
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _generateStatusGradient(ProjectStatus status) {
    final baseColors = [
      const Color(0xFF667eea).withOpacity(0.9), // Vibrant but not neon
      const Color(0xFFf093fb).withOpacity(0.9),
      const Color(0xFF4facfe).withOpacity(0.9),
      const Color(0xFF43e97b).withOpacity(0.9),
      const Color(0xFFfa709a).withOpacity(0.9),
      const Color(0xFF6a11cb).withOpacity(0.9),
      const Color(0xFF2575fc).withOpacity(0.9),
      const Color(0xFFa8edea).withOpacity(0.9),
    ];

    final random = status.timestamp.millisecond;
    final color1 = baseColors[random % baseColors.length];
    final color2 = baseColors[(random + 1) % baseColors.length];

    return [color1, color2];
  }

  Widget _buildStatusCard(ProjectStatus status) {
    const isNote = false; // Remove note detection since we removed the emoji
    final gradientColors = _generateStatusGradient(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 12, right: 16),
            decoration: BoxDecoration(
              color: gradientColors.first,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Black cell with STATUS/NOTE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          // ignore: dead_code
                          isNote ? 'NOTE' : 'STATUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // Line from center of black cell to timestamp
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),

                      // Timestamp at the end of line
                      Text(
                        _formatTimestamp(status.timestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Close button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            itemOrders.remove(
                                'status:${status.timestamp.millisecondsSinceEpoch}');
                            project.statusUpdates.remove(status);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    status.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(ProjectFeedback feedback) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 16, right: 16),
            decoration: BoxDecoration(
              color: feedback.type.color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    feedback.type.color,
                    const Color.fromARGB(255, 255, 154, 59),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feedback.type.label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            itemOrders.remove('feedback:${feedback.id}');
                            project.feedbacks.remove(feedback);
                          });
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feedback.content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (feedback.byWho != null && feedback.byWho!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'By: ${feedback.byWho}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(ProjectReference ref) {
    final color = _getLinkColor(ref.linkType);
    final platformInfo = _getPlatformInfo(ref.linkType, ref.url);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 16, right: 16),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Platform icon and label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                platformInfo['icon'] ?? '🔗',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                platformInfo['label'] ?? 'LINK',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        Row(
                          children: [
                            // Copy button
                            if (ref.url != null) ...[
                              GestureDetector(
                                onTap: () => _copyToClipboard(ref.url!),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Open button
                            if (ref.url != null) ...[
                              GestureDetector(
                                onTap: () => _openLink(ref.url!),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Delete button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  final refIndex =
                                      project.references.indexOf(ref);
                                  if (refIndex != -1) {
                                    itemOrders.remove('reference:$refIndex');
                                    project.references.remove(ref);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content area with preview/embed
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: _buildLinkPreview(ref, platformInfo),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLinkColor(String linkType) {
    switch (linkType) {
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'apple':
        return const Color(0xFFFA233B);
      case 'soundcloud':
        return const Color(0xFFFF5500);
      case 'bandcamp':
        return const Color(0xFF629AA0);
      default:
        return const Color(0xFF2196F3);
    }
  }

  Map<String, String> _getPlatformInfo(String linkType, String? url) {
    switch (linkType) {
      case 'spotify':
        return {'icon': '🎵', 'label': 'SPOTIFY'};
      case 'youtube':
        return {'icon': '📺', 'label': 'YOUTUBE'};
      case 'apple':
        return {'icon': '🍎', 'label': 'APPLE MUSIC'};
      case 'soundcloud':
        return {'icon': '☁️', 'label': 'SOUNDCLOUD'};
      case 'bandcamp':
        return {'icon': '🎼', 'label': 'BANDCAMP'};
      default:
        return {'icon': '🔗', 'label': 'LINK'};
    }
  }

  Widget _buildLinkPreview(
      ProjectReference ref, Map<String, String> platformInfo) {
    switch (ref.linkType) {
      case 'spotify':
        return _buildSpotifyEmbed(ref);
      case 'youtube':
        return _buildYouTubeEmbed(ref);
      case 'apple':
        return _buildAppleMusicEmbed(ref);
      case 'soundcloud':
        return _buildSoundCloudEmbed(ref);
      default:
        return _buildGenericPreview(ref);
    }
  }

  Widget _buildSpotifyEmbed(ProjectReference ref) {
    // Extract track info from URL
    final spotifyInfo = _extractSpotifyInfo(ref.url ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Mock album art
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1DB954),
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1DB954), Color(0xFF1ed760)],
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spotifyInfo['type'] ?? 'Spotify Track',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Open in Spotify',
                      style: TextStyle(
                        color: Color(0xFF1DB954),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ref.url != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ref.url!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYouTubeEmbed(ProjectReference ref) {
    final videoId = _extractYouTubeVideoId(ref.url ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mock video thumbnail
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'YouTube',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ref.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Watch on YouTube',
            style: TextStyle(
              color: Color(0xFFFF0000),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (ref.url != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ref.url!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppleMusicEmbed(ProjectReference ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFA233B), Color(0xFFFF6B6B)],
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Apple Music',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Open in Apple Music',
                      style: TextStyle(
                        color: Color(0xFFFA233B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCloudEmbed(ProjectReference ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5500), Color(0xFFFF7700)],
              ),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'SoundCloud',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ref.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview(ProjectReference ref) {
    final domain = _extractDomain(ref.url ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (domain.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        domain,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (ref.url != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ref.url!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskCard(ProjectTask task) {
    // Dark and bright color pairs
    final colorPairs = [
      {
        'dark': const Color(0xFF1B5E20),
        'bright': const Color(0xFF4CAF50)
      }, // Green pair
      {
        'dark': const Color(0xFF0D47A1),
        'bright': const Color(0xFF2196F3)
      }, // Blue pair
      {
        'dark': const Color(0xFF4A148C),
        'bright': const Color(0xFF9C27B0)
      }, // Purple pair
      {
        'dark': const Color(0xFFB71C1C),
        'bright': const Color(0xFFFF5722)
      }, // Red pair
      {
        'dark': const Color(0xFFE65100),
        'bright': const Color(0xFFFF9800)
      }, // Orange pair
      {
        'dark': const Color(0xFF006064),
        'bright': const Color(0xFF00BCD4)
      }, // Cyan pair
      {
        'dark': const Color(0xFF1A237E),
        'bright': const Color(0xFF3F51B5)
      }, // Indigo pair
      {
        'dark': const Color(0xFF880E4F),
        'bright': const Color(0xFFE91E63)
      }, // Pink pair
      {
        'dark': const Color(0xFF263238),
        'bright': const Color(0xFF607D8B)
      }, // Blue Grey pair
      {
        'dark': const Color(0xFF3E2723),
        'bright': const Color(0xFF795548)
      }, // Brown pair
    ];

    // Get consistent color pair for this task
    final colorPair = colorPairs[task.id.hashCode.abs() % colorPairs.length];
    final taskColor = task.isCompleted
        ? colorPair['bright']! // Bright when completed
        : colorPair['dark']!; // Dark when incomplete

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 16, right: 16),
            decoration: BoxDecoration(
              color: taskColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: taskColor,
                borderRadius: BorderRadius.circular(0), // No borders
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            task.isCompleted = !task.isCompleted;
                          });
                        },
                        child: Icon(
                          task.isCompleted
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: const Text(
                          'TASK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final taskIndex = project.todoList.indexOf(task);
                            if (taskIndex != -1) {
                              itemOrders.remove('task:$taskIndex');
                              project.todoList.remove(task);
                            }
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.task,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF9C27B0),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to build something amazing?',
            style: TextStyle(
              color: Color(0xFFF8F8F8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add phases, notes, and more',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAllTimelineItems() {
    List<Map<String, dynamic>> allItems = [];

    // Add phases
    for (var phase in projectPhases) {
      final order = itemOrders['phase:${phase.id}'] ?? 1;
      allItems.add({'type': 'phase', 'data': phase, 'order': order});
    }

    // Add status updates
    for (var status in project.statusUpdates) {
      final order =
          itemOrders['status:${status.timestamp.millisecondsSinceEpoch}'] ??
              999;
      allItems.add({'type': 'status', 'data': status, 'order': order});
    }

    // Add feedbacks
    for (var feedback in project.feedbacks) {
      final order = itemOrders['feedback:${feedback.id}'] ?? 999;
      allItems.add({'type': 'feedback', 'data': feedback, 'order': order});
    }

    // Add attached notes - now using full note objects (NO VALIDATION NEEDED)
    for (int i = 0; i < project.attachedNotes.length; i++) {
      final note = project.attachedNotes[i];
      final order = itemOrders['note:${note.id}'] ?? 999;
      allItems.add({'type': 'note', 'data': note, 'order': order});
    }

    // Add references
    for (int i = 0; i < project.references.length; i++) {
      final ref = project.references[i];
      final order = itemOrders['reference:$i'] ?? 999;
      allItems.add({'type': 'reference', 'data': ref, 'order': order});
    }

    // Add tasks
    for (int i = 0; i < project.todoList.length; i++) {
      final task = project.todoList[i];
      final order = itemOrders['task:$i'] ?? 999;
      allItems.add({'type': 'task', 'data': task, 'order': order});
    }

    // Add simple notes
    for (var simpleNote in project.simpleNotes) {
      final order = itemOrders['simplenote:${simpleNote.id}'] ?? 999;
      allItems.add({'type': 'simplenote', 'data': simpleNote, 'order': order});
    }

    // Sort by add order (first added = first shown)
    allItems.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    return allItems;
  }

  String _getNoteTypeLabel(NoteType type) {
    switch (type) {
      case NoteType.music:
        return 'ID HUB';
      case NoteType.mixtip:
        return 'MIX';
      case NoteType.quick:
        return 'QUICK';
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text(
                'Add to Project',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8F8F8),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildAddOption(
                        'Phase', Icons.timeline, const Color(0xFF9C27B0), () {
                      Navigator.pop(context);
                      _showPhaseSelector();
                    }),
                    _buildAddOption(
                        'Status', Icons.update, const Color(0xFF2196F3), () {
                      Navigator.pop(context);
                      _showStatusSelector();
                    }),
                    _buildAddOption(
                        'Feedback', Icons.feedback, const Color(0xFFFF5722),
                        () {
                      Navigator.pop(context);
                      _showFeedbackDialog();
                    }),
                    _buildAddOption('Attach Notes', Icons.attach_file,
                        const Color(0xFF4CAF50), () {
                      Navigator.pop(context);
                      _showAttachNotesDialog();
                    }),
                    _buildAddOption(
                        'Add Link', Icons.link, const Color(0xFF00BCD4), () {
                      Navigator.pop(context);
                      _showAddLinkDialog();
                    }),
                    _buildAddOption(
                        'Add Task', Icons.task_alt, const Color(0xFFE91E63),
                        () {
                      Navigator.pop(context);
                      _showAddTaskDialog();
                    }),
                    _buildAddOption(
                        'Simple Note', Icons.note_add, const Color(0xFFFFC107),
                        () {
                      Navigator.pop(context);
                      _showSimpleNoteDialog();
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOption(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withOpacity(0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showPhaseSelector() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController customController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Add Phase',
            style: TextStyle(color: Color(0xFFF8F8F8)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: customController,
                  style: const TextStyle(color: Color(0xFFF8F8F8)),
                  decoration: InputDecoration(
                    hintText: 'Type custom phase (e.g., "Recording")...',
                    hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                    filled: true,
                    fillColor: const Color(0xFF3C3C3C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Or choose from presets:',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
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
                              title: Text(
                                phase,
                                style: const TextStyle(
                                  color: Color(0xFFF8F8F8),
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () {
                                _addPhase(phase);
                                Navigator.pop(context);
                              },
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Do NOT save the project here!
              },
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFB0B0B0))),
            ),
            TextButton(
              onPressed: () {
                if (customController.text.isNotEmpty) {
                  String phaseName = customController.text.trim();
                  // Don't add "Phase" automatically - let user type it if they want
                  _addPhase(phaseName);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add Custom',
                style: TextStyle(color: Color(0xFF9C27B0)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showStatusSelector() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController customController = TextEditingController();
        final TextEditingController searchController = TextEditingController();
        List<String> filteredStatuses = List.from(predefinedStatuses);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Add Status Update',
                style: TextStyle(color: Color(0xFFF8F8F8)),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom input field
                    TextField(
                      controller: customController,
                      style: const TextStyle(color: Color(0xFFF8F8F8)),
                      decoration: InputDecoration(
                        hintText: 'Type your own status...',
                        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                        filled: true,
                        fillColor: const Color(0xFF3C3C3C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Or choose from presets:',
                      style: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Search bar for presets
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Color(0xFFF8F8F8)),
                      decoration: InputDecoration(
                        hintText: 'Search presets',
                        hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
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
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFFB0B0B0),
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  searchController.clear();
                                  setDialogState(() {
                                    filteredStatuses =
                                        List.from(predefinedStatuses);
                                  });
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Color(0xFFB0B0B0),
                                ),
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value.isEmpty) {
                            filteredStatuses = List.from(predefinedStatuses);
                          } else {
                            filteredStatuses = predefinedStatuses
                                .where((status) => status
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Filtered preset list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredStatuses.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              filteredStatuses[index],
                              style: const TextStyle(
                                color: Color(0xFFF8F8F8),
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              _addStatus(filteredStatuses[index], false);
                              Navigator.pop(context);
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFB0B0B0)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (customController.text.isNotEmpty) {
                      _addStatus(customController.text, true);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Add Custom',
                    style: TextStyle(color: Color(0xFF2196F3)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController feedbackController =
            TextEditingController();
        final TextEditingController byWhoController = TextEditingController();
        FeedbackType selectedType = FeedbackType.good;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Add Feedback',
                style: TextStyle(color: Color(0xFFF8F8F8)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: feedbackController,
                    style: const TextStyle(color: Color(0xFFF8F8F8)),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback...',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: byWhoController,
                    style: const TextStyle(color: Color(0xFFF8F8F8)),
                    decoration: InputDecoration(
                      hintText: 'By: (optional)',
                      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                      filled: true,
                      fillColor: const Color(0xFF3C3C3C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: FeedbackType.values.map((type) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedType = type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedType == type
                                ? type.color
                                : const Color(0xFF3C3C3C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type.label,
                            style: TextStyle(
                              color: selectedType == type
                                  ? Colors.white
                                  : const Color(0xFFB0B0B0),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFFB0B0B0))),
                ),
                TextButton(
                  onPressed: () {
                    if (feedbackController.text.isNotEmpty) {
                      _addFeedback(feedbackController.text,
                          byWhoController.text, selectedType);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add',
                      style: TextStyle(color: Color(0xFFFF5722))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAttachNotesDialog() {
    // Only reload if availableNotes is empty (performance optimization)
    if (availableNotes.isEmpty) {
      _loadAvailableNotes();
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text(
                'Attach Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8F8F8),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: availableNotes.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF9C27B0),
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableNotes.length,
                        itemBuilder: (context, index) {
                          final note = availableNotes[index];
                          final isAttached =
                              project.attachedNotes.any((n) => n.id == note.id);

                          return ListTile(
                            title: Text(
                              note.title,
                              style: const TextStyle(
                                color: Color(0xFFF8F8F8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _getNoteTypeLabel(note.type),
                              style: const TextStyle(
                                color: Color(0xFFF5C97E),
                                fontSize: 12,
                              ),
                            ),
                            trailing: isAttached
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF4CAF50),
                                  )
                                : const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFFB0B0B0),
                                  ),
                            onTap: () {
                              setState(() {
                                if (isAttached) {
                                  itemOrders.remove('note:${note.id}');
                                  project.attachedNotes
                                      .removeWhere((n) => n.id == note.id);
                                } else {
                                  // Check for duplicates by ID
                                  if (!project.attachedNotes
                                      .any((n) => n.id == note.id)) {
                                    _globalOrderCounter++;
                                    itemOrders['note:${note.id}'] =
                                        _globalOrderCounter;
                                    project.attachedNotes
                                        .add(note); // Add full note object
                                  }
                                }
                              });
                              Navigator.pop(context);
                            },
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

  void _showAddLinkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController urlController = TextEditingController();

        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Add Reference Link',
            style: TextStyle(color: Color(0xFFF8F8F8)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Color(0xFFF8F8F8)),
                decoration: InputDecoration(
                  hintText: 'Reference name...',
                  hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF3C3C3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Color(0xFFF8F8F8)),
                decoration: InputDecoration(
                  hintText: 'URL (YouTube, Spotify, etc.)',
                  hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                  filled: true,
                  fillColor: const Color(0xFF3C3C3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFB0B0B0)),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _addReference(nameController.text, urlController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Color(0xFF00BCD4)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();

        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Add Task',
            style: TextStyle(color: Color(0xFFF8F8F8)),
          ),
          content: TextField(
            controller: taskController,
            style: const TextStyle(color: Color(0xFFF8F8F8)),
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              filled: true,
              fillColor: const Color(0xFF3C3C3C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFB0B0B0)),
              ),
            ),
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty) {
                  _addTask(taskController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Color(0xFFE91E63)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSimpleNoteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController noteController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Add Simple Note',
              style: TextStyle(color: Color(0xFFF8F8F8))),
          content: TextField(
            controller: noteController,
            style: const TextStyle(color: Color(0xFFF8F8F8)),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your note...',
              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
              filled: true,
              fillColor: const Color(0xFF3C3C3C),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFFB0B0B0)))),
            TextButton(
              onPressed: () {
                if (noteController.text.isNotEmpty) {
                  _addSimpleNote(noteController.text);
                  Navigator.pop(context);
                }
              },
              child:
                  const Text('Add', style: TextStyle(color: Color(0xFFFFC107))),
            ),
          ],
        );
      },
    );
  }

  void _addStatus(String status, bool isCustom) {
    setState(() {
      _globalOrderCounter++;
      final statusObj = ProjectStatus(
        status: status,
        isCustom: isCustom,
        timestamp: DateTime.now(),
      );
      project.statusUpdates.add(statusObj);

      itemOrders['status:${statusObj.timestamp.millisecondsSinceEpoch}'] =
          _globalOrderCounter;
    });

    // Auto-save after adding
    _saveProjectToStorage();
  }

  void _addSimpleNote(String content) {
    setState(() {
      _globalOrderCounter++;
      final simpleNote = SimpleNote(
        content: content,
      );
      project.simpleNotes.add(simpleNote);

      itemOrders['simplenote:${simpleNote.id}'] = _globalOrderCounter;
    });

    // Auto-save after adding
    _saveProjectToStorage();
  }

  void _addFeedback(String content, String byWho, FeedbackType type) {
    setState(() {
      _globalOrderCounter++;
      final feedbackObj = ProjectFeedback(
        content: content,
        byWho: byWho.isEmpty ? null : byWho,
        type: type,
      );
      project.feedbacks.add(feedbackObj);

      itemOrders['feedback:${feedbackObj.id}'] = _globalOrderCounter;
    });

    // Auto-save after adding
    _saveProjectToStorage();
  }

  void _addReference(String name, String url) {
    setState(() {
      _globalOrderCounter++;

      // Detect link type
      String linkType = 'generic';
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        linkType = 'youtube';
      } else if (url.contains('spotify.com')) {
        linkType = 'spotify';
      } else if (url.contains('music.apple.com')) {
        linkType = 'apple';
      }

      project.references.add(ProjectReference(
        name: name,
        url: url.isEmpty ? null : url,
        linkType: linkType,
      ));

      itemOrders['reference:${project.references.length - 1}'] =
          _globalOrderCounter;
    });

    // Auto-save after adding
    _saveProjectToStorage();
  }

  void _addTask(String task) {
    setState(() {
      _globalOrderCounter++;
      project.todoList.add(ProjectTask(
        task: task,
      ));

      itemOrders['task:${project.todoList.length - 1}'] = _globalOrderCounter;
    });

    // Auto-save after adding
    _saveProjectToStorage();
  }

  void _addPhase(String phaseName) {
    setState(() {
      _globalOrderCounter++;
      // Simple phase naming - no duplication logic
      final phaseId = DateTime.now().millisecondsSinceEpoch.toString();
      projectPhases.add(ProjectPhaseEntry(
        id: phaseId,
        name: phaseName, // Use exact name as provided
        timestamp: DateTime.now(),
      ));

      itemOrders['phase:$phaseId'] = _globalOrderCounter;
    });

    // Auto-save after adding - but DON'T navigate away
    _saveProjectToStorage();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text(
            'Delete Project',
            style: TextStyle(color: Color(0xFFF8F8F8)),
          ),
          content: const Text(
            'Are you sure you want to delete this project? This action cannot be undone.',
            style: TextStyle(color: Color(0xFFB0B0B0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFB0B0B0)),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Delete from local storage
                final prefs = await SharedPreferences.getInstance();
                final projectsJson = prefs.getStringList('projects') ?? [];
                final projects = projectsJson
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

                // Remove this project
                projects.removeWhere((p) => p.id == project.id);

                // Save updated list
                final updatedProjectsJson = projects
                    .map((project) => jsonEncode(project.toJson()))
                    .toList();
                await prefs.setStringList('projects', updatedProjectsJson);

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to project list

                // Call onDelete callback if provided
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project deleted successfully!'),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Color(0xFFFF6B6B)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// Helper methods
Map<String, String> _extractSpotifyInfo(String url) {
  try {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final type = pathSegments[0];
      return {'type': 'Spotify ${type.capitalize()}'};
    }
  } catch (e) {
    // Handle error
  }
  return {'type': 'Spotify Track'};
}

String _extractYouTubeVideoId(String url) {
  try {
    final uri = Uri.parse(url);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    }
  } catch (e) {
    // Handle error
  }
  return '';
}

String _extractDomain(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host;
  } catch (e) {
    return '';
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
