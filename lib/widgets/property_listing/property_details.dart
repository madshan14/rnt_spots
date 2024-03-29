import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/goolgle_map/google_map_view.dart';
import 'package:rnt_spots/widgets/inbox/conversation.dart';
import 'package:rnt_spots/widgets/property_listing/edit_property.dart';
import 'package:rnt_spots/widgets/ratings/add_ratings.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PropertyDetails extends StatefulWidget {
  final PropertyDto property;

  const PropertyDetails({super.key, required this.property});

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

final storage = SecureStorage();

class _PropertyDetailsState extends State<PropertyDetails> {
  late String tenantName;
  bool isLandlord = false;
  bool isAdmin = false;
  bool isUser = false;
  late bool isTenant;
  String? user;

  @override
  void initState() {
    super.initState();
    _getUserRole();
    _getTenantName();
  }

  Future<void> _getTenantName() async {
    final storage = SecureStorage();
    final userEmail = await storage.getFromSecureStorage("email");

    if (userEmail != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: userEmail)
          .get();

      if (userDoc.docs.isNotEmpty) {
        setState(() {
          tenantName = userDoc.docs.first['firstName'] +
              " " +
              userDoc.docs.first['lastName'];
        });
      }
    }
  }

  void _getUserRole() async {
    final userRole = await storage.getFromSecureStorage("userRole");
    final userEmail = await storage.getFromSecureStorage("email");
    setState(() {
      isLandlord = userRole == "Landlord";
      isAdmin = userRole == "Admin";
      isUser = widget.property.email == userEmail;
      isTenant = userRole == "Tenant";
      user = userEmail ?? "";
    });
  }

  Future<void> _createNewMessage(BuildContext context, String landlord,
      String landlordName, String tenantName) async {
    final conversationQuery = await FirebaseFirestore.instance
        .collection('GroupMessages')
        .where('members', arrayContainsAny: [user, landlord]).get();

    if (conversationQuery.docs.isNotEmpty) {
      // If conversation exists, navigate to the existing conversation
      final conversationId = conversationQuery.docs.first.id;
      Navigator.pop(context); // Close the new message screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(groupId: conversationId),
        ),
      );
    } else {
      // If conversation does not exist, create a new conversation
      final groupRef =
          await FirebaseFirestore.instance.collection('GroupMessages').add({
        'members': [user, landlord],
        'names': [tenantName, landlordName]
      });

      // Navigate to the screen to create a new message
      Navigator.pop(context); // Close the new message screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(groupId: groupRef.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Properties')
          .doc(widget.property.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.exists) {
          final property = PropertyDto.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>,
            snapshot.data!.id,
          );
          return Scaffold(
            appBar: AppBar(
              title: const Text('Property Details'),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Hero(
                    tag: 'property_image_${widget.property.id}',
                    child: _buildImageSlider(widget.property),
                  ),
                  _buildDetails(property),
                  _buildViewOnMapButton(property),
                  _buildReviewSection(property),
                ],
              ),
            ),
            floatingActionButton: isTenant && user != widget.property.email
                ? FloatingActionButton(
                    onPressed: () {
                      _createNewMessage(context, widget.property.email,
                          widget.property.landlord, tenantName);
                    },
                    child: const Icon(Icons.message),
                  )
                : isLandlord && isUser
                    ? FloatingActionButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProperty(
                                property: property,
                              ),
                            ),
                          );
                        },
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.edit),
                      )
                    : null,
          );
        } else {
          return const Text('Property not found');
        }
      },
    );
  }

  Widget _buildImageSlider(PropertyDto property) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CarouselSlider(
              options: CarouselOptions(
                aspectRatio: 16 / 9,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
              ),
              items: property.imageUrls.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ),
        if (widget.property.status != 'Reserved' && !isLandlord && !isAdmin)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _confirmReservation(context, property);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                'Reserve',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmReservation(
      BuildContext context, PropertyDto property) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      String? paymentMethod;
      File? receiptImage;
      bool uploading = false;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Payment Method'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: ['GCASH', 'Palawan', 'MLhullier', 'Cebuana', 'Cash']
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        paymentMethod = value;
                      });
                    },
                  ),
                  if (paymentMethod != null &&
                      paymentMethod !=
                          'Cash') // Check if payment method is not cash
                    SizedBox(height: 16),
                  if (paymentMethod != null &&
                      paymentMethod !=
                          'Cash') // Check if payment method is not cash
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile =
                            await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          receiptImage = File(pickedFile.path);
                        }
                      },
                      child: Text('Upload Receipt Image'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: uploading
                      ? null
                      : () async {
                          if (paymentMethod != 'Cash' && receiptImage == null) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Please upload receipt.'),
                            ));
                            return;
                          }
                          if (paymentMethod != null) {
                            setState(() {
                              uploading = true;
                            });

                            // Save reservation with payment method and receipt image if applicable
                            final reservationData = {
                              'propertyId': property.id,
                              'reservedBy': user,
                              'reservedTo': widget.property.email,
                              'reservationDate': selectedDate,
                              'paymentMethod': paymentMethod,
                              'status': "Pending"
                            };

                            if (receiptImage != null) {
                              // Upload receipt image to storage (replace 'receipts' with your storage path)
                              final storageRef = FirebaseStorage.instance
                                  .ref()
                                  .child('receipts')
                                  .child(
                                      '${DateTime.now().millisecondsSinceEpoch}.jpg');
                              final uploadTask =
                                  storageRef.putFile(receiptImage!);
                              final TaskSnapshot taskSnapshot =
                                  await uploadTask.whenComplete(() => null);
                              final String downloadUrl =
                                  await taskSnapshot.ref.getDownloadURL();
                              reservationData['receiptUrl'] = downloadUrl;
                            }

                            // Save reservation data to Firestore
                            await FirebaseFirestore.instance
                                .collection('Reservations')
                                .add(reservationData);

                            // Show confirmation message
                            Navigator.pop(context); // Close the dialog
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Reservation confirmed.'),
                            ));
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Please select a payment method.'),
                            ));
                          }
                        },
                  child: uploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Confirm'),
                ),
              ],
            );
          },
        ),
      );
    } else {
      // User canceled reservation
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Reservation canceled.'),
      ));
    }
  }

  Widget _buildDetails(PropertyDto property) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Landlord: ${property.landlord}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              if (property.verified)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              if (!property.verified)
                const Icon(
                  Icons.warning,
                  color: Colors.red,
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'Email: ${property.email}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Width: ${property.width}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Length: ${property.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Status: ${property.status}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Home Type: ${property.type}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Rooms: ${property.room}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Address: ${property.address}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Barangay: ${property.barangay}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Date: ${property.date}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Price: PHP ${property.price}',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(PropertyDto property) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAdmin && !property.verified)
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  // Update property verification
                  await FirebaseFirestore.instance
                      .collection('Properties')
                      .doc(property.id)
                      .update({"Verified": true});

                  Fluttertoast.showToast(msg: "Property Verified");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Verify Listing',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (!isAdmin)
            Row(
              children: [
                const Text(
                  'Reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                const Spacer(),
                if (!isAdmin && !isLandlord)
                  ElevatedButton(
                    onPressed: () {
                      _navigateToAddRating(context, property.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Add Review',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8.0),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Ratings')
                .where('propertyId', isEqualTo: property.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No reviews yet');
              }
              final List<double> ratings = snapshot.data!.docs
                  .map((doc) => doc['rating'] as double)
                  .toList();
              final double averageRating =
                  ratings.reduce((value, element) => value + element) /
                      ratings.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RatingBar.builder(
                    initialRating: averageRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      //print(rating);
                    },
                  ),
                  const SizedBox(height: 8.0),
                  const Divider(),
                  const SizedBox(height: 8.0),
                  // Display individual reviews
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data!.docs.map((doc) {
                      final double rating = doc['rating'] as double;
                      final String comment = doc['comment'] as String;
                      final Timestamp timestamp = doc['timestamp'] as Timestamp;
                      final DateTime dateTime = timestamp.toDate();
                      final formattedDate =
                          DateFormat.yMMMMd().format(dateTime);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Rating: $rating',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(comment),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _navigateToAddRating(BuildContext context, String propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRating(propertyId: propertyId),
      ),
    );
  }

  Widget _buildViewOnMapButton(PropertyDto property) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoogleMapView(
                latitude: property.latitude,
                longitude: property.longitude,
                label: property.landlord,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
        ),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'View on Map',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
