import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/widgets/property_listing/property_details.dart';

class UnverifiedProperties extends StatelessWidget {
  final UserDto user;

  const UnverifiedProperties({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unverified Properties'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Properties')
            .where('Email', isEqualTo: user.email)
            .where('Verified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final List<PropertyDto> unverifiedProperties =
                snapshot.data!.docs.map((doc) {
              final Map<String, dynamic> data =
                  doc.data() as Map<String, dynamic>;
              return PropertyDto.fromFirestore(data, doc.id);
            }).toList();

            return ListView.builder(
              itemCount: unverifiedProperties.length,
              itemBuilder: (context, index) {
                final property = unverifiedProperties[index];
                return _buildPropertyCard(context, property);
              },
            );
          } else {
            return const Center(child: Text('No unverified properties found.'));
          }
        },
      ),
    );
  }

  Widget _buildPropertyCard(context, PropertyDto property) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetails(property: property),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.all(8.0),
        elevation: 0,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.black,
                    width: 2), // Adding border to the image
              ),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CarouselSlider(
                    options: CarouselOptions(
                      aspectRatio: 16 / 12,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      enlargeCenterPage: true,
                    ),
                    items: property.imageUrls.map((imageUrl) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Image.network(
                            imageUrl,
                            fit: BoxFit.fill,
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                if (property.verified)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(
                      Icons.verified,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    property.landlord,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    property.address,
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  Text(
                    property.date,
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  Text(
                    'PHP ${property.price}',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
