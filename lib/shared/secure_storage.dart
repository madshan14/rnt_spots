import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToSecureStorage(String key, String email) async {
    await _storage.write(key: key, value: email);
  }

  Future<String> getFromSecureStorage(String key) async {
    const storage = FlutterSecureStorage();
    final email = await storage.read(key: key);
    return email.toString();
  }

  Future<void> deleteAllFromSecureStorage() async {
    await _storage.deleteAll();
  }
}
