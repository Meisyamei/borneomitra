import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/hash_service.dart';
import '../../domain/entities/admin.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, Admin>> login(String username, String password) async {
    try {
      final admin = await localDataSource.getAdminByUsername(username);
      
      if (admin == null) {
        return Left(AuthFailure('Username tidak ditemukan'));
      }

      if (!HashService.verifyPassword(password, admin['password_hash'])) {
        return Left(AuthFailure('Password salah'));
      }

      await localDataSource.saveLoginStatus(true);
      await localDataSource.saveCurrentAdmin(admin['id']);

      return Right(Admin(
        id: admin['id'],
        username: admin['username'],
        namaLengkap: admin['nama_lengkap'] ?? 'Administrator',
        createdAt: DateTime.parse(admin['created_at']),
      ));
    } catch (e) {
      return Left(DatabaseFailure('Gagal login: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.saveLoginStatus(false);
      await localDataSource.clearCurrentAdmin();
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal logout: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await localDataSource.getLoginStatus();
      return Right(isLoggedIn);
    } catch (e) {
      return Left(DatabaseFailure('Gagal cek status login: $e'));
    }
  }

  // ===== CHANGE PASSWORD =====
  @override
  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Ambil admin (hardcode username 'admin')
      final admin = await localDataSource.getAdminByUsername('admin');
      
      if (admin == null) {
        return Left(AuthFailure('Admin tidak ditemukan'));
      }

      // Verifikasi password lama
      if (!HashService.verifyPassword(oldPassword, admin['password_hash'])) {
        return Left(AuthFailure('Password lama salah'));
      }

      // Hash password baru
      final newHashedPassword = HashService.hashPassword(newPassword);

      // Update di database
      await localDataSource.updatePassword(admin['id'], newHashedPassword);

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengganti password: $e'));
    }
  }

  // ===== CHANGE USERNAME =====
  @override
  Future<Either<Failure, void>> changeUsername(String newUsername) async {
    try {
      // Ambil admin saat ini
      final adminId = await localDataSource.getCurrentAdmin();
      if (adminId == null) {
        return Left(AuthFailure('Admin tidak ditemukan'));
      }

      final admin = await localDataSource.getAdminById(adminId);
      if (admin == null) {
        return Left(AuthFailure('Admin tidak ditemukan'));
      }

      // Cek apakah username sudah dipakai
      final existing = await localDataSource.getAdminByUsername(newUsername);
      if (existing != null && existing['id'] != adminId) {
        return Left(AuthFailure('Username sudah digunakan'));
      }

      await localDataSource.updateUsername(adminId, newUsername);

      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengganti username: $e'));
    }
  }
}