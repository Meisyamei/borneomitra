import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Koperasi/core/services/database_service.dart';
import '../../domain/entities/profile.dart';

class ProfileLocalDataSource {
  static const String _profileKey = 'user_profile';

  final DatabaseService dbService;

  ProfileLocalDataSource(this.dbService);

  Future<Database> get _db async => await dbService.database;

  // ===== SAVE PROFILE =====
  Future<void> saveProfile(Profile profile) async {
    final db = await _db;
    
    // Cek apakah sudah ada
    final existing = await db.query('profile');
    
    if (existing.isEmpty) {
      // Insert baru
      await db.insert('profile', {
        'nama': profile.nama,
        'email': profile.email,
        'foto_path': profile.fotoPath,
      });
    } else {
      // Update existing
      await db.update(
        'profile',
        {
          'nama': profile.nama,
          'email': profile.email,
          'foto_path': profile.fotoPath,
        },
        where: 'id = ?',
        whereArgs: [1],
      );
    }

    // Juga simpan ke SharedPreferences untuk akses cepat
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(profile.toMap());
    await prefs.setString(_profileKey, json);
  }

  // ===== GET PROFILE =====
  Future<Profile> getProfile() async {
    final db = await _db;
    final result = await db.query('profile');
    
    if (result.isEmpty) {
      // Profile default
      return Profile(
        nama: 'Administrator',
        email: 'admin@bms.com',
        fotoPath: null,
      );
    }
    
    return Profile.fromMap(result.first);
  }

  // ===== SAVE FOTO =====
  Future<String?> saveFoto(File imageFile) async {
    try {
      // 1. Dapatkan direktori aplikasi
      final appDir = await getApplicationDocumentsDirectory();
      
      // 2. Buat folder 'profile' jika belum ada
      final profileDir = Directory('${appDir.path}/profile');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      
      // 3. Generate nama file unik
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${profileDir.path}/$fileName';
      
      // 4. Copy file ke direktori aplikasi
      final savedFile = await imageFile.copy(filePath);
      
      // 5. Hapus file lama jika ada (opsional)
      final currentProfile = await getProfile();
      if (currentProfile.fotoPath != null && currentProfile.fotoPath!.isNotEmpty) {
        final oldFile = File(currentProfile.fotoPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
      
      return savedFile.path;
    } catch (e) {
      print('❌ Error saving foto: $e');
      return null;
    }
  }

  // ===== DELETE FOTO =====
  Future<void> deleteFoto(String? fotoPath) async {
    if (fotoPath != null && fotoPath.isNotEmpty) {
      try {
        final file = File(fotoPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('⚠️ Error deleting foto: $e');
      }
    }
  }
}