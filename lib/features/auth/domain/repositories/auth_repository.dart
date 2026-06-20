import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';

abstract class AuthRepository {
  Future<Either<Failure, Admin>> login(String username, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, bool>> isLoggedIn();
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword);
}