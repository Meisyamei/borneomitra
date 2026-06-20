import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AesService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();
  static encrypt.Key? _key;
  static encrypt.IV? _iv;
  
  static Future<void> init() async {
    _key = await _getOrCreateKey();
    _iv = encrypt.IV.fromSecureRandom(16);
  }
  
  static Future<encrypt.Key> _getOrCreateKey() async {
    try {
      // Coba ambil dari secure storage dulu
      final storedKey = await _storage.read(key: AppConstants.aesKeyStorage);
      if (storedKey != null) {
        return encrypt.Key.fromBase64(storedKey);
      }
    } catch (e) {
      print('SecureStorage error: $e, using fallback');
      // Jika secure storage gagal, coba dari shared_preferences
      final fallbackKey = await _prefs.getString(AppConstants.aesKeyStorage);
      if (fallbackKey != null) {
        return encrypt.Key.fromBase64(fallbackKey);
      }
    }
    
    // Generate key baru
    final newKey = encrypt.Key.fromSecureRandom(32);
    
    try {
      // Simpan ke secure storage
      await _storage.write(key: AppConstants.aesKeyStorage, value: newKey.base64);
    } catch (e) {
      print('Failed to save to secure storage: $e, using shared_preferences');
      // Fallback ke shared_preferences
      await _prefs.setString(AppConstants.aesKeyStorage, newKey.base64);
    }
    
    return newKey;
  }
  
  static String encryptData(String plainText) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(plainText, iv: _iv!);
    return encrypted.base64;
  }
  
  static String decryptData(String cipherText) {
    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );
    final decrypted = encrypter.decrypt64(cipherText, iv: _iv!);
    return decrypted;
  }
  
  static String encryptSensitiveData(Map<String, dynamic> data) {
    return encryptData(jsonEncode(data));
  }
  
  static Map<String, dynamic> decryptSensitiveData(String cipherText) {
    final decrypted = decryptData(cipherText);
    return jsonDecode(decrypted);
  }
  
  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}