// firebase_service.dart - Clean version without dead code
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'dart:html' as html show window;
import 'models.dart';
import 'firebase_options.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static bool _isInitialized = false;
  static const String _userId = 'syntanote_user';

  // Initialize Firebase
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      WidgetsFlutterBinding.ensureInitialized();

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _isInitialized = true;
      return await _testConnection();
    } catch (e) {
      if (kDebugMode) print('Firebase init error: $e');
      return false;
    }
  }

  // Test connection
  static Future<bool> _testConnection() async {
    try {
      await _firestore.collection('users').doc('_test').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getFirebaseStatus() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          if (kDebugMode) print('🔥 Firebase initialization failed');
          return "Init Failed ❌";
        }
      }

      // Simple connection test
      await _firestore.collection('users').doc('_test').get();

      if (kDebugMode) print('🔥 Firebase connection successful');
      return "Online ✅";
    } catch (e) {
      if (kDebugMode) print('🔥 Firebase connection error: $e');
      if (e.toString().contains('cors')) {
        return "CORS Error ❌";
      } else if (e.toString().contains('permission')) {
        return "Permission ❌";
      } else if (e.toString().contains('network')) {
        return "Network ❌";
      } else {
        return "Error ❌";
      }
    }
  }

  // Force connection on app start
  static Future<void> forceConnection() async {
    if (kDebugMode) print('🔥 Forcing Firebase connection...');

    try {
      await initialize();
      await getFirebaseStatus();
      if (kDebugMode) print('🔥 Force connection complete');
    } catch (e) {
      if (kDebugMode) print('🔥 Force connection failed: $e');
    }
  }

  // Save notes
  static Future<bool> saveNotes(List<Note> notes) async {
    if (!_isInitialized && !await initialize()) return false;

    try {
      final userDoc = _firestore.collection('users').doc(_userId);
      await userDoc.set({
        'notes': notes.map((note) => note.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'noteCount': notes.length,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      if (kDebugMode) print('Save notes error: $e');
      return false;
    }
  }

  // Load notes
  static Future<List<Note>> loadNotes() async {
    if (!_isInitialized && !await initialize()) return [];

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists || userDoc.data()?['notes'] == null) {
        return [];
      }

      final notesList = userDoc.data()!['notes'] as List;
      return notesList
          .map((item) {
            try {
              return Note.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((note) => note != null)
          .cast<Note>()
          .toList();
    } catch (e) {
      if (kDebugMode) print('Load notes error: $e');
      return [];
    }
  }

  // Save projects
  static Future<bool> saveProjects(List<ProjectStudio> projects) async {
    if (!_isInitialized && !await initialize()) return false;

    try {
      final projectsDoc = _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc('all_projects');

      await projectsDoc.set({
        'projects': projects.map((p) => p.toJson()).toList(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'projectCount': projects.length,
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('Save projects error: $e');
      return false;
    }
  }

  // Load projects
  static Future<List<ProjectStudio>> loadProjects() async {
    if (!_isInitialized && !await initialize()) return [];

    try {
      final projectsDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc('all_projects')
          .get();

      if (!projectsDoc.exists || projectsDoc.data()?['projects'] == null) {
        return [];
      }

      final projectsList = projectsDoc.data()!['projects'] as List;
      return projectsList
          .map((item) {
            try {
              return ProjectStudio.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((project) => project != null)
          .cast<ProjectStudio>()
          .toList();
    } catch (e) {
      if (kDebugMode) print('Load projects error: $e');
      return [];
    }
  }

  // Upload voice recording
  static Future<String?> uploadVoiceRecording(
    String fileName,
    Uint8List audioData,
  ) async {
    if (!_isInitialized && !await initialize()) return null;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final storageRef = _storage
          .ref()
          .child('voice_recordings')
          .child(_userId)
          .child(uniqueFileName);

      final uploadTask = storageRef.putData(
        audioData,
        SettableMetadata(contentType: 'audio/webm'),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print('Upload voice error: $e');
      return null;
    }
  }
}
