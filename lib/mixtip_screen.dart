import 'package:flutter/material.dart';

// Mix Tip Screen
class MixTipScreen extends StatefulWidget {
  final Function(String, String, String) onSave;

  const MixTipScreen({super.key, required this.onSave});

  @override
  State<MixTipScreen> createState() => _MixTipScreenState();
}

class _MixTipScreenState extends State<MixTipScreen> {
  String? selectedElement;
  final TextEditingController _descController = TextEditingController();

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                  const Text(
                    'Mix Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8F8F8),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Mix Element',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedElement == null)
                      GestureDetector(
                        onTap: _showElementPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3C3C3C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Choose Element...',
                                style: TextStyle(
                                  color: Color(0xFFB0B0B0),
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFB0B0B0),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5C97E),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedElement!,
                                style: const TextStyle(
                                  color: Color(0xFF121212),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedElement = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFF121212),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                    controller: _descController,
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
              ),
              const SizedBox(height: 20),
              if (selectedElement != null)
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  MixTipNoteScreen(
                            title: selectedElement!,
                            shortDescription: _descController.text,
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
              const Spacer(),
            ],
          ),
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
          height: MediaQuery.of(context).size.height * 0.6,
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

// Mix Tip Note Screen
class MixTipNoteScreen extends StatefulWidget {
  final String title;
  final String shortDescription;
  final Function(String, String, String) onSave;

  const MixTipNoteScreen({
    super.key,
    required this.title,
    required this.shortDescription,
    required this.onSave,
  });

  @override
  State<MixTipNoteScreen> createState() => _MixTipNoteScreenState();
}

class _MixTipNoteScreenState extends State<MixTipNoteScreen> {
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
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
                  const Text(
                    'Mix Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8F8F8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      widget.onSave(
                        widget.title,
                        widget.shortDescription,
                        _contentController.text,
                      );
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (mounted) {
                        // ignore: use_build_context_synchronously
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
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5C97E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF121212),
                  ),
                ),
              ),
              if (widget.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.shortDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF8F8F8),
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Write your mixing tips and notes...\n\nFor example:\n• EQ settings\n• Compression ratios\n• Effects chains\n• Automation tips',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Color(0xFFB0B0B0),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}
