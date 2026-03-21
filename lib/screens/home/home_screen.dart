import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = firestoreService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Feed'),
      ),
      body: currentUserId == null
          ? const Center(
        child: Text('No logged-in user found.'),
      )
          : StreamBuilder<DocumentSnapshot>(
        stream: firestoreService.getCurrentUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userSnapshot.hasError) {
            return Center(
              child: Text('Error: ${userSnapshot.error}'),
            );
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(
              child: Text('User profile not found.'),
            );
          }

          final userData =
          userSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> following = userData['following'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Something went wrong: ${snapshot.error}',
                  ),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No posts yet. Create your first post!',
                  ),
                );
              }

              final allPosts = snapshot.data!.docs;

              final filteredPosts = allPosts.where((post) {
                final data =
                post.data() as Map<String, dynamic>;
                final postUserId = data['userId'];

                return postUserId == currentUserId ||
                    following.contains(postUserId);
              }).toList();

              if (filteredPosts.isEmpty) {
                return const Center(
                  child: Text(
                    'No posts from followed users yet. Follow some users to see their posts.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  final post = filteredPosts[index];
                  final data =
                  post.data() as Map<String, dynamic>;

                  final List<dynamic> likes =
                      data['likes'] ?? [];
                  final bool isLiked =
                  likes.contains(currentUserId);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                child:
                                Icon(Icons.person),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  data['username'] ??
                                      'Unknown User',
                                  style:
                                  const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if ((data['content'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Text(
                              data['content'] ?? '',
                              style:
                              const TextStyle(
                                fontSize: 16,
                              ),
                            ),

                          const SizedBox(height: 8),

                          if ((data['imageUrl'] ?? '')
                              .toString()
                              .isNotEmpty)
                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(12),
                              child: Image.network(
                                data['imageUrl'],
                                height: 200,
                                width:
                                double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                          const SizedBox(height: 8),

                          Text(
                            formatTimestamp(
                              data['createdAt']
                              as Timestamp?,
                            ),
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              IconButton(
                                onPressed:
                                    () async {
                                  await firestoreService
                                      .toggleLike(
                                    postId:
                                    post.id,
                                    likes: likes,
                                  );
                                },
                                icon: Icon(
                                  isLiked
                                      ? Icons
                                      .favorite
                                      : Icons
                                      .favorite_border,
                                  color: isLiked
                                      ? Colors.red
                                      : null,
                                ),
                              ),
                              Text(
                                  '${likes.length} likes'),
                              const SizedBox(
                                  width: 16),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CommentsScreen(
                                            postId:
                                            post.id,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons
                                      .comment_outlined,
                                ),
                              ),
                              const Text(
                                  'Comments'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}