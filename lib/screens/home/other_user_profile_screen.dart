import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'messages_screen.dart';

class OtherUserProfileScreen extends StatelessWidget {
  final String userId;
  final String username;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = firestoreService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
      ),
      body: currentUserId == null
          ? const Center(child: Text('No logged-in user found.'))
          : StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getCurrentUserProfile(),
        builder: (context, currentUserSnapshot) {
          if (currentUserSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (currentUserSnapshot.hasError) {
            return Center(
              child: Text('Error: ${currentUserSnapshot.error}'),
            );
          }

          if (!currentUserSnapshot.hasData ||
              !currentUserSnapshot.data!.exists) {
            return const Center(
              child: Text('Current user profile not found.'),
            );
          }

          final currentUserData =
          currentUserSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> currentFollowing =
              currentUserData['following'] ?? [];

          return StreamBuilder<DocumentSnapshot>(
            stream: firestoreService.getUserProfile(userId: userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(
                  child: Text('User profile not found.'),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final List<dynamic> followers = data['followers'] ?? [];
              final List<dynamic> following = data['following'] ?? [];
              final bool isFollowing =
              currentFollowing.contains(userId);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 48,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data['username'] ?? 'No Username',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['email'] ?? '',
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['bio'] ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '${followers.length}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Followers'),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 36,
                                    color: Colors.black12,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        '${following.length}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Following'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final chatId =
                                      await firestoreService
                                          .createOrOpenChat(
                                        targetUserId: userId,
                                        targetUsername:
                                        data['username'] ??
                                            'User',
                                      );

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MessagesScreen(
                                            chatId: chatId,
                                            otherUserId: userId,
                                            otherUsername:
                                            data['username'] ??
                                                'User',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.message),
                                    label: const Text('Message'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await firestoreService.toggleFollow(
                                        targetUserId: userId,
                                        currentFollowing:
                                        currentFollowing,
                                      );
                                    },
                                    child: Text(
                                      isFollowing
                                          ? 'Unfollow'
                                          : 'Follow',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Posts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                      firestoreService.getUserPosts(userId: userId),
                      builder: (context, postSnapshot) {
                        if (postSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (postSnapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Error: ${postSnapshot.error}',
                            ),
                          );
                        }

                        if (!postSnapshot.hasData ||
                            postSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No posts yet.'),
                          );
                        }

                        final posts = postSnapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final postData =
                            post.data() as Map<String, dynamic>;

                            return Padding(
                              padding:
                              const EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      if ((postData['content'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          postData['content'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                          ),
                                        ),
                                      if ((postData['imageUrl'] ?? '')
                                          .toString()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          child: Image.network(
                                            postData['imageUrl'],
                                            height: 210,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 10),
                                      Text(
                                        formatTimestamp(
                                          postData['createdAt']
                                          as Timestamp?,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}