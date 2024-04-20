// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDto {
  final String? id;
  final String email;
  final String firstName;
  final String lastName;
  final String? password;
  final String? status;
  String? imageUrl;
  List<String>? imageUrls;
  final String role;
  final double? balance;
  final DateTime createdAt;

  UserDto(
      {required this.email,
      required this.firstName,
      required this.lastName,
      this.password,
      this.status,
      this.imageUrl,
      List<dynamic>? imageUrls,
      this.id,
      required this.role,
      double? balance,
      DateTime? createdAt})
      : balance = balance ?? 0.00,
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      'status': status,
      'role': role,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'Balance': balance,
      'CreatedAt': Timestamp.fromDate(createdAt)
    };
  }
}
