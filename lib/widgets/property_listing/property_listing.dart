import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/widgets/home/home.dart';
import 'package:rnt_spots/widgets/property_listing/add_property.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PropertyListing extends StatefulWidget {
  const PropertyListing({Key? key});

  @override
  State<PropertyListing> createState() => _PropertyListingState();
}

class _PropertyListingState extends State<PropertyListing> {
  late Future<UserDto?> userInfoFuture;

  @override
  void initState() {
    super.initState();
    userInfoFuture = getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PropertyDto>>(
        future: getPropertyList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return _buildPropertyCard(snapshot.data![index]);
              },
            );
          } else {
            return Center(child: Text('No properties found.'));
          }
        },
      ),
      floatingActionButton: FutureBuilder<UserDto?>(
        future: userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null ||
              snapshot.data!.role != 'Landlord') {
            // Hide the floating action button while waiting for user info
            return const SizedBox.shrink();
          } else {
            // User info is available, show the floating action button
            return FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProperty(userInfo: snapshot.data!),
                  ),
                );
              },
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            );
          }
        },
      ),
    );
  }

  Widget _buildPropertyCard(PropertyDto property) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CarouselSlider(
            options: CarouselOptions(
              aspectRatio: 16 / 9,
              autoPlay: true,
              autoPlayInterval: Duration(seconds: 3),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  property.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  property.subtitle,
                  style: const TextStyle(
                    fontSize: 14.0,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Date: ${property.date}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Price: ${property.price}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<PropertyDto>> getPropertyList() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Properties').get();
    final List<PropertyDto> propertyList = [];
    querySnapshot.docs.forEach((doc) {
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final PropertyDto property = PropertyDto.fromFirestore(data);
      propertyList.add(property);
    });
    return propertyList;
  }
}
