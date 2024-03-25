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
        final names = doc['names'] as List<dynamic>;

        // Determine the index of the current user's email in the members list
        final index = members.indexWhere((element) => element != email);
        final displayName = names[index];
        // Exclude the current user's email from the list of members
        final filteredMembers =
            members.cast<String>().where((member) => member != email).toList();

        return GroupMessage(
          id: messageId,
          members: filteredMembers,
          displayName: displayName,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
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
                final displayName = message.displayName;
                return Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors
                        .grey[100], // Set your desired background color here
                  ),
                  child: ListTile(
                    title: Text('$displayName', style: TextStyle(fontSize: 20)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ConversationScreen(groupId: message.id),
                        ),
                      );
                    },
                  ),
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
  final String displayName;

  GroupMessage({
    required this.id,
    required this.members,
    required this.displayName,
  });
}
