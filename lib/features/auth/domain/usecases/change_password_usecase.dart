import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validasi
    if (oldPassword.isEmpty) {
      return Left(ValidationFailure('Password lama tidak boleh kosong'));
    }
    if (newPassword.isEmpty) {
      return Left(ValidationFailure('Password baru tidak boleh kosong'));
    }
    if (newPassword.length < 6) {
      return Left(ValidationFailure('Password minimal 6 karakter'));
    }
    if (newPassword != confirmPassword) {
      return Left(ValidationFailure('Password baru tidak cocok'));
    }

    return await repository.changePassword(oldPassword, newPassword);
  }
}