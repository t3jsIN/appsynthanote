// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FullScreenEditMixTip extends StatefulWidget {
  final Note note;

  const FullScreenEditMixTip({super.key, required this.note});

  @override
  State<FullScreenEditMixTip> createState() => _FullScreenEditMixTipState();
}

class _FullScreenEditMixTipState extends State<FullScreenEditMixTip> {
  late TextEditingController _shortDescController;
  late TextEditingController _contentController;
  late String selectedElement;

  @override
  void initState() {
    super.initState();
    selectedElement = widget.note.title;
    _shortDescController =
        TextEditingController(text: widget.note.shortDescription);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _shortDescController.dispose();
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
            title: selectedElement,
            shortDescription: _shortDescController.text.trim(),
            inspiration: null,
            content: _contentController.text.trim(),
            type: NoteType.mixtip,
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
            content: Text('✅ Mix tip updated successfully!'),
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

  final Map<String, List<String>> mixElements = {
    '🥁 DRUMS': [
      'Kick (Main)',
      'Kick (Layered / Low Tail)',
      'Snare (Main)',
      'Snare (Top Layer / Transient)',
      'Clap (Primary)',
      'Clap (Wide / Layered)',
      'Rimshot / Perc Shot',
      'Toms (Low / Mid / High)',
      'Hi-Hat (Closed)',
      'Hi-Hat (Open)',
      'Ride Cymbal',
      'Crash Cymbal (Intro / Impact)',
      'Reverse Cymbal',
      'Drum Fill (Loop or Sample)',
      'Shakers (L/R panned)',
      'Tambourine',
      'Bongo / Conga',
      'Woodblock',
      'Cowbell',
      'Cabasa',
      'Misc Perc (Triangle, Bells, etc.)',
      'Loop Percussion Layer',
      'Drum Loops (Glitched, Breaks)',
      'Kicks Group',
      'Snare & Clap Group',
      'Hi-Hat Group',
      'Percussion Bus',
      'Full Drum Bus'
    ],
    '🎵 MELODIC ELEMENTS': [
      'Sub Bass (Mono, Below 100Hz)',
      'Mid Bass (Growly/Distorted)',
      'Reece Bass (Wide / Moving)',
      'Pluck Bass',
      '808 (in Trap/Pop)',
      'Bass Bus (All basses grouped)',
      'Lead Synth (Mono Lead)',
      'Wide Synth (Stereo)',
      'Arp Synth (Arpeggiator)',
      'Pad (Ambient / Lush)',
      'Pluck (Melodic)',
      'Stab Synths (Short, rhythmic)',
      'FM Synth (Gritty tones)',
      'Saw Stack Lead (e.g. Supersaw)',
      'Strings (Synth-based or real)',
      'Chord Stack',
      'Guitar (Real or VST)',
      'Piano (Rhodes, Grand, Lo-Fi)',
      'Organ',
      'Harp / Dulcimer',
      'Keys (Electric, Digital)',
      'Melodic Synth Group',
      'Lead Group',
      'Pad Group',
      'All Instruments Bus'
    ],
    '🎙️ VOCALS': [
      'Lead Vocal (Dry)',
      'Lead Vocal (Processed)',
      'Vocal Doubles',
      'Vocal Harmony Stack',
      'Vocal Octaves (Lower / Higher)',
      'Vocal Chop Loop',
      'Reversed Vocals',
      'Vox Shots (e.g., "Hey!")',
      'Talkbox / Robot Vox',
      'Screams / Yells / Shouts',
      'Lead Vocal Group',
      'Backing Vocal Group',
      'Full Vocal Bus'
    ],
    '🌌 FX ELEMENTS': [
      'Noise Riser',
      'Synth Riser',
      'White Noise Downsweep',
      'Cymbal Downsweep',
      'Tonal Downlifter',
      'Impact (Boom)',
      'Sub Drop',
      'Hit / Slam / Metal',
      'Rumble (Layer under kick drops)',
      'Cinematic Hit',
      'Background Noise (Room Tone)',
      'Rain / Wind / Forest / Crowd',
      'Footsteps',
      'Paper / Cloth Rustle',
      'Door Slam',
      'Bottle Clinks',
      'Glass / Metal Hits',
      'Breathing',
      'Keys / Coins / Drops',
      'Texture Foley (Used in techno a lot)',
      'All FX Grouped',
      'Ambience Layer',
      'Foley Bus'
    ],
    '🎚️ GROUPS & BUSES': [
      'Master Channel',
      'Sidechain Trigger Channel (Ghost kick)',
      'Pre-Master Bus (for metering)',
      'Drum Bus',
      'Bass Bus',
      'Synth Bus',
      'Vocal Bus',
      'FX Bus',
      'Parallel Compression Bus',
      'Reverb Send (Drums)',
      'Reverb Send (Vocals)',
      'Delay Send (Vocal Slap/Quarter/8th)',
      'Saturation Bus',
      'Glue Bus (for final "gel")'
    ],
    '🎛️ OTHER / SPECIALS': [
      'Volume Automation Lane',
      'Filter Automation (for buildups)',
      'Sidechain Channel (e.g., LFO Tool or Kickstart)',
      'Pitch Riser Track (Buildup)',
      'Tempo Automation',
      'Noise Layer (Tonal White Noise for pad/lead)',
      'Transient Click (For Kicks)',
      'Sub Reinforcement Layer (Pure Sine or 30Hz bump)',
      'Grain FX / Resampled Audio',
      'Guitar DI Track',
      'Live Drum Loop',
      'Saxophone / Horn',
      'Flute / Native Instruments',
      'Violin Solo',
      'Ambient Mic Recording (for realism)'
    ],
    '✅ TECHNO-SPECIFIC': [
      'Modular Perc Loop',
      'Distorted Clap Layer',
      'Noise Drone (for tension)',
      'Low Mid Texture Loop (Vinyl hiss, machinery)',
      'Analog Synth Bass',
      'Off-beat Perc Loop (like in Afterlife tracks)',
      'Sidechained Pad Wash',
      'Kick Top Layer (Transient click only)'
    ]
  };

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
                    'Edit Mix Tip',
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

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Mix Element Selector
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
                            'Mix Element',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _showElementPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5C97E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedElement,
                                      style: const TextStyle(
                                        color: Color(0xFF121212),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF121212),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Short Description Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Short Description (optional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _shortDescController,
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
                    ),

                    const SizedBox(height: 20),

                    // Main Content
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
                          hintText:
                              'Edit your mixing tips and notes...\n\nFor example:\n• EQ settings\n• Compression ratios\n• Effects chains\n• Automation tips',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Color(0xFFB0B0B0),
                            height: 1.4,
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

  void _showElementPicker() {
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
                'Choose Mix Element',
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
                  children: mixElements.entries.expand((entry) {
                    return [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C3C3C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ...entry.value.map((item) => ListTile(
                            title: Text(
                              item,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFF8F8F8),
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedElement = item;
                              });
                              Navigator.pop(context);
                            },
                          )),
                    ];
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
