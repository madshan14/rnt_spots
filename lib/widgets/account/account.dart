import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
                  return Visibility(
                    visible: userInfoStream != null,
                    child: _buildUserInfo(snapshot.data!),
                  );
                } else {
                  return const Text('No user data found.');
                }
              },
            ),
            const SizedBox(height: 40),
            _buildAddBalanceButton(),
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
            balance: userData['Balance'] ?? user.balance,
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

  Widget _buildAddBalanceButton() {
    return ElevatedButton(
      onPressed: () {
        _showAddBalanceModal();
      },
      child: const Text('Add Balance'),
    );
  }

  void _showAddBalanceModal() {
    TextEditingController amountController = TextEditingController();
    String selectedPaymentMethod = 'GCASH'; // Default value
    bool amountError = false; // Track if there is an amount error
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Balance',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  errorText: amountError
                      ? 'Amount must be greater than 0'
                      : null, // Error text if amount is invalid
                  errorStyle: TextStyle(color: Colors.red), // Error text style
                ),
                keyboardType: TextInputType.numberWithOptions(
                    decimal: true), // Allow decimal input
                onChanged: (_) {
                  setState(() {
                    amountError = false;
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedPaymentMethod,
                onChanged: (String? value) {
                  setState(() {
                    selectedPaymentMethod = value!;
                  });
                },
                items: ['GCASH', 'MAYA', 'CREDIT CARD'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Payment Method',
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty ||
                      double.parse(amountController.text) < 0) {
                    setState(() {
                      amountError = true;
                    });
                    Fluttertoast.showToast(
                        msg: 'Amount must be greater than 0');
                  } else {
                    setState(() {
                      amountError = true;
                    });
                    _addBalance(amountController.text, selectedPaymentMethod);
                    amountController.clear();
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addBalance(String amount, String paymentMethod) async {
    try {
      UserDto? user = await userInfoFuture;
      double newBalance = double.parse(amount) + (user!.balance ?? 0.0);

      // Retrieve existing balance from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .get();
      final existingBalance = userDoc.get('Balance') ?? 0.0;

      // Add the new balance to the existing balance
      newBalance += existingBalance;

      final userRef =
          FirebaseFirestore.instance.collection('Users').doc(user.id);
      await userRef.update({'Balance': newBalance});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Balance added successfully')),
      );
      setState(() {
        userInfoFuture = getUserInfo(); // Reload user information
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add balance: $error')),
      );
    }
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
        SnackBar(content: Text('Failed to update user role')),
      );
    }
  }
}
