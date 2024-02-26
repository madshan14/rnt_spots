import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnt_spots/dtos/users_dto.dart';

class AccountList extends StatefulWidget {
  const AccountList({Key? key}) : super(key: key);

  @override
  State<AccountList> createState() => _AccountListState();
}

class _AccountListState extends State<AccountList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final List<DocumentSnapshot> userDocs = snapshot.data!.docs;
          if (userDocs.isEmpty) {
            return Center(
              child: Text('No users found.'),
            );
          }
          // Filter out admin users
          final List<DocumentSnapshot> nonAdminUserDocs = userDocs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>)['role'] != 'Admin')
              .toList();
          if (nonAdminUserDocs.isEmpty) {
            return Center(
              child: Text('No non-admin users found.'),
            );
          }
          return ListView.builder(
            itemCount: nonAdminUserDocs.length,
            itemBuilder: (context, index) {
              final userData =
                  nonAdminUserDocs[index].data() as Map<String, dynamic>;
              final user = UserDto(
                id: nonAdminUserDocs[index].id,
                firstName: userData['firstName'],
                lastName: userData['lastName'],
                email: userData['email'],
                role: userData['role'],
                balance: userData['Balance'] ?? 0,
                imageUrl: userData['imageUrl'],
              );
              return ListTile(
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.email),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return UserDetailsDialog(user: user);
                    },
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

class UserDetailsDialog extends StatelessWidget {
  final UserDto user;

  const UserDetailsDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text('${user.firstName} ${user.lastName}')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.imageUrl != null) // Check if imageUrl is available
            Center(
              child: Image.network(
                user.imageUrl!,
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Email: ${user.email}',
            style: TextStyle(fontSize: 20),
          ),
          Text(
            'Role: ${user.role}',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _markUserAsVerified(context, user.id);
            Navigator.of(context).pop();
          },
          child: Text('Verify'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }

  void _markUserAsVerified(BuildContext context, String? userId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'status': 'Verified'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User marked as verified.'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking user as verified: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
