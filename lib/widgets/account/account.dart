import 'package:flutter/material.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/home/home.dart';
import 'package:rnt_spots/widgets/login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  final storage = SecureStorage();
  late Future<UserDto?> userInfoFuture;

  @override
  void initState() {
    super.initState();
    userInfoFuture = getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserDto?>(
              future: userInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return _buildUserInfo(snapshot.data!);
                } else {
                  return Text('No user data found.');
                }
              },
            ),
            SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(UserDto user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username: ${user.firstName} ${user.lastName}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          'Email: ${user.email}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          'Role: ${user.role}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          'Balance: PHP ${user.balance}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          'Created At: ${user.createdAt}',
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _editRole(user);
          },
          child: Text('Edit Role'),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () {
        _logout();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          'Logout',
          style: TextStyle(fontSize: 18),
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
    // Update user role in Firestore
    try {
      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(user.id);
      await userRef.update({'role': 'Tenant'});
      setState(() {
        // Reload user information after updating role
        userInfoFuture = getUserInfo();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user role')),
      );
    }
  }
}
