import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/inbox/conversation.dart';
import 'package:rnt_spots/widgets/inbox/new_message.dart';

class Inbox extends StatefulWidget {
  const Inbox({super.key});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  late Stream<List<GroupMessage>> _groupMessagesStream;

  @override
  void initState() {
    super.initState();
    _groupMessagesStream = _subscribeToGroupMessages();
  }

  Stream<List<GroupMessage>> _subscribeToGroupMessages() {
    final storage = SecureStorage();
    return FirebaseFirestore.instance
        .collection('GroupMessages')
        .snapshots()
        .asyncMap<List<GroupMessage>>((snapshot) async {
      final email = await storage.getFromSecureStorage("email");

      return snapshot.docs
          .where((doc) => (doc['members'] as List<dynamic>).contains(email))
          .map((doc) {
        final messageId = doc.id;
        final members = doc['members'] as List<dynamic>;

        // Exclude the current user's email from the list of members
        final filteredMembers = members
            .cast<String>()
            .where((member) => member != email)
            .toList();

        return GroupMessage(
          id: messageId,
          members: filteredMembers,
        );
      }).toList();
    });
  }

  Future<void> _createNewMessage(BuildContext context) async {
    // Retrieve all landlords
    final querySnapshot =
        await FirebaseFirestore.instance.collection('Users').get();
    final List<String> landlords = [];

    for (final doc in querySnapshot.docs) {
      final role = doc['role'] as String?;
      if (role == 'Landlord') {
        final email = doc['email'] as String;
        landlords.add(email);
      }
    }

    // Navigate to the screen to create a new message
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewMessageScreen(landlords: landlords),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewMessage(context),
          ),
        ],
      ),
      body: StreamBuilder<List<GroupMessage>>(
        stream: _groupMessagesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final groupMessages = snapshot.data!;
            return ListView.builder(
              itemCount: groupMessages.length,
              itemBuilder: (context, index) {
                final message = groupMessages[index];
                final member = message.members[0];
                return ListTile(
                  title: Text('Conversation with $member'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConversationScreen(groupId: message.id),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return const Text('No messages found.');
          }
        },
      ),
    );
  }
}

class GroupMessage {
  final String id;
  final List<String> members;

  GroupMessage({
    required this.id,
    required this.members,
  });
}
