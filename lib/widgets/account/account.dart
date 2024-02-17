// ignore_for_file: use_build_context_synchronously

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<UserDto?>(
              future: userInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return _buildUserInfo(snapshot.data!);
                } else {
                  return const Text('No user data found.');
                }
              },
            ),
            const SizedBox(height: 40),
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
          'First Name: ${user.firstName}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          'Last Name: ${user.lastName}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          'Email: ${user.email}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          'Role: ${user.role}',
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),
        if (user.role != 'Admin')
          Text(
            'Balance: PHP ${user.balance}',
            style: const TextStyle(fontSize: 18),
          ),
        if (user.role != 'Admin') const SizedBox(height: 10),
        if (user.role != "Admin")
          ElevatedButton(
            onPressed: () {
              _editRole(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
            ),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Switch Role',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
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
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Logout',
            style: TextStyle(fontSize: 18, color: Colors.white),
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
    // Update user role in Firestore
    try {
      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(user.id);
      await userRef.update(
          {'role': roles.where((element) => element != user.role).first});
      setState(() {
        // Reload user information after updating role
        userInfoFuture = getUserInfo();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role updated successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user role')),
      );
    }
  }
}
