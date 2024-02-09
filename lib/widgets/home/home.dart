import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/property_listing/property_listing.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PropertyListing(),
    const PlaceholderWidget(text: 'Screen 2'),
    const PlaceholderWidget(text: 'Screen 3'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

Future<UserDto?> getUserInfo() async {
  final storage = SecureStorage();
  final email = await storage.getFromSecureStorage();
  final userQuery = await FirebaseFirestore.instance
      .collection('Users')
      .where('email', isEqualTo: email)
      .get();

  if (userQuery.docs.isEmpty) {
    return null;
  }

  final userData =
      userQuery.docs.first.data(); // Extract user data from the first document
  final firstName = userData['firstName'];
  final lastName = userData['lastName'];
  final role = userData['role'];
  final balance = userData['balance'];

  return UserDto(
      email: email ?? "",
      firstName: firstName,
      lastName: lastName,
      role: role,
      balance: balance);
}

class PlaceholderWidget extends StatelessWidget {
  final String text;

  const PlaceholderWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text),
    );
  }
}
