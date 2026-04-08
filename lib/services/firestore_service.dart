import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() => _auth.currentUser?.uid;

  Future<Map<String, dynamic>> _getCurrentUserProfileData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data() ?? {};
  }

  String _buildChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> createPost({
    required String content,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final profile = await _getCurrentUserProfileData();
    final username = profile['username'] ?? 'Unknown User';

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

  Stream<DocumentSnapshot> getUserProfile({
    required String userId,
  }) {
    return _firestore.collection('users').doc(userId).snapshots();
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

  Future<void> updateProfile({
    required String username,
    required String bio,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    final userPosts = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();

    batch.update(userRef, {
      'username': username,
      'bio': bio,
    });

    for (final post in userPosts.docs) {
      batch.update(post.reference, {
        'username': username,
      });
    }

    await batch.commit();
  }

  Future<void> deletePost({
    required String postId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();

    if (!postDoc.exists) return;

    final data = postDoc.data() as Map<String, dynamic>;
    if (data['userId'] != user.uid) {
      throw Exception('You can only delete your own posts.');
    }

    final imageUrl = (data['imageUrl'] ?? '').toString();

    final comments = await postRef.collection('comments').get();
    final batch = _firestore.batch();

    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }

    batch.delete(postRef);
    await batch.commit();

    if (imageUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {}
    }
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
    final user = _auth.currentUser;
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
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final profile = await _getCurrentUserProfileData();
    final username = profile['username'] ?? 'Unknown User';

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

  Future<String> createOrOpenChat({
    required String targetUserId,
    required String targetUsername,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final profile = await _getCurrentUserProfileData();
    final currentUsername = profile['username'] ?? 'Unknown User';

    final chatId = _buildChatId(user.uid, targetUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': [user.uid, targetUserId],
      'participantNames': {
        user.uid: currentUsername,
        targetUserId: targetUsername,
      },
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String recipientUserId,
    required String recipientUsername,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    final profile = await _getCurrentUserProfileData();
    final currentUsername = profile['username'] ?? 'Unknown User';

    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': [user.uid, recipientUserId],
      'participantNames': {
        user.uid: currentUsername,
        recipientUserId: recipientUsername,
      },
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add({
      'senderId': user.uid,
      'senderUsername': currentUsername,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages({
    required String chatId,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots();
  }
}