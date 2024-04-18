import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/home/home.dart';
import 'package:rnt_spots/widgets/login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Account extends StatefulWidget {
  final VoidCallback? onRoleSwitched;
  const Account({super.key, this.onRoleSwitched});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final storage = SecureStorage();
  late Future<UserDto?> userInfoFuture;
  late Stream<DocumentSnapshot> userInfoStream;

  @override
  void initState() {
    super.initState();
    userInfoFuture = getUserInfo();
    userInfoFuture.then((user) {
      if (user != null) {
        userInfoStream = FirebaseFirestore.instance
            .collection('Users')
            .doc(user.id)
            .snapshots();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<UserDto?>(
              future: userInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return Visibility(
                    visible: userInfoStream != null,
                    child: _buildUserInfo(snapshot.data!),
                  );
                } else {
                  return const Text('No user data found.');
                }
              },
            ),
            const SizedBox(height: 20),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserDto user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userInfoStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final updatedUserDto = UserDto(
            id: user.id,
            firstName: userData['firstName'],
            lastName: userData['lastName'],
            email: userData['email'],
            role: userData['role'],
            status: userData['status'],
            imageUrl: userData['imageUrl'],
          );
          return _buildUserInfoWidget(updatedUserDto);
        } else {
          return const Text('No user data found.');
        }
      },
    );
  }

  Widget _buildUserInfoWidget(UserDto user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            'First Name: ${user.firstName}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Last Name: ${user.lastName}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Email: ${user.email}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Role: ${user.role}',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        if (user.status == 'Verified') // Check if status is Verified
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status: ${user.status}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 5),
                Icon(Icons.check_circle,
                    color: Colors.green), // Verified checkmark
              ],
            ),
          ),
        if (user.status == 'Unverified' &&
            user.role != 'Admin') // Check if status is Unverified
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status: ${user.status}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 5),
                Icon(Icons.cancel, color: Colors.red), // X icon for Unverified
              ],
            ),
          ),
        if (user.role != 'Admin') const SizedBox(height: 10),
        // if (user.role != "Admin")
        //   ElevatedButton(
        //     onPressed: () {
        //       _editRole(user);
        //     },
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.grey,
        //     ),
        //     child: const Padding(
        //       padding: EdgeInsets.all(8.0),
        //       child: Text(
        //         'Switch Role',
        //         style: TextStyle(fontSize: 18, color: Colors.white),
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _logout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          textStyle: TextStyle(fontSize: 18),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Logout',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await storage.deleteAllFromSecureStorage();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void _editRole(UserDto user) async {
    final List<String> roles = ['Tenant', 'Landlord'];
    try {
      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(user.id);
      await userRef.update(
          {'role': roles.where((element) => element != user.role).first});
      setState(() {
        userInfoFuture = getUserInfo();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated successfully')),
      );
      widget.onRoleSwitched!();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user role')),
      );
    }
  }
}
