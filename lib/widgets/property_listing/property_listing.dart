import 'dart:ffi';

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

enum FilterOption { Price, Type, Rooms, Location }

enum HomeType { House, Apartment, BoardingHouse, Dormitories }

class _PropertyListingState extends State<PropertyListing> {
  late Future<UserDto?> userInfoFuture;
  String selectedLocation = 'All'; // Track the selected location
  late FilterOption selectedFilterOption;
  HomeType? selectedHomeType = HomeType.House;
  String selectedRoom = "All";

  final List<String> locations = [
    "All",
    'Baliwasan',
    'Camino Nuevo',
    'Canelar',
    'Campo Islam',
    'Rio Hondo',
    'San Jose Cawa-cawa',
    'San Jose Gusu',
    'San Roque',
    'Santa Barbara',
    'Santa Catalina',
    'Santa Maria',
    'Santo Niño',
    'Zone I (Poblacion)',
    'Zone II (Poblacion)',
    'Zone III (Poblacion)',
    'Zone IV (Poblacion)',
    'Divisoria',
    'Guiwan',
    'Lunzuran',
    'Putik',
    'Tetuan',
    'Tugbungan',
  ];

  final List<String> rooms = ["All", "1", "2", "3", "4"];
  late TextEditingController minPriceController;
  late TextEditingController maxPriceController;
  @override
  void initState() {
    super.initState();
    userInfoFuture = getUserInfo();
    selectedFilterOption = FilterOption.Price;
    minPriceController = TextEditingController();
    maxPriceController = TextEditingController();
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
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
                  if (selectedFilterOption == FilterOption.Location)
                    DropdownButton<String>(
                      value: selectedLocation,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLocation = newValue!;
                        });
                      },
                      items: locations
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  if (selectedFilterOption == FilterOption.Rooms)
                    DropdownButton<String>(
                      value: selectedRoom,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRoom = newValue!;
                        });
                      },
                      items:
                          rooms.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  if (selectedFilterOption == FilterOption.Price)
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Min',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  if (selectedFilterOption ==
                      FilterOption.Type) // Dropdown for selecting home type
                    DropdownButton<HomeType>(
                      value: selectedHomeType,
                      onChanged: (HomeType? newValue) {
                        setState(() {
                          selectedHomeType = newValue;
                          // Reset selected location when home type is selected
                          selectedLocation = 'All';
                        });
                      },
                      items: HomeType.values
                          .map((type) => DropdownMenuItem<HomeType>(
                                value: type,
                                child: Text(type.toString().split('.').last),
                              ))
                          .toList(),
                    ),
                  Row(
                    children: [
                      const Text('Filter By: '),
                      DropdownButton<FilterOption>(
                        value: selectedFilterOption,
                        onChanged: (FilterOption? newValue) {
                          setState(() {
                            selectedFilterOption = newValue!;
                          });
                        },
                        items: FilterOption.values
                            .map((option) => DropdownMenuItem<FilterOption>(
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
                          List<PropertyDto> verifiedList = propertyList
                              .where((property) => property.verified || isAdmin)
                              .toList();

                          return _buildPropertyList(verifiedList);
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
          const SizedBox(height: 16), // Adjust the spacing as needed
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

  Widget _buildPropertyList(List<PropertyDto> propertyList) {
    final filteredList =
        _filterProperties(propertyList); // Apply filtering based on sort option
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final property = filteredList[index];
        return _buildPropertyCard(property);
      },
    );
  }

  List<PropertyDto> _filterProperties(List<PropertyDto> propertyList) {
    switch (selectedFilterOption) {
      case FilterOption.Price:
        final minPrice =
            double.tryParse(minPriceController.text) ?? double.negativeInfinity;
        final maxPrice =
            double.tryParse(maxPriceController.text) ?? double.infinity;

        // Filter by price range
        propertyList = propertyList.where((property) {
          final propertyPrice = double.tryParse(property.price) ?? 0;
          return propertyPrice >= minPrice && propertyPrice <= maxPrice;
        }).toList();
        propertyList = propertyList.toList();
        break;
      case FilterOption.Type:
        String type = selectedHomeType.toString().split('.').last;
        type = type == "BoardingHouse" ? "Boarding House" : type;
        List<PropertyDto> filteredList =
            propertyList.where((property) => (property.type == type)).toList();
        propertyList = filteredList;
        break;
      case FilterOption.Rooms:
        List<PropertyDto> filteredList = propertyList
            .where((property) =>
                (selectedRoom == 'All' || property.room == selectedRoom))
            .toList();
        propertyList = filteredList;
        break;
      case FilterOption.Location:
        List<PropertyDto> filteredList = propertyList
            .where((property) => (selectedLocation == 'All' ||
                property.barangay == selectedLocation))
            .toList();
        propertyList = filteredList;
        break;
    }
    return propertyList; // Return unfiltered list by default
  }
}
