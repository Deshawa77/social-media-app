import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'messages_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = firestoreService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: currentUserId == null
          ? const Center(child: Text('No logged-in user found.'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  query = value.trim().toLowerCase();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
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
                currentUserSnapshot.data!.data()
                as Map<String, dynamic>;
                final List<dynamic> following =
                    currentUserData['following'] ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getAllOtherUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No users found.'),
                      );
                    }

                    final allUsers = snapshot.data!.docs;

                    final users = allUsers.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final username =
                      (data['username'] ?? '').toString().toLowerCase();
                      return username.contains(query);
                    }).toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text('No matching users found.'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final data =
                        userDoc.data() as Map<String, dynamic>;

                        final String targetUserId = userDoc.id;
                        final String username =
                            data['username'] ?? 'No Username';
                        final bool isFollowing =
                        following.contains(targetUserId);

                        final List<dynamic> followers =
                            data['followers'] ?? [];
                        final List<dynamic> targetFollowing =
                            data['following'] ?? [];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius:
                                          BorderRadius.circular(18),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                fontWeight:
                                                FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              data['bio'] ?? '',
                                              maxLines: 2,
                                              overflow:
                                              TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color:
                                                Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${followers.length} followers • ${targetFollowing.length} following',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            final chatId =
                                            await firestoreService
                                                .createOrOpenChat(
                                              targetUserId: targetUserId,
                                              targetUsername: username,
                                            );

                                            if (!context.mounted) return;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    MessagesScreen(
                                                      chatId: chatId,
                                                      otherUserId:
                                                      targetUserId,
                                                      otherUsername:
                                                      username,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon:
                                          const Icon(Icons.message),
                                          label: const Text('Message'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await firestoreService
                                                .toggleFollow(
                                              targetUserId: targetUserId,
                                              currentFollowing: following,
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
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}