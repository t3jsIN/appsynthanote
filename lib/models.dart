import 'package:flutter/material.dart';

// Data Models
enum NoteType { quick, music, mixtip }

class Note {
  final String id;
  final String title;
  final String shortDescription;
  final String? inspiration;
  final String content;
  final NoteType type;
  final String preview;
  final List<MusicSection>? musicSections;

  Note({
    String? id,
    required this.title,
    required this.shortDescription,
    this.inspiration,
    required this.content,
    required this.type,
    required this.preview,
    this.musicSections,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'shortDescription': shortDescription,
        'inspiration': inspiration,
        'content': content,
        'type': type.index,
        'preview': preview,
        'musicSections': musicSections?.map((s) => s.toJson()).toList(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Untitled',
        shortDescription: json['shortDescription'] ?? '',
        inspiration: json['inspiration'],
        content: json['content'] ?? '',
        type: NoteType.values[json['type'] ?? 0],
        preview: json['preview'] ?? '',
        musicSections: (json['musicSections'] as List?)
            ?.map((s) => MusicSection.fromJson(s))
            .toList(),
      );
}

class MusicSection {
  final String type;
  final String subtitle;
  final String content;
  final List<VoiceNote>? voiceNotes;

  MusicSection({
    required this.type,
    required this.subtitle,
    required this.content,
    this.voiceNotes,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'subtitle': subtitle,
        'content': content,
        'voiceNotes': voiceNotes?.map((v) => v.toJson()).toList(),
      };

  factory MusicSection.fromJson(Map<String, dynamic> json) => MusicSection(
        type: json['type'] ?? 'Untitled',
        subtitle: json['subtitle'] ?? '',
        content: json['content'] ?? '',
        voiceNotes: (json['voiceNotes'] as List?)
            ?.map((v) => VoiceNote.fromJson(v))
            .toList(),
      );

  MusicSection copyWith({
    String? type,
    String? subtitle,
    String? content,
    List<VoiceNote>? voiceNotes,
  }) {
    return MusicSection(
      type: type ?? this.type,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      voiceNotes: voiceNotes ?? this.voiceNotes,
    );
  }
}

class VoiceNote {
  final String id;
  final String filePath;
  final String title;
  final DateTime createdAt;
  final int durationMs;

  VoiceNote({
    required this.id,
    required this.filePath,
    required this.title,
    required this.createdAt,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': durationMs,
      };

  factory VoiceNote.fromJson(Map<String, dynamic> json) => VoiceNote(
        id: json['id'] ?? '',
        filePath: json['filePath'] ?? '',
        title: json['title'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        durationMs: json['durationMs'] ?? 0,
      );
}

class MusicSectionController {
  final MusicSection section;
  final TextEditingController textController;
  final List<VoiceNote> voiceNotes;

  MusicSectionController({
    required this.section,
  })  : textController = TextEditingController(text: section.content),
        voiceNotes = List.from(section.voiceNotes ?? []);

  void dispose() {
    textController.dispose();
  }

  MusicSection getUpdatedSection() {
    return section.copyWith(
      content: textController.text,
      voiceNotes: voiceNotes,
    );
  }

  void addVoiceNote(VoiceNote voiceNote) {
    voiceNotes.add(voiceNote);
  }

  void removeVoiceNote(String id) {
    voiceNotes.removeWhere((note) => note.id == id);
  }
}

// Project Studio Models
enum ProjectPhase {
  idea('Idea Phase'),
  draft('Draft'),
  breakdown('Breakdown'),
  drop('Drop'),
  finalMix('Final Mix'),
  done('Done');

  const ProjectPhase(this.label);
  final String label;
}

enum FeedbackType {
  good('Good Feedback', Color(0xFF1B5E20)), // Dark Green
  bad('Bad Feedback', Color(0xFFB71C1C)), // Dark Red
  mixed('Mixed Feedback', Color(0xFF0D47A1)); // Dark Blue

  const FeedbackType(this.label, this.color);
  final String label;
  final Color color;
}

class ProjectStudio {
  final String id;
  String title;
  List<Note> attachedNotes; // FIXED: Store full notes, not just IDs
  List<ProjectStatus> statusUpdates;
  List<ProjectFeedback> feedbacks;
  ProjectPhase currentPhase;
  List<ProjectReference> references;
  List<String> tags;
  int? bpm;
  String? key;
  String? mood;
  List<ProjectTask> todoList;
  DateTime createdAt;
  DateTime? completedAt;
  bool isCompleted;
  List<SimpleNote> simpleNotes;
  List<ProjectPhaseEntry> phases;
  Map<String, int> itemOrders; // Store item orders

  // Constructor with default values
  ProjectStudio({
    String? id,
    required this.title,
    List<Note>? attachedNotes, // FIXED: Changed from List<String>
    List<ProjectStatus>? statusUpdates,
    List<ProjectFeedback>? feedbacks,
    this.currentPhase = ProjectPhase.idea,
    List<ProjectReference>? references,
    List<String>? tags,
    this.bpm,
    this.key,
    this.mood,
    List<ProjectTask>? todoList,
    List<SimpleNote>? simpleNotes,
    DateTime? createdAt,
    this.completedAt,
    this.isCompleted = false,
    List<ProjectPhaseEntry>? phases,
    Map<String, int>? itemOrders,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        attachedNotes =
            attachedNotes ?? [], // FIXED: Initialize as empty Note list
        statusUpdates = statusUpdates ?? [],
        feedbacks = feedbacks ?? [],
        references = references ?? [],
        tags = tags ?? [],
        todoList = todoList ?? [],
        simpleNotes = simpleNotes ?? [],
        phases = phases ?? [],
        itemOrders = itemOrders ?? {};

  String get displayTitle => title.isEmpty ? 'Untitled Project' : title;

  Duration? get projectDuration {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'attachedNotes': attachedNotes
          .map((note) => note.toJson())
          .toList(), // FIXED: Save full note data
      'statusUpdates': statusUpdates.map((status) => status.toJson()).toList(),
      'feedbacks': feedbacks.map((feedback) => feedback.toJson()).toList(),
      'currentPhase': currentPhase.index,
      'references': references.map((ref) => ref.toJson()).toList(),
      'tags': tags,
      'bpm': bpm,
      'key': key,
      'mood': mood,
      'todoList': todoList.map((task) => task.toJson()).toList(),
      'simpleNotes': simpleNotes.map((note) => note.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'phases': phases.map((p) => p.toJson()).toList(),
      'itemOrders': itemOrders,
    };
  }

  factory ProjectStudio.fromJson(Map<String, dynamic> json) => ProjectStudio(
        id: json['id'],
        title: json['title'] ?? '',
        attachedNotes:
            (json['attachedNotes'] as List?) // FIXED: Load full note data
                    ?.map((noteJson) => Note.fromJson(noteJson))
                    .toList() ??
                [],
        statusUpdates: (json['statusUpdates'] as List?)
                ?.map((s) => ProjectStatus.fromJson(s))
                .toList() ??
            [],
        feedbacks: (json['feedbacks'] as List?)
                ?.map((f) => ProjectFeedback.fromJson(f))
                .toList() ??
            [],
        currentPhase: ProjectPhase.values[json['currentPhase'] ?? 0],
        references: (json['references'] as List?)
                ?.map((r) => ProjectReference.fromJson(r))
                .toList() ??
            [],
        tags: List<String>.from(json['tags'] ?? []),
        bpm: json['bpm'],
        key: json['key'],
        mood: json['mood'],
        todoList: (json['todoList'] as List?)
                ?.map((t) => ProjectTask.fromJson(t))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'])
            : null,
        isCompleted: json['isCompleted'] ?? false,
        simpleNotes: (json['simpleNotes'] as List<dynamic>?)
                ?.map((noteJson) => SimpleNote.fromJson(noteJson))
                .toList() ??
            [],
        phases: (json['phases'] as List?)
                ?.map((p) => ProjectPhaseEntry.fromJson(p))
                .toList() ??
            [],
        itemOrders: (json['itemOrders'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                  key,
                  (value is int)
                      ? value
                      : int.tryParse(value.toString()) ?? 999),
            ) ??
            {},
      );
}

class ProjectStatus {
  final String id;
  final String status;
  final DateTime timestamp;
  final bool isCustom;

  ProjectStatus({
    String? id,
    required this.status,
    DateTime? timestamp,
    this.isCustom = false,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'isCustom': isCustom,
      };

  factory ProjectStatus.fromJson(Map<String, dynamic> json) => ProjectStatus(
        id: json['id'],
        status: json['status'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        isCustom: json['isCustom'] ?? false,
      );
}

class ProjectFeedback {
  final String id;
  final String content;
  final String? byWho;
  final FeedbackType type;

  ProjectFeedback({
    String? id,
    required this.content,
    this.byWho,
    required this.type,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'byWho': byWho,
        'type': type.index,
      };

  factory ProjectFeedback.fromJson(Map<String, dynamic> json) =>
      ProjectFeedback(
        id: json['id'],
        content: json['content'] ?? '',
        byWho: json['byWho'],
        type: FeedbackType.values[json['type'] ?? 0],
      );
}

class SimpleNote {
  final String id;
  final String content;
  final DateTime timestamp;

  SimpleNote({
    String? id,
    required this.content,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SimpleNote.fromJson(Map<String, dynamic> json) => SimpleNote(
        id: json['id'],
        content: json['content'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );
}

class ProjectReference {
  final String id;
  final String name;
  final String? url;
  final String? title;
  final String? artist;
  final String? thumbnail;
  final String? platformIcon;
  final String linkType;

  ProjectReference({
    String? id,
    required this.name,
    this.url,
    this.title,
    this.artist,
    this.thumbnail,
    this.platformIcon,
    this.linkType = 'generic',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'title': title,
        'artist': artist,
        'thumbnail': thumbnail,
        'platformIcon': platformIcon,
        'linkType': linkType,
      };

  factory ProjectReference.fromJson(Map<String, dynamic> json) =>
      ProjectReference(
        id: json['id'],
        name: json['name'] ?? '',
        url: json['url'],
        title: json['title'],
        artist: json['artist'],
        thumbnail: json['thumbnail'],
        platformIcon: json['platformIcon'],
        linkType: json['linkType'] ?? 'generic',
      );
}

class ProjectTask {
  final String id;
  String task;
  bool isCompleted;
  final DateTime createdAt;

  ProjectTask({
    String? id,
    required this.task,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'task': task,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
        id: json['id'],
        task: json['task'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}

// Project Phase Entry for enhanced phase tracking
class ProjectPhaseEntry {
  final String id;
  final String name;
  final DateTime timestamp;

  ProjectPhaseEntry({
    required this.id,
    required this.name,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ProjectPhaseEntry.fromJson(Map<String, dynamic> json) =>
      ProjectPhaseEntry(
        id: json['id'],
        name: json['name'],
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      );
}
