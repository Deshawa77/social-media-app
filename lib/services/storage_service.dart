import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> uploadPostImage(File imageFile) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = _storage
        .ref()
        .child('post_images')
        .child(user.uid)
        .child('$fileName.jpg');

    await ref.putFile(imageFile);

    return await ref.getDownloadURL();
  }
}