// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FullScreenEditQuickNote extends StatefulWidget {
  final Note note;

  const FullScreenEditQuickNote({super.key, required this.note});

  @override
  State<FullScreenEditQuickNote> createState() =>
      _FullScreenEditQuickNoteState();
}

class _FullScreenEditQuickNoteState extends State<FullScreenEditQuickNote> {
  late TextEditingController _titleController;
  late TextEditingController _shortDescController;
  late TextEditingController _inspirationController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _shortDescController =
        TextEditingController(text: widget.note.shortDescription);
    _inspirationController =
        TextEditingController(text: widget.note.inspiration ?? '');
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _inspirationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Note> notes = [];

      // Load notes (Firebase first on web, then local fallback)
      if (kIsWeb) {
        try {
          await FirebaseService.initialize();
          final firebaseNotes = await FirebaseService.loadNotes();
          notes = firebaseNotes.isNotEmpty ? firebaseNotes : [];
        } catch (e) {}
      }

      // Always load local as backup
      if (notes.isEmpty) {
        final notesJson = prefs.getStringList('notes') ?? [];
        notes = notesJson
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
      }

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
            content: _contentController.text.trim(),
            type: NoteType.quick,
            preview: _contentController.text.trim().length > 80
                ? '${_contentController.text.trim().substring(0, 80)}...'
                : _contentController.text.trim(),
          );
          noteUpdated = true;
          break;
        }
      }

      if (!noteUpdated) {
        throw Exception('Note not found for update');
      }

      // Save locally first (guaranteed to work)
      final updatedNotesJson =
          notes.map((note) => jsonEncode(note.toJson())).toList();
      await prefs.setStringList('notes', updatedNotesJson);

      // Try Firebase save on web
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
            content: Text('✅ Quick note updated successfully!'),
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
                    'Edit Quick Note',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8F8F8),
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveNote,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form Fields
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Title Field
                    _buildInputField('Title', _titleController),
                    const SizedBox(height: 16),

                    // Short Description Field
                    _buildInputField('Short Description', _shortDescController),
                    const SizedBox(height: 16),

                    // Inspiration Field
                    _buildInputField(
                        'Inspiration (optional)', _inspirationController),
                    const SizedBox(height: 20),

                    // Main Content Field
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.4,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFF8F8F8),
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Edit your thoughts...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B0B0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
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
            fontSize: 14,
            color: Color(0xFFD4AF37),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFF8F8F8),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFF5C97E),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
