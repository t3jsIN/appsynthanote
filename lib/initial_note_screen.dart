import 'package:flutter/material.dart';
import 'models.dart';
import 'music_note_screen.dart';
import 'quick_note_screen.dart';

// Initial Note Setup Screen
class InitialNoteScreen extends StatefulWidget {
  final bool isMusic;
  final Function(String, String, String?, String, List<MusicSection>?) onSave;

  const InitialNoteScreen(
      {super.key, required this.isMusic, required this.onSave});

  @override
  State<InitialNoteScreen> createState() => _InitialNoteScreenState();
}

class _InitialNoteScreenState extends State<InitialNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _inspirationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
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
                  Text(
                    widget.isMusic ? 'ID Hub' : 'Quick Note',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8F8F8),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 30),
              _buildInputField('Title', _titleController),
              const SizedBox(height: 20),
              _buildInputField('Short Description', _shortDescController),
              const SizedBox(height: 20),
              _buildInputField(
                  'Inspiration (optional)', _inspirationController),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (widget.isMusic) {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  MusicNoteScreen(
                            title: _titleController.text.isEmpty
                                ? 'Untitled'
                                : _titleController.text,
                            shortDescription: _shortDescController.text,
                            inspiration: _inspirationController.text,
                            onSave: widget.onSave,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero)
                                    .chain(CurveTween(
                                        curve: Curves.easeInOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  QuickNoteScreen(
                            title: _titleController.text.isEmpty
                                ? 'Untitled'
                                : _titleController.text,
                            shortDescription: _shortDescController.text,
                            inspiration: _inspirationController.text,
                            onSave: widget.onSave,
                          ),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            return SlideTransition(
                              position: animation.drive(
                                Tween(
                                        begin: const Offset(1.0, 0.0),
                                        end: Offset.zero)
                                    .chain(CurveTween(
                                        curve: Curves.easeInOutCubic)),
                              ),
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 300),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC7A144),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF121212),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
          ),
        ),
      ],
    );
  }
}
