import 'package:intl/intl.dart';

class PropertyDto {
  final List<String> imageUrls;
  final String landlord;
  final String name;
  final String address;
  final String date;
  final String price;
  final String email;
  final String width;
  final String room;
  final String roomCapacity;
  final String length;
  final double latitude;
  final double longitude;
  final bool verified;
  final String status;
  final String type;
  final String barangay;
  final String notes;
  final String id;

  PropertyDto({
    required this.imageUrls,
    required this.landlord,
    required this.name,
    required this.address,
    required this.date,
    required this.price,
    required this.room,
    required this.roomCapacity,
    required this.width,
    required this.length,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.verified,
    required this.status,
    required this.type,
    required this.barangay,
    required this.notes,
    required this.id,
  });

  factory PropertyDto.fromFirestore(Map<String, dynamic> data, String docId) {
    // Assuming 'Images' field in Firestore contains a list of image URLs
    List<String> imageUrls = List<String>.from(data['Images'] ?? []);

    // Ensure that numeric fields are converted to strings
    String landlord = data['Landlord']?.toString() ?? '';
    String name = data['Name']?.toString() ?? '';
    String notes = data['Notes']?.toString() ?? '';
    String address = data['Address']?.toString() ?? '';
    String date = data['Date']?.toString() ?? '';
    String price = data['Price']?.toString() ?? '';
    String email = data['Email']?.toString() ?? '';
    String status = data['Status']?.toString() ?? '';
    String type = data['Type']?.toString() ?? '';
    String barangay = data['Barangay']?.toString() ?? '';
    String width = data['Width']?.toString() ?? '';
    String length = data['Length']?.toString() ?? '';
    String room = data['Room']?.toString() ?? '';
    String roomCapacity = data['RoomCapacity']?.toString() ?? '';
    bool verified = data['Verified'];
    double latitude = data['Latitude'];
    double longitude = data['Longitude'];
    // Parse the date string to DateTime
    DateTime parsedDate = DateTime.tryParse(date) ?? DateTime.now();

    // Format the date as "February 14, 1999"
    String formattedDate = DateFormat('MMMM dd, yyyy').format(parsedDate);

    return PropertyDto(
        imageUrls: imageUrls,
        landlord: landlord,
        name: name,
        notes: notes,
        address: address,
        date: formattedDate,
        price: price,
        width: width,
        length: length,
        email: email,
        room: room,
        roomCapacity: roomCapacity,
        latitude: latitude,
        longitude: longitude,
        verified: verified,
        status: status,
        type: type,
        barangay: barangay,
        id: docId);
  }
}
