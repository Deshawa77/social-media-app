import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final currentUserId = firestoreService.getCurrentUserId();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Users'),
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
          final List<dynamic> following =
              currentUserData['following'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getAllOtherUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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

              final users = snapshot.data!.docs;

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final data = userDoc.data() as Map<String, dynamic>;

                  final String targetUserId = userDoc.id;
                  final bool isFollowing =
                  following.contains(targetUserId);

                  final List<dynamic> followers =
                      data['followers'] ?? [];
                  final List<dynamic> targetFollowing =
                      data['following'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(data['username'] ?? 'No Username'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['bio'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            '${followers.length} followers • ${targetFollowing.length} following',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await firestoreService.toggleFollow(
                            targetUserId: targetUserId,
                            currentFollowing: following,
                          );
                        },
                        child: Text(
                          isFollowing ? 'Unfollow' : 'Follow',
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
    );
  }
}