import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _key = 'email';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToSecureStorage(String email) async {
    await _storage.write(key: _key, value: email);
  }

  Future<String?> getFromSecureStorage() async {
    const storage = FlutterSecureStorage();
    final email = await storage.read(key: 'email');
    return email.toString();
  }
}
