import 'package:flutter/material.dart';
import 'package:rnt_spots/widgets/login/login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final List<String> roles = ['Tenant', 'Landlord'];

  String selectedRole = 'Tenant';
  // Default role
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(top: 30),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Center(
                    child: Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Subtext
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Please sign up to continue',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Form fields for sign-up
                  Form(
                      child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Email',
                            errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.redAccent))),
                        validator: (value) {
                          // Regular expression for email validation
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email address';
                          } else if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'First Name'),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Last Name'),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12.0),
                      // Selector for role field
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedRole = newValue!;
                          });
                        },
                        items: roles.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: const InputDecoration(labelText: 'Role'),
                      ),
                    ],
                  )),
          
                  const SizedBox(height: 24.0),
                  // Sign-up button
                  ElevatedButton(
                    onPressed: () {
                      // Implement your sign-up logic here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const Login()));
                    },
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
