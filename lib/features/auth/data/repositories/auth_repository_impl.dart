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
        namaLengkap: admin['nama_lengkap'],
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
  
  @override
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword) async {
    try {
      final currentAdminId = await localDataSource.getCurrentAdmin();
      if (currentAdminId == null) {
        return Left(AuthFailure('Admin tidak ditemukan'));
      }
      
      final admin = await localDataSource.getAdminById(currentAdminId);
      if (admin == null) {
        return Left(AuthFailure('Admin tidak ditemukan'));
      }
      
      if (!HashService.verifyPassword(oldPassword, admin['password_hash'])) {
        return Left(AuthFailure('Password lama salah'));
      }
      
      final newHashedPassword = HashService.hashPassword(newPassword);
      await localDataSource.updatePassword(currentAdminId, newHashedPassword);
      
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengganti password: $e'));
    }
  }
}