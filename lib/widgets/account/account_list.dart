import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:rnt_spots/widgets/property_listing/unverified_listing.dart';

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
                  (doc.data() as Map<String, dynamic>)['role'] == 'Landlord')
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
                imageUrls: userData['imageUrls'],
                status: userData['status'],
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: user.status == 'Verified'
                        ? Colors.white
                        : Color.fromARGB(146, 248, 96,
                            96), // Choose your desired background color
                    borderRadius: BorderRadius.circular(
                        10), // Optional: Add border radius for rounded corners
                  ),
                  child: ListTile(
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
                  ),
                ),
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

  Widget _populateCarouselWithImages() {
    List<Widget> carouselItems = [];
    List<String>? imageUrls = user.imageUrls;

    if (imageUrls != null && imageUrls.isNotEmpty) {
      for (var imageUrl in imageUrls) {
        carouselItems.add(
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enableInfiniteScroll: false,
        enlargeCenterPage: true,
      ),
      items: carouselItems,
    );
  }

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
          _populateCarouselWithImages(),
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
            _markUserAsRejected(context, user.id);
            Navigator.of(context).pop();
          },
          child: Text('Reject'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnverifiedProperties(user: user),
              ),
            );
          },
          child: Text('Listings'),
        ),
      ],
    );
  }

  void _markUserAsVerified(BuildContext context, String? userId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'status': 'Verified'}).then((_) {
      Fluttertoast.showToast(msg: "User marked as verified.");
    }).catchError((error) {
      Fluttertoast.showToast(msg: 'Error marking user as verified: $error');
    });
  }

  void _markUserAsRejected(BuildContext context, String? userId) {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .update({'status': 'Unverified'}).then((_) {
      Fluttertoast.showToast(msg: "User marked as unverified.");
    }).catchError((error) {
      Fluttertoast.showToast(msg: 'Error marking user as unverified: $error');
    });
  }
}
