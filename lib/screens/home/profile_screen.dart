import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final authService = AuthService();
    final currentUserId = firestoreService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: currentUserId == null
          ? const Center(child: Text('No logged-in user found.'))
          : SingleChildScrollView(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: firestoreService.getCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Profile not found.'),
                  );
                }

                final data =
                snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> followers =
                    data['followers'] ?? [];
                final List<dynamic> following =
                    data['following'] ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        data['username'] ?? 'No Username',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['email'] ?? ''),
                      const SizedBox(height: 8),
                      Text(
                        data['bio'] ?? '',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${followers.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Followers'),
                            ],
                          ),
                          const SizedBox(width: 32),
                          Column(
                            children: [
                              Text(
                                '${following.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Following'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(),

            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'My Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getUserPosts(
                userId: currentUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No posts yet.'),
                  );
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final data =
                    post.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(
                                  fontSize: 16),
                            ),

                            const SizedBox(height: 8),

                            if ((data['imageUrl'] ?? '')
                                .toString()
                                .isNotEmpty)
                              ClipRRect(
                                borderRadius:
                                BorderRadius.circular(
                                    12),
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
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}