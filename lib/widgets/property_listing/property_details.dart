import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/goolgle_map/google_map_view.dart';
import 'package:rnt_spots/widgets/home/home.dart';
import 'package:rnt_spots/widgets/property_listing/edit_property.dart';
import 'package:rnt_spots/widgets/ratings/add_ratings.dart';

class PropertyDetails extends StatefulWidget {
  final PropertyDto property;

  const PropertyDetails({super.key, required this.property});

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

final storage = SecureStorage();

class _PropertyDetailsState extends State<PropertyDetails> {
  bool isLandlord = false;
  bool isAdmin = false;
  bool isUser = false;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    final userRole = await storage.getFromSecureStorage("userRole");
    final userEmail = await storage.getFromSecureStorage("email");
    setState(() {
      isLandlord = userRole == "Landlord";
      isAdmin = userRole == "Admin";
      isUser = widget.property.email == userEmail;
    });
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
                  _buildImageSlider(property),
                  _buildDetails(property),
                  _buildViewOnMapButton(property),
                  _buildReviewSection(property),
                ],
              ),
            ),
            floatingActionButton: isLandlord && isUser
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
        if ( widget.property.status != 'Reserved' && !isLandlord && !isAdmin)
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
    getUserInfo().then((user) async {
      if (user != null) {
        final userInfoStream = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.id)
            .get();

        final landlordInfo = await FirebaseFirestore.instance
            .collection('Users')
            .where('email', isEqualTo: property.email)
            .get();

        final landlordId = landlordInfo.docs[0].id;
        final double landlordBalance =
            landlordInfo.docs[0].get('Balance') as double;

        final double userBalance = userInfoStream['Balance'] as double;
        final price = double.parse(property.price);
        if (userBalance < price) {
          // Display insufficient balance message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Insufficient Balance'),
                content: const Text(
                    'You have insufficient balance to reserve this property.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Reservation'),
                content: Text(
                    'Do you want to confirm the reservation for PHP ${property.price}?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      double newBalance = userBalance - price;
                      double newLandlordBalance = landlordBalance + price;

                      final propertyRef = FirebaseFirestore.instance
                          .collection('Properties')
                          .doc(property.id);
                      await propertyRef.update({'Status': 'Reserved'});

                      final userRef = FirebaseFirestore.instance
                          .collection('Users')
                          .doc(user.id);
                      await userRef.update({'Balance': newBalance});

                      final landlordRef = FirebaseFirestore.instance
                          .collection('Users')
                          .doc(landlordId);
                      await landlordRef.update({'Balance': newLandlordBalance});

                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Reservation confirmed.'),
                      ));
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              );
            },
          );
        }
      }
    });
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
            'Size: ${property.size}',
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
