import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    final username = userData?['username'] ?? 'Unknown User';

    await _firestore.collection('posts').add({
      'userId': user.uid,
      'username': username,
      'content': content,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'likes': [],
    });
  }

  Stream<QuerySnapshot> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserPosts({
    required String userId,
  }) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getCurrentUserProfile() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    return _firestore.collection('users').doc(user.uid).snapshots();
  }

  Stream<QuerySnapshot> getAllOtherUsers() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: user.uid)
        .snapshots();
  }

  Future<void> toggleFollow({
    required String targetUserId,
    required List<dynamic> currentFollowing,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final currentUserRef = _firestore.collection('users').doc(user.uid);
    final targetUserRef = _firestore.collection('users').doc(targetUserId);

    if (currentFollowing.contains(targetUserId)) {
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([targetUserId]),
      });

      await targetUserRef.update({
        'followers': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([targetUserId]),
      });

      await targetUserRef.update({
        'followers': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> toggleLike({
    required String postId,
    required List<dynamic> likes,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final postRef = _firestore.collection('posts').doc(postId);

    if (likes.contains(user.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final username = userData?['username'] ?? 'Unknown User';

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'username': username,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getComments({
    required String postId,
  }) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}