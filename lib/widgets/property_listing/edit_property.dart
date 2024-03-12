// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:rnt_spots/shared/error_dialog.dart';
import 'package:rnt_spots/widgets/property_listing/property_listing.dart';

class EditProperty extends StatefulWidget {
  final PropertyDto? property;
  const EditProperty({super.key, this.property});

  @override
  State<EditProperty> createState() => _EditPropertyState();
}

class _EditPropertyState extends State<EditProperty> {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<XFile> resultList = [];
  bool _isLoading = false;
  String _landlord = "";
  String _selectedStatus = 'Available';
  String _selectedBarangay = "Baliwasan";

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

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      populateFields();
      populateCarouselWithImages();
    }
  }

  void populateCarouselWithImages() {
    if (widget.property != null) {
      final PropertyDto property = widget.property!;
      List<String> imageUrls = property.imageUrls;

      // Iterate through imageUrls and load images into resultList
      for (var imageUrl in imageUrls) {
        // Convert the imageUrl to XFile and add it to the resultList
        XFile imageFile =
            XFile(imageUrl); // Assuming you're using XFile for images
        resultList.add(imageFile);
      }

      setState(() {});
    }
  }

  void populateFields() {
    final PropertyDto property = widget.property!;
    addressController.text = property.address;
    latitudeController.text = property.latitude.toString();
    longitudeController.text = property.longitude.toString();
    priceController.text = property.price.toString();
    sizeController.text = property.size.toString();
    _selectedStatus = property.status;
    _selectedBarangay = property.barangay;
    _landlord = property.landlord;
  }

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
            if (image.path.startsWith('http')) {
              // Display image from URL
              return Image.network(
                image.path,
                fit: BoxFit.cover,
              );
            } else {
              // Display image from local file
              return Image.file(
                File(image.path),
                fit: BoxFit.cover,
              );
            }
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Property"),
      ),
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
                items: const [
                  DropdownMenuItem<String>(
                    value: 'Available',
                    child: Text('Available'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Reserved',
                    child: Text('Reserved'),
                  ),
                ],
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
              TextFormField(
                controller: sizeController,
                keyboardType: TextInputType.number,
                decoration: _textFieldDecoration('Size'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Size';
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
                          'Edit Property',
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
    final landlord = _landlord;

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
          'Latitude': double.tryParse(latitudeController.text) ?? 0.0,
          'Longitude': double.tryParse(longitudeController.text) ?? 0.0,
          'Status': _selectedStatus,
          'Barangay': _selectedBarangay,
          'Email': widget.property!.email,
          'Price': double.tryParse(priceController.text) ?? 0.0,
          'Size': double.tryParse(sizeController.text) ?? 0.0,
          'Images': imageUrls,
          'Date': DateTime.now().toIso8601String(),
        };

        // Update property data in Firestore
        await FirebaseFirestore.instance
            .collection('Properties')
            .doc(widget.property!.id)
            .update(propertyData);
        Fluttertoast.showToast(msg: "Property edited successfully");
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const PropertyListing()));
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
      if (imageFile.path.startsWith('http')) {
        // If the image URL starts with 'http', it's already hosted on the web
        // Add the existing URL directly to the imageUrls list
        imageUrls.add(imageFile.path);
      } else {
        File file = File(imageFile.path);

        // Generate a unique filename for the image
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();

        // Upload the image to Firebase Storage
        firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('images/$fileName.jpg');
        firebase_storage.UploadTask uploadTask = ref.putFile(file);

        // Get download URL of the uploaded image
        String imageUrl = await (await uploadTask).ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }
    }

    return imageUrls;
  }

  // Method to delete existing images from Firebase Storage
  Future<void> _deleteExistingImages(List<String> imageUrls) async {
    final List<Future<void>> deleteTasks = [];

    for (String imageUrl in imageUrls) {
      // Extract the image filename from the URL
      final imageName = imageUrl.split('/').last.split('?').first;
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('images/$imageName');

      // Add delete task to the list
      deleteTasks.add(ref.delete());
    }

    // Wait for all delete tasks to complete
    await Future.wait(deleteTasks);
  }
}
