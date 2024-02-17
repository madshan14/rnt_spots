import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/login/login.dart';

class Inbox extends StatefulWidget {
  const Inbox({Key? key});

  @override
  State<Inbox> createState() => _InboxState();
}

class _InboxState extends State<Inbox> {
  late Future<List<GroupMessage>> _groupMessages;

  @override
  void initState() {
    super.initState();
    _groupMessages = _fetchGroupMessages();
  }

  Future<List<GroupMessage>> _fetchGroupMessages() async {
    final storage = SecureStorage();
    final email = await storage.getFromSecureStorage("email");

    final querySnapshot = await FirebaseFirestore.instance
        .collection('GroupMessages')
        .where('members', arrayContains: email)
        .get();

    final List<GroupMessage> groupMessages = [];

    for (final doc in querySnapshot.docs) {
      final messageId = doc.id;
      final members = doc['members'] as List<dynamic>;

      // Exclude the current user's email from the list of members
      final filteredMembers =
          members.cast<String>().where((member) => member != email).toList();

      groupMessages.add(GroupMessage(
        id: messageId,
        members: filteredMembers,
      ));
    }

    return groupMessages;
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
      body: FutureBuilder<List<GroupMessage>>(
        future: _groupMessages,
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
                  title: Text(
                      'Conversation with $member'), // Displaying the name of the other member
                  subtitle: Text(""),
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

class ConversationScreen extends StatelessWidget {
  final String groupId;

  const ConversationScreen({Key? key, required this.groupId});

  Future<void> _sendMessage(String messageText) async {
    final storage = SecureStorage();
    final userEmail = await storage.getFromSecureStorage("email");
    await FirebaseFirestore.instance
        .collection('GroupMessages')
        .doc(groupId)
        .collection('Messages')
        .add({
      'text': messageText,
      'sender': userEmail,
      'timestamp': FieldValue.serverTimestamp()
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
      ),
      body: FutureBuilder<String>(
        future: storage.getFromSecureStorage("email"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final userEmail = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('GroupMessages')
                        .doc(groupId)
                        .collection('Messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final messages = snapshot.data!.docs;
                        return ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final messageText = message['text'];
                            final sender = message['sender'];
                            final timestamp = message['timestamp'] as Timestamp;
                            final timestampDate = timestamp.toDate();
                            final formattedTimestamp =
                                DateFormat('MMMM d, yyyy')
                                    .format(timestampDate);

                            final isCurrentUser = sender == userEmail;
                            final backgroundColor = isCurrentUser
                                ? Colors.lightGreenAccent
                                : Colors.lightBlueAccent;

                            return SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.5, // 50% of the width
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ListTile(
                                  title: Text(
                                    messageText,
                                    style: TextStyle(
                                      color:
                                          isCurrentUser ? Colors.black : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    formattedTimestamp,
                                    style: TextStyle(
                                      color:
                                          isCurrentUser ? Colors.black : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Text('No messages found.');
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          _sendMessage(_messageController.text);
                          _messageController.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Text('No messages found.');
          }
        },
      ),
    );
  }
}

class NewMessageScreen extends StatelessWidget {
  final List<String> landlords;

  const NewMessageScreen({Key? key, required this.landlords});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Message'),
      ),
      body: ListView.builder(
        itemCount: landlords.length,
        itemBuilder: (context, index) {
          final landlordEmail = landlords[index];
          return ListTile(
            title: Text(landlordEmail),
            onTap: () async {
              final storage = SecureStorage();
              final userEmail = await storage.getFromSecureStorage("email");
              final groupRef = await FirebaseFirestore.instance
                  .collection('GroupMessages')
                  .add({
                'members': [userEmail, landlordEmail]
              });
              Navigator.pop(context); // Close the new message screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ConversationScreen(groupId: groupRef.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
