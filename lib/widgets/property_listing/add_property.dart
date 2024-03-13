// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
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
  final TextEditingController priceController = TextEditingController();
  final TextEditingController widthController =
      TextEditingController(); 
  final TextEditingController lengthController =
      TextEditingController();
  final TextEditingController roomController =
      TextEditingController(); 

  final _formKey = GlobalKey<FormState>();

  List<XFile> resultList = [];
  bool _isLoading = false;
  String _selectedStatus = "Available";
  String _selectedBarangay = "Baliwasan";
  String _selectedHomeType = "House";

  final List<String> homeTypes = ['House', 'Apartment', 'Boarding House', 'Dormitories']; // List of home types

  final List<String> barangays = [
    'Arena Blanco',
    'Ayala',
    'Baliwasan',
    'Baluno',
    'Boalan',
    'Bolong',
    'Buenavista',
    'Bunguiao',
    'Busay (Sacol Island)',
    'Cabaluay',
    'Cabatangan',
    'Cacao',
    'Calabasa',
    'Calarian',
    'Camino Nuevo',
    'Campo Islam',
    'Canelar',
    'Capisan',
    'Cawit',
    'Culianan',
    'Curuan',
    'Dita',
    'Divisoria',
    'Dulian (Upper Bunguiao)',
    'Dulian (Upper Pasonanca)',
    'Guisao',
    'Guiwan',
    'Kasanyangan',
    'La Paz',
    'Labuan',
    'Lamisahan',
    'Landang Gua',
    'Landang Laum',
    'Lanzones',
    'Lapakan',
    'Latuan (Curuan)',
    'Licomo',
    'Limaong',
    'Limpapa',
    'Lubigan',
    'Lumayang',
    'Lumbangan',
    'Lunzuran',
    'Maasin',
    'Malagutay',
    'Mampang',
    'Manalipa',
    'Mangusu',
    'Manicahan',
    'Mariki',
    'Mercedes',
    'Muti',
    'Pamucutan',
    'Pangapuyan',
    'Panubigan',
    'Pasilmanta (Sacol Island)',
    'Pasobolong',
    'Pasonanca',
    'Patalon',
    'Putik',
    'Quiniput',
    'Recodo',
    'Rio Hondo',
    'Salaan',
    'San Jose Cawa-cawa',
    'San Jose Gusu',
    'San Ramon',
    'San Roque',
    'Sangali',
    'Santa Barbara',
    'Santa Catalina',
    'Santa Maria',
    'Santo Niño',
    'Sibulao (Caruan)',
    'Sinubung',
    'Sinunoc',
    'Tagasilay',
    'Taguiti',
    'Talabaan',
    'Talisayan',
    'Talon-talon',
    'Taluksangay',
    'Tetuan',
    'Tictapul',
    'Tigbalabag',
    'Tigtabon',
    'Tolosa',
    'Tugbungan',
    'Tulungatung',
    'Tumaga',
    'Tumalutab',
    'Tumitus',
    'Victoria',
    'Vitali',
    'Zambowood',
    'Zone I (Poblacion)',
    'Zone II (Poblacion)',
    'Zone III (Poblacion)',
    'Zone IV (Poblacion)'
  ];

  InputDecoration _textFieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(20.0), // Set rounded border radius
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(20.0), // Set rounded border radius
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(20.0), // Set rounded border radius
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(20.0), // Set rounded border radius
      ),
    );
  }

  Widget _buildCarousel() {
    if (resultList.isEmpty) {
      return const SizedBox.shrink();
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        enableInfiniteScroll: false,
        enlargeCenterPage: true,
      ),
      items: resultList.map((XFile image) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildCarousel(),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedBarangay,
                onChanged: (newValue) {
                  setState(() {
                    _selectedBarangay = newValue!;
                  });
                },
                decoration: _textFieldDecoration('Barangay'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a Barangay';
                  }
                  return null;
                },
                items: barangays.map((barangay) {
                  return DropdownMenuItem<String>(
                    value: barangay,
                    child: Text(barangay),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                keyboardType: TextInputType.text,
                decoration: _textFieldDecoration('Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: latitudeController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Latitude'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Latitude';
                  }
                  double? latitude = double.tryParse(value);
                  if (latitude == null || latitude < -90 || latitude > 90) {
                    return 'Latitude must be between -90 and 90';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: longitudeController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Longitude'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Longitude';
                  }
                  double? latitude = double.tryParse(value);
                  if (latitude == null || latitude < -180 || latitude > 180) {
                    return 'Longitude must be between -180 and 180';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                onChanged: (newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                decoration: _textFieldDecoration('Status'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select Status';
                  }
                  return null;
                },
                items: ['Available', 'Reserved'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Price'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedHomeType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedHomeType = newValue!;
                  });
                },
                decoration: _textFieldDecoration(
                    'Home Type'), // New dropdown field for home type
                items: homeTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widthController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Width'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Width';
                  }
                  return null;
                },
              ),const SizedBox(height: 10),
              TextFormField(
                controller: lengthController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Length'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Length';
                  }
                  return null;
                },
              ),const SizedBox(height: 10),
              TextFormField(
                controller: roomController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Rooms'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Rooms';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _pickImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.white, // Set background color to white
                  foregroundColor: Colors.black, // Set text color to black
                  side: const BorderSide(
                      color: Colors.black), // Set border color to black
                  padding: const EdgeInsets.all(12.0), // Set padding
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Select Images',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Add Property',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImages() async {
    try {
      final List<XFile> pickedImages = await ImagePicker().pickMultiImage();
      resultList = pickedImages;
      setState(() {});
    } catch (e) {
      // Handle exception
    }
  }

  void _submitForm() async {
    final landlord = "${widget.userInfo.firstName} ${widget.userInfo.lastName}";
    if (_formKey.currentState!.validate()) {
      if (resultList.isEmpty) {
        Fluttertoast.showToast(msg: "Please select at least one image");

        return;
      }
      setState(() {
        _isLoading = true; // Set loading state to true when submitting
      });
      try {
        // Upload images to Firebase Storage
        final List<String> imageUrls = await _uploadImages();

        // Create property data with image URLs
        final propertyData = {
          'Landlord': landlord,
          'Address': addressController.text,
          'Room': roomController.text,
          'Latitude': double.tryParse(latitudeController.text) ?? 0.0,
          'Longitude': double.tryParse(longitudeController.text) ?? 0.0,
          'Status': _selectedStatus,
          'Barangay': _selectedBarangay,
          'Email': widget.userInfo.email,
          'Price': double.tryParse(priceController.text) ?? 0.0,
          'Width': double.tryParse(widthController.text) ?? 0.0,
          'Length': double.tryParse(lengthController.text) ?? 0.0,
          'Images': imageUrls,
          'Date': DateTime.now().toIso8601String(),
          'Type': _selectedHomeType,
          'Verified': false
        };

        // Add property data to Firestore
        await FirebaseFirestore.instance
            .collection('Properties')
            .add(propertyData);

        Fluttertoast.showToast(msg: "Property added and for verification.");

        // Clear form fields
        addressController.clear();
        latitudeController.clear();
        longitudeController.clear();
        priceController.clear();
        widthController.clear();
        lengthController.clear();
        roomController.clear();

        // Clear resultList
        resultList.clear();
      } catch (error) {
        ErrorDialog.showErrorDialog(context, "Property add error: $error");
      } finally {
        setState(() {
          _isLoading = false;
        });
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
