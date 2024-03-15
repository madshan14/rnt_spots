import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rnt_spots/dtos/property_dto.dart';
import 'package:rnt_spots/dtos/users_dto.dart';
import 'package:rnt_spots/widgets/home/home.dart';
import 'package:rnt_spots/widgets/property_listing/add_property.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:rnt_spots/widgets/property_listing/property_details.dart';
import 'package:rnt_spots/widgets/property_listing/unverified_listing.dart';

class PropertyListing extends StatefulWidget {
  const PropertyListing({super.key});

  @override
  State<PropertyListing> createState() => _PropertyListingState();
}

enum SortOption { Price, Type, Rooms, Location }

class _PropertyListingState extends State<PropertyListing> {
  late Future<UserDto?> userInfoFuture;
  String selectedLocation = 'All'; // Track the selected location
  late SortOption selectedSortOption;

  final List<String> locations = [
    "All",
    'Baliwasan',
    'Tetuan',
    'San Jose',
    'Sta Catalina',
    'Mampang',
    'Talon-Talon'
  ];

  @override
  void initState() {
    super.initState();
    userInfoFuture = getUserInfo();
    selectedSortOption = SortOption.Price;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: selectedLocation,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedLocation = newValue!;
                      });
                    },
                    items:
                        locations.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  Row(
                    children: [
                      const Text('Sort By: '),
                      DropdownButton<SortOption>(
                        value: selectedSortOption,
                        onChanged: (SortOption? newValue) {
                          setState(() {
                            selectedSortOption = newValue!;
                          });
                        },
                        items: SortOption.values
                            .map((option) => DropdownMenuItem<SortOption>(
                                  value: option,
                                  child:
                                      Text(option.toString().split('.').last),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Properties')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData &&
                      snapshot.data!.docs.isNotEmpty) {
                    final List<PropertyDto> propertyList =
                        snapshot.data!.docs.map((doc) {
                      final Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      return PropertyDto.fromFirestore(data, doc.id);
                    }).toList();

                    // Filter the property list based on user role
                    return FutureBuilder<UserDto?>(
                      future: userInfoFuture,
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (userSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${userSnapshot.error}'));
                        } else {
                          final isAdmin = userSnapshot.data?.role == 'Admin';
                          final filteredList = propertyList.where((property) =>
                              (selectedLocation == 'All' ||
                                  property.barangay == selectedLocation) &&
                              (property.verified || isAdmin));

                          return ListView.builder(
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final property = filteredList.elementAt(index);
                              return _buildPropertyCard(property);
                            },
                          );
                        }
                      },
                    );
                  } else {
                    return const Center(child: Text('No properties found.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FutureBuilder<UserDto?>(
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
                        builder: (context) =>
                            AddProperty(userInfo: snapshot.data!),
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
          SizedBox(height: 16), // Adjust the spacing as needed
          FutureBuilder<UserDto?>(
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
                        builder: (context) =>
                            UnverifiedProperties(user: snapshot.data!),
                      ),
                    );
                  },
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.home_filled),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyDto property) {
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
