// ignore_for_file: use_build_context_synchronously, deprecated_member_use, empty_catches

import 'package:flutter/material.dart';
import 'dart:io';
import 'models.dart';
import 'voice_recorder.dart';

// Music Note Screen with Voice Recording
class MusicNoteScreen extends StatefulWidget {
  final String title;
  final String shortDescription;
  final String? inspiration;
  final Function(String, String, String?, String, List<MusicSection>?) onSave;

  const MusicNoteScreen({
    super.key,
    required this.title,
    required this.shortDescription,
    this.inspiration,
    required this.onSave,
  });

  @override
  State<MusicNoteScreen> createState() => _MusicNoteScreenState();
}

class _MusicNoteScreenState extends State<MusicNoteScreen> {
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
  void dispose() {
    for (var controller in sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
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
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF8F8F8),
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      List<MusicSection> sections = sectionControllers
                          .map((controller) => controller.getUpdatedSection())
                          .toList();
                      String combinedContent = sections
                          .map((s) => '${s.type}: ${s.content}')
                          .join('\n\n');
                      widget.onSave(
                        widget.title,
                        widget.shortDescription,
                        widget.inspiration,
                        combinedContent,
                        sections,
                      );
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
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
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
                  Padding(
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
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212).withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFFF8F8F8),
                            size: 24,
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
                      height: 300,
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
              (voiceNote) => VoiceNotePlayerWidget(
                voiceNote: voiceNote,
                onDelete: () {
                  setState(() {
                    sectionController.removeVoiceNote(voiceNote.id);
                  });
                  try {
                    File(voiceNote.filePath).deleteSync();
                  } catch (e) {}
                },
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
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const Text(
                'Choose Section',
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
