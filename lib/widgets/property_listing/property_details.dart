import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/goolgle_map/google_map_view.dart';
import 'package:rnt_spots/widgets/property_listing/edit_property.dart';

class PropertyDetails extends StatefulWidget {
  final PropertyDto property;

  const PropertyDetails({Key? key, required this.property}) : super(key: key);

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

final storage = SecureStorage();

class _PropertyDetailsState extends State<PropertyDetails> {
  bool isLandlord = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    final userRole = await storage.getFromSecureStorage("userRole");
    setState(() {
      isLandlord = userRole == "Landlord";
      isAdmin = userRole == "Admin";
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
            floatingActionButton: isLandlord
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
          return Text('Property not found');
        }
      },
    );
  }

  Widget _buildImageSlider(PropertyDto property) {
    return SizedBox(
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
    );
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
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              if (!property.verified)
                Icon(
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
    // Dummy ratings data
    final List<int> ratings = [5, 4, 3, 5, 2];

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
            const Text(
              'Reviews',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
          const SizedBox(height: 8.0),
          if (!isAdmin)
            Row(
              children: ratings.map((rating) {
                return const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 24.0,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8.0),
          // Add reviews here
        ],
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
