import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─── Profile Picture ──────────────────────────────────────────────────────

  Future<String?> uploadProfilePicture(String uid) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return null;

    final file = File(image.path);
    final ref = _storage.ref().child('profile_pictures/$uid.jpg');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await task.ref.getDownloadURL();
  }

  // ─── Resume ───────────────────────────────────────────────────────────────

  Future<String?> uploadResume(String uid) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    final pickedFile = result.files.first;
    if (pickedFile.path == null) return null;

    final file = File(pickedFile.path!);
    final ref = _storage.ref().child('resumes/$uid/${pickedFile.name}');

    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );

    return await task.ref.getDownloadURL();
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // File may not exist — ignore
    }
  }

  // ─── Upload progress stream ───────────────────────────────────────────────

  Stream<double> uploadWithProgress(File file, String path) {
    final ref = _storage.ref().child(path);
    final task = ref.putFile(file);
    return task.snapshotEvents.map(
      (snap) => snap.bytesTransferred / snap.totalBytes,
    );
  }
}
