
class PropertyDto {
  final List<String> imageUrls;
  final String title;
  final String subtitle;
  final String date;
  final String price;

  PropertyDto({
    required this.imageUrls,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.price,
  });

  factory PropertyDto.fromFirestore(Map<String, dynamic> data) {
    // Assuming 'Images' field in Firestore contains a list of image URLs
    List<String> imageUrls = List<String>.from(data['Images'] ?? []);

    // Ensure that numeric fields are converted to strings
    String title = data['Title']?.toString() ?? '';
    String subtitle = data['Subtitle']?.toString() ?? '';
    String date = data['Date']?.toString() ?? '';
    String price = data['Price']?.toString() ?? '';

    return PropertyDto(
      imageUrls: imageUrls,
      title: title,
      subtitle: subtitle,
      date: date,
      price: price,
    );
  }
}
