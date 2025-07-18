// ignore_for_file: deprecated_member_use, empty_catches

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'voice_recorder.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FullScreenEditMusicNote extends StatefulWidget {
  final Note note;

  const FullScreenEditMusicNote({super.key, required this.note});

  @override
  State<FullScreenEditMusicNote> createState() =>
      _FullScreenEditMusicNoteState();
}

class _FullScreenEditMusicNoteState extends State<FullScreenEditMusicNote> {
  late TextEditingController _titleController;
  late TextEditingController _shortDescController;
  late TextEditingController _inspirationController;
  List<MusicSectionController> sectionControllers = [];

  final Map<String, String> sectionTypes = {
    'Intro': 'DJ-mixable section with minimal elements',
    'Break': 'Emotional or atmospheric part',
    'Build-up': 'Tension rises with risers, filter sweeps',
    'Drop': 'Kick + bass return with main groove',
    'Main Loop': 'Extended groove section',
    'Outro': 'Gradual removal of elements for mixing',
    'Verse': 'Main vocal or melodic section',
    'Chorus': 'Hook section with strongest melody',
    'Bridge': 'Contrasting section that connects parts',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _shortDescController =
        TextEditingController(text: widget.note.shortDescription);
    _inspirationController =
        TextEditingController(text: widget.note.inspiration ?? '');

    // Load existing music sections
    if (widget.note.musicSections != null) {
      for (var section in widget.note.musicSections!) {
        sectionControllers.add(MusicSectionController(section: section));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _inspirationController.dispose();
    for (var controller in sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveNote() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ALWAYS load from local storage first - it's the source of truth
      final notesJson = prefs.getStringList('notes') ?? [];
      List<Note> notes = notesJson
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

      // Build updated sections
      List<MusicSection> sections = sectionControllers
          .map((controller) => controller.getUpdatedSection())
          .toList();

      String combinedContent =
          sections.map((s) => '${s.type}: ${s.content}').join('\n\n');

      String preview = sections.isNotEmpty
          ? (sections.first.content.isNotEmpty
              ? sections.first.content
              : sections.first.type)
          : 'Empty music note';

      // Update the specific note
      bool noteUpdated = false;
      for (int i = 0; i < notes.length; i++) {
        if (notes[i].id == widget.note.id) {
          notes[i] = Note(
            id: widget.note.id,
            title: _titleController.text.trim().isEmpty
                ? 'Untitled'
                : _titleController.text.trim(),
            shortDescription: _shortDescController.text.trim(),
            inspiration: _inspirationController.text.trim().isEmpty
                ? null
                : _inspirationController.text.trim(),
            content: combinedContent,
            type: NoteType.music,
            preview: preview.length > 80
                ? '${preview.substring(0, 80)}...'
                : preview,
            musicSections: sections,
          );
          noteUpdated = true;
          break;
        }
      }

      if (!noteUpdated) {
        throw Exception('Note not found for update');
      }

      // Save to local storage immediately
      final updatedNotesJson =
          notes.map((note) => jsonEncode(note.toJson())).toList();
      await prefs.setStringList('notes', updatedNotesJson);

      // Try Firebase save on web (but don't depend on it)
      if (kIsWeb) {
        try {
          await FirebaseService.saveNotes(notes);
        } catch (e) {
          // Continue anyway - local save succeeded
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Music note updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving note: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              padding: const EdgeInsets.all(20),
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
                    'Edit Music Note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8F8F8),
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Color(0xFF121212),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Header Fields
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInputField('Title', _titleController),
                  const SizedBox(height: 12),
                  _buildInputField('Short Description', _shortDescController),
                  const SizedBox(height: 12),
                  _buildInputField(
                      'Inspiration (optional)', _inspirationController),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Sections List
            Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: sectionControllers.length,
                      itemBuilder: (context, index) {
                        return _buildSectionCard(
                            sectionControllers[index], index);
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _showSectionPicker,
                        child: Container(
                          width: 56,
                          height: 56,
                          child: const Icon(
                            Icons.add,
                            color: Color.fromARGB(255, 0, 0, 0),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hint,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFFF8F8F8),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(
                color: Color(0xFFF5C97E),
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      MusicSectionController sectionController, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5C97E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getSectionDisplayName(sectionController.section.type, index),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF8F8F8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '* ${sectionController.section.subtitle} *',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF121212),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => Container(
                      height: 350,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF121212),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: VoiceRecorderWidget(
                        onVoiceNoteSaved: (voiceNote) {
                          setState(() {
                            sectionController.addVoiceNote(voiceNote);
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Color(0xFF121212),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    sectionControllers.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Section deleted'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF121212),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: sectionController.textController,
            maxLines: null,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF121212),
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: '*notes*',
              border: InputBorder.none,
              hintStyle: TextStyle(
                color: Color(0xFF121212),
                fontSize: 12,
              ),
            ),
          ),
          if (sectionController.voiceNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF121212), thickness: 1),
            const SizedBox(height: 8),
            const Text(
              'Voice Notes:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 8),
            ...sectionController.voiceNotes.map(
              (voiceNote) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: VoiceNotePlayerWidget(
                  voiceNote: voiceNote,
                  onDelete: () {
                    setState(() {
                      sectionController.removeVoiceNote(voiceNote.id);
                    });
                    try {
                      if (!kIsWeb) {
                        File(voiceNote.filePath).deleteSync();
                      }
                    } catch (e) {}
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSectionDisplayName(String type, int index) {
    int count = 1;
    for (int i = 0; i < index; i++) {
      if (sectionControllers[i].section.type == type) {
        count++;
      }
    }

    if (count > 1) {
      return '${type.toLowerCase()} $count';
    }
    return type.toLowerCase();
  }

  void _showSectionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
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
                'Add Section',
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
                  children: sectionTypes.entries.map((entry) {
                    return ListTile(
                      title: Text(
                        entry.key.toLowerCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF8F8F8),
                        ),
                      ),
                      subtitle: Text(
                        entry.value,
                        style: const TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          sectionControllers.add(MusicSectionController(
                            section: MusicSection(
                              type: entry.key,
                              subtitle: entry.value,
                              content: '',
                            ),
                          ));
                        });
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
