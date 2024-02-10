class PropertyDto {
  final List<String> imageUrls;
  final String landlord;
  final String address;
  final String date;
  final String price;
  final String email;
  final String size;
  final double latitude;
  final double longitude;
  final String status;
  final String id;

  PropertyDto({
    required this.imageUrls,
    required this.landlord,
    required this.address,
    required this.date,
    required this.price,
    required this.size,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.id,
  });

  factory PropertyDto.fromFirestore(Map<String, dynamic> data, String docId) {
    // Assuming 'Images' field in Firestore contains a list of image URLs
    List<String> imageUrls = List<String>.from(data['Images'] ?? []);

    // Ensure that numeric fields are converted to strings
    String landlord = data['Landlord']?.toString() ?? '';
    String address = data['Address']?.toString() ?? '';
    String date = data['Date']?.toString() ?? '';
    String price = data['Price']?.toString() ?? '';
    String email = data['Email']?.toString() ?? '';
    String status = data['Status']?.toString() ?? '';
    String size = data['Size']?.toString() ?? '';
    double latitude = data['Latitude'];
    double longitude = data['Longitude'];

    return PropertyDto(
      imageUrls: imageUrls,
      landlord: landlord,
      address: address,
      date: date,
      price: price,
      size: size,
      email: email,
      latitude: latitude,
      longitude: longitude,
      status: status,
      id: docId
    );
  }
}
