import 'package:Koperasi/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalDataSource {
  final DatabaseService dbService;
  final SharedPreferences prefs;

  AuthLocalDataSource(this.dbService, this.prefs);

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentAdminIdKey = 'current_admin_id';

  // ===== GET ADMIN BY USERNAME =====
  Future<Map<String, dynamic>?> getAdminByUsername(String username) async {
    final db = await dbService.database;
    final result = await db.query(
      'admin',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ===== GET ADMIN BY ID =====
  Future<Map<String, dynamic>?> getAdminById(int id) async {
    final db = await dbService.database;
    final result = await db.query(
      'admin',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ===== UPDATE PASSWORD =====
  Future<void> updatePassword(int adminId, String newHashedPassword) async {
    final db = await dbService.database;
    await db.update(
      'admin',
      {'password_hash': newHashedPassword},
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  // ===== UPDATE USERNAME =====
  Future<void> updateUsername(int adminId, String newUsername) async {
    final db = await dbService.database;
    await db.update(
      'admin',
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [adminId],
    );
  }

  // ===== SAVE LOGIN STATUS =====
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // ===== GET LOGIN STATUS =====
  Future<bool> getLoginStatus() async {
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // ===== SAVE CURRENT ADMIN =====
  Future<void> saveCurrentAdmin(int adminId) async {
    await prefs.setInt(_currentAdminIdKey, adminId);
  }

  // ===== GET CURRENT ADMIN =====
  Future<int?> getCurrentAdmin() async {
    return prefs.getInt(_currentAdminIdKey);
  }

  // ===== CLEAR CURRENT ADMIN =====
  Future<void> clearCurrentAdmin() async {
    await prefs.remove(_currentAdminIdKey);
  }
}