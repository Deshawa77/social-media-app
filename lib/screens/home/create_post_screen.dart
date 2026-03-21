import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool isLoading = false;
  String? errorMessage;

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<void> submitPost() async {
    final content = postController.text.trim();

    if (content.isEmpty && selectedImage == null) {
      setState(() {
        errorMessage = 'Post cannot be empty.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      String? imageUrl;

      if (selectedImage != null) {
        imageUrl = await StorageService().uploadPostImage(selectedImage!);
      }

      await FirestoreService().createPost(
        content: content,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to create post: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: postController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What is on your mind?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pick Image'),
              ),
            ),
            const SizedBox(height: 16),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitPost,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}