import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/account/account.dart';
import 'package:rnt_spots/widgets/account/account_list.dart';
import 'package:rnt_spots/widgets/inbox/inbox.dart';
import 'package:rnt_spots/widgets/property_listing/property_listing.dart';
import 'package:rnt_spots/widgets/reservation/reservation.dart';

final storage = SecureStorage();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool isAdmin = false;
  String? user;
  late List<Widget> _screensAdmin;
  late List<Widget> _screensNonAdmin;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _initializeScreensAdmin();
    _initializeScreensNonAdmin();
  }

  void _getUserRole() async {
    final userRole = await storage.getFromSecureStorage("userRole");
    final email = await storage.getFromSecureStorage("email");
    setState(() {
      isAdmin = userRole == "Admin";
      user = email ?? "";
    });
  }

  void _initializeScreensAdmin() {
    _screensAdmin = [
      const PropertyListing(),
      ReservationScreen(
        reserveTo: user,
      ),
      const AccountList(),
      const Account(),
    ];
  }

  void _initializeScreensNonAdmin() {
    _screensNonAdmin = [
      const PropertyListing(),
      ReservationScreen(
        reserveBy: user,
      ),
      const Inbox(),
      const Account(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> screensToShow = isAdmin ? _screensAdmin : _screensNonAdmin;

    return Scaffold(
      body: screensToShow[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: _selectedIndex == 0 ? Colors.redAccent : Colors.grey),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspaces,
                color: _selectedIndex == 1 ? Colors.redAccent : Colors.grey),
            label: 'Reservations',
          ),
          if (!isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined,
                  color: _selectedIndex == 2 ? Colors.redAccent : Colors.grey),
              label: 'Inbox',
            ),
          if (isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.account_box,
                  color: _selectedIndex == 2 ? Colors.redAccent : Colors.grey),
              label: 'Users',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle,
                color: _selectedIndex == 3 ? Colors.redAccent : Colors.grey),
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
  final email = await storage.getFromSecureStorage("email");
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
  final id = userQuery.docs.first.id;

  await storage.saveToSecureStorage('userRole', role);

  return UserDto(
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      balance: balance,
      id: id);
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
