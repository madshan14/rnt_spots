import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/shared/secure_storage.dart';
import 'package:rnt_spots/widgets/property_listing/edit_property.dart';

class PropertyDetails extends StatefulWidget {
  final PropertyDto property;

  const PropertyDetails({super.key, required this.property});

  @override
  State<PropertyDetails> createState() => _PropertyDetailsState();
}

final storage = SecureStorage();

class _PropertyDetailsState extends State<PropertyDetails> {
  bool isLandlord = false;
  @override
  void initState() {
    super.initState();
    _getUserRole();
  }

  void _getUserRole() async {
    final userRole = await storage.getFromSecureStorage("userRole");
    setState(() {
      isLandlord = userRole == "Landlord";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageSlider(),
            _buildDetails(),
            _buildViewOnMapButton(),
            _buildReviewSection(),
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
                      property: widget.property,
                    ),
                  ),
                );
              },
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              child: Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildImageSlider() {
    return Container(
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
          items: widget.property.imageUrls.map((imageUrl) {
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

  Widget _buildDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Landlord: ${widget.property.landlord}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Email: ${widget.property.email}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Size: ${widget.property.size}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Status: ${widget.property.status}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Address: ${widget.property.address}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Date: ${widget.property.date}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Price: PHP ${widget.property.price}',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    // Dummy ratings data
    final List<int> ratings = [5, 4, 3, 5, 2];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: ratings.map((rating) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
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

  Widget _buildViewOnMapButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to map
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
