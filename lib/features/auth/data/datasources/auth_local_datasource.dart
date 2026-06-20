import 'package:shared_preferences/shared_preferences.dart';
import 'package:Koperasi/core/services/database_service.dart';

class AuthLocalDataSource {
  final DatabaseService dbService;
  final SharedPreferences prefs;
  
  AuthLocalDataSource(this.dbService, this.prefs);
  
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentAdminIdKey = 'current_admin_id';
  
  Future<Map<String, dynamic>?> getAdminByUsername(String username) async {
    final result = await dbService.query(
      'admin',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }
  
  Future<Map<String, dynamic>?> getAdminById(int id) async {
    return await dbService.getById('admin', id);
  }
  
  Future<void> updatePassword(int adminId, String newHashedPassword) async {
    await dbService.update('admin', adminId, {
      'password_hash': newHashedPassword,
    });
  }
  
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }
  
  Future<bool> getLoginStatus() async {
    return prefs.getBool(_isLoggedInKey) ?? false;
  }
  
  Future<void> saveCurrentAdmin(int adminId) async {
    await prefs.setInt(_currentAdminIdKey, adminId);
  }
  
  Future<int?> getCurrentAdmin() async {
    return prefs.getInt(_currentAdminIdKey);
  }
  
  Future<void> clearCurrentAdmin() async {
    await prefs.remove(_currentAdminIdKey);
  }
}