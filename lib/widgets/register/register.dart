// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/shared/error_dialog.dart';
import 'package:rnt_spots/widgets/login/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  List<XFile> selectedImages = [];

  final List<String> roles = ['Tenant', 'Landlord'];

  String selectedRole = 'Tenant';
  bool _showPassword = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (selectedRole == 'Landlord') {
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedImage != null) {
          _imageFile = File(pickedImage.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  void _clearFields() {
    emailController.clear();
    firstNameController.clear();
    lastNameController.clear();
    passwordController.clear();
    _imageFile = null;
    selectedImages.clear();
    setState(() {}); // Refresh the UI
  }

  Widget _buildCarousel() {
    if (selectedImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enableInfiniteScroll: false,
        enlargeCenterPage: true,
      ),
      items: selectedImages.map((XFile image) {
        return Builder(
          builder: (BuildContext context) {
            return Image.file(
              File(image.path),
              fit: BoxFit.cover,
            );
          },
        );
      }).toList(),
    );
  }

  void _pickImages() async {
    try {
      final List<XFile> pickedImages = await ImagePicker().pickMultiImage();
      selectedImages = pickedImages;
      setState(() {});
    } catch (e) {
      // Handle exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _clearFields();
          return;
        } // Clear fields when navigating back
      },
      child: Scaffold(
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
                    const SizedBox(height: 20.0),
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
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email',
                                  errorBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.redAccent))),
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
                              controller: firstNameController,
                              decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  errorBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.redAccent))),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter First Name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12.0),
                            TextFormField(
                              controller: lastNameController,
                              decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  errorBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.redAccent))),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter Last Name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12.0),

                            TextFormField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                  labelText: 'Password',
                                  errorBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.redAccent),
                                  ),
                                  suffixIcon: IconButton(
                                      icon: Icon(_showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off),
                                      onPressed: () {
                                        setState(() {
                                          _showPassword = !_showPassword;
                                        });
                                      })),
                              validator: (value) {
                                final passwordRegex = RegExp(
                                    r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()-_=+{};:,<.>]).{7,}$');

                                if (value == null || value.isEmpty) {
                                  return 'Please enter Password';
                                } else if (!passwordRegex.hasMatch(value)) {
                                  return 'Password must contain at least 1 capital letter,\n1 number,\n1 special character,\nand be at least 7 characters long';
                                }
                                return null;
                              },
                              obscureText: !_showPassword,
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
                              items: roles.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              decoration:
                                  const InputDecoration(labelText: 'Role'),
                            ),
                          ],
                        )),
                    const SizedBox(height: 8.0),
                    Container(
                        child: _imageFile == null && selectedRole == 'Landlord'
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: _pickImage,
                                    child: Text('Tap to select Valid ID'),
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16.0),
                                      primary: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                            : null),
                    const SizedBox(height: 8.0),
                    Container(
                        child: selectedImages.isEmpty &&
                                selectedRole == 'Landlord'
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: _pickImages,
                                    child: Text('Tap to Upload Documents'),
                                    style: TextButton.styleFrom(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16.0),
                                      primary:
                                          const Color.fromARGB(255, 36, 35, 35),
                                    ),
                                  ),
                                ),
                              )
                            : null),
                    if (_imageFile != null && selectedRole == 'Landlord')
                      Container(
                        width: double.infinity, // Consume available width
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          // Border radius
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  fit: BoxFit.fill,
                                )
                              : SizedBox(
                                  // Adjust height as needed
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.grey[700],
                                  ),
                                ),
                        ),
                      ),
                    const SizedBox(height: 24.0),

                    _buildCarousel(),
                    const SizedBox(height: 20),
                    // Sign-up button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _signUp();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator() // Show CircularProgressIndicator if loading
                          : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontSize: 24, color: Colors.white),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16.0),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Login()));
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
      ),
    );
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true; // Set isLoading to true when signing up starts
    });
    if (_imageFile == null && selectedRole == 'Landlord') {
      // Show error message if image is not selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a ID picture.'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false; // Reset isLoading to false
      });
      return;
    }
    if (selectedImages.isEmpty && selectedRole == 'Landlord') {
      // Show error message if images are not selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select ID pictures.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false; // Reset isLoading to false
      });
      return;
    }
    final newUser = UserDto(
      email: emailController.text,
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      password: passwordController.text,
      status: 'Unverified',
      role: selectedRole,
    );

    try {
      // Check if the email already exists in Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: newUser.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If email exists, show error message and return
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Email already exists. Please use a different email.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false; // Reset isLoading to false
        });
        return;
      }
      // Upload image to Firebase Storage
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      // Update user object with image URL
      newUser.imageUrl = imageUrl;

      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (final image in selectedImages) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(File(image.path));
        final imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      // Update user object with image URLs
      newUser.imageUrls = imageUrls;

      // Add user data to Firestore
      await firestore.collection('Users').add(newUser.toJson());

      // Show success dialog
      if (selectedRole != "Landlord") {
        Fluttertoast.showToast(msg: "Successfully Registered");
        _clearFields();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
        return;
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Successfully Registered"),
            content: const Text(
                "To be verified, kindly please wait 3 working days from the day of signing up. Thank you!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearFields();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (error) {
      ErrorDialog.showErrorDialog(context, "Registration Error: $error");
    } finally {
      setState(() {
        _isLoading =
            false; // Reset isLoading to false when sign up process is complete
      });
    }
  }
}
