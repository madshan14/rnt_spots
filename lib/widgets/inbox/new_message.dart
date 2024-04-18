
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/inbox/conversation.dart';

class NewMessageScreen extends StatelessWidget {
  final List<String> landlords;

  const NewMessageScreen({super.key, required this.landlords});

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
                      ConversationScreen(groupId: groupRef.id, index: 0,),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
