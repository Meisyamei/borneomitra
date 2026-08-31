import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ServerConfig {
  static const String _prefKey = 'server_ip';
  static String baseUrl = '';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(_prefKey);

    if (savedIp != null && savedIp.isNotEmpty) {
      baseUrl = 'http://$savedIp:80/api';
      print('✅ Server IP loaded: $baseUrl');
      return;
    }

    // 🔴 COMMENT AUTO-DETECT
    // final detected = await detectServer();
    // if (detected != null) {
    //   baseUrl = detected;
    //   await prefs.setString(_prefKey, detected.replaceAll('http://', '').replaceAll(':80/api', ''));
    //   print('✅ Server detected: $baseUrl');
    // } else {
    //   // Default fallback
    //   baseUrl = 'http://172.27.47.4:80/api';
    //   print('⚠️ Server not detected, using default: $baseUrl');
    // }

    // 🔴 PAKAI DEFAULT LANGSUNG
    baseUrl = 'http://172.27.47.4:80/api';
    print('ℹ️ Using default baseUrl: $baseUrl');
  }

  static Future<String?> detectServer() async {
    final List<String> possibleIPs = [
      '172.27.47.4',
      '172.27.48.5',
      '172.27.49.10',
      '192.168.1.100',
      '10.0.2.2',
      'localhost',
      '127.0.0.1',
    ];

    for (var ip in possibleIPs) {
      final url = 'http://$ip:80/api/anggota';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            if (data.containsKey('status') && data['status'] == 'success') {
              return 'http://$ip:80/api';
            }
          } catch (_) {}
        }
      } catch (e) {
        print('❌ Coba $ip: gagal');
      }
    }
    return null;
  }

  static Future<void> setServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, ip);
    baseUrl = 'http://$ip:80/api';
    print('✅ Server IP updated: $baseUrl');
  }

  static Future<String?> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }
}