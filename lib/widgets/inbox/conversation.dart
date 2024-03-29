
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/login/login.dart';

class ConversationScreen extends StatelessWidget {
  final String groupId;

  const ConversationScreen({super.key, required this.groupId});

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
    TextEditingController messageController = TextEditingController();

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
                                margin: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                padding: const EdgeInsets.all(10),
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
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type your message...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          _sendMessage(messageController.text);
                          messageController.clear();
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