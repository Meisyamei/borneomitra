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
  
  
  static Future<void> init() async {
    _key = await _getOrCreateKey();
  }
  
  static Future<encrypt.Key> _getOrCreateKey() async {
    try {
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
  
  // static String encryptData(String plainText) {
  //   final encrypter = encrypt.Encrypter(
  //     encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
  //   );
  //   final encrypted = encrypter.encrypt(plainText, iv: _iv!);
  //   return encrypted.base64;
  // }

  static String encryptData(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );

    final encrypted = encrypter.encrypt(
      plainText,
      iv: iv,
    );

    return "${iv.base64}:${encrypted.base64}";
  }
  
  // static String decryptData(String cipherText) {
  //   final encrypter = encrypt.Encrypter(
  //     encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
  //   );
  //   final decrypted = encrypter.decrypt64(cipherText, iv: _iv!);
  //   return decrypted;
  // }
  static String decryptData(String cipherText) {
    final parts = cipherText.split(":");

    if (parts.length != 2) {
      throw Exception("Invalid encrypted data");
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final cipher = parts[1];

    final encrypter = encrypt.Encrypter(
      encrypt.AES(_key!, mode: encrypt.AESMode.cbc),
    );

    return encrypter.decrypt64(
      cipher,
      iv: iv,
    );
  }
  
    static String encryptSensitiveData(Map<String, dynamic> data) {
    return encryptData(jsonEncode(data));
  }
  // static Map<String, dynamic> decryptSensitiveData(String cipherText) {
  //   final decrypted = decryptData(cipherText);
  //   return jsonDecode(decrypted);
  // }
  //cari masalah aes dlu 
  static Map<String, dynamic> decryptSensitiveData(String cipherText) {
    try {
      final decrypted = decryptData(cipherText);

      print("========== HASIL AES ==========");
      print(decrypted);
      print("===============================");

      return jsonDecode(decrypted);
    } catch (e, stack) {
      print("========== AES ERROR ==========");
      print(e);
      print(stack);
      print("===============================");

      rethrow;
    }
  }

  static String generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}