import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:rnt_spots/shared/error_dialog.dart';

class AddProperty extends StatefulWidget {
  final UserDto userInfo;
  const AddProperty({super.key, required this.userInfo});

  @override
  State<AddProperty> createState() => _AddPropertyState();
}

class _AddPropertyState extends State<AddProperty> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<XFile> resultList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Address', addressController),
              _buildTextField('Latitude', latitudeController,
                  keyboardType: TextInputType.number),
              _buildTextField('Longitude', longitudeController,
                  keyboardType: TextInputType.number),
              _buildTextField('Status', statusController),
              _buildTextField('Price', priceController,
                  keyboardType: TextInputType.number),
              _buildTextField('Size', sizeController,
                  keyboardType: TextInputType.number),
              ElevatedButton(
                onPressed: _pickImages,
                child: const Text('Select Images'),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Property'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  void _pickImages() async {
    try {
      final List<XFile>? pickedImages = await ImagePicker().pickMultiImage();
      if (pickedImages != null) {
        resultList = pickedImages;
        setState(() {});
      }
    } catch (e) {
      // Handle exception
    }
  }

  void _submitForm() async {
    final landlord = "${widget.userInfo.firstName} ${widget.userInfo.lastName}";
    if (_formKey.currentState!.validate()) {
      try {
        // Upload images to Firebase Storage
        final List<String> imageUrls = await _uploadImages();

        // Create property data with image URLs
        final propertyData = {
          'Landlord': landlord,
          'Address': addressController.text,
          'Latitude': double.tryParse(latitudeController.text) ?? 0.0,
          'Longitude': double.tryParse(longitudeController.text) ?? 0.0,
          'Status': statusController.text,
          'Email': widget.userInfo.email,
          'Price': double.tryParse(priceController.text) ?? 0.0,
          'Size': double.tryParse(sizeController.text) ?? 0.0,
          'Images': imageUrls,
          'Date': DateTime.now().toIso8601String(),
        };

        // Add property data to Firestore
        await FirebaseFirestore.instance
            .collection('Properties')
            .add(propertyData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully')),
        );
        _formKey.currentState!.reset();
      } catch (error) {
        ErrorDialog.showErrorDialog(context, "Property add error: $error");
      }
    }
  }

  // Method to upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];

    for (XFile imageFile in resultList) {
      File file = File(imageFile.path);

      // Generate a unique filename for the image
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload the image to Firebase Storage
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/$fileName.jpg');
      firebase_storage.UploadTask uploadTask = ref.putFile(file);

      // Get download URL of the uploaded image
      String imageUrl = await (await uploadTask).ref.getDownloadURL();
      imageUrls.add(imageUrl);
    }

    return imageUrls;
  }
}
