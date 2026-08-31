import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

class ChangeUsernameUseCase {
  final AuthRepository repository;

  ChangeUsernameUseCase(this.repository);

  Future<Either<Failure, void>> execute(String newUsername) async {
    // Validasi
    if (newUsername.isEmpty) {
      return Left(ValidationFailure('Username tidak boleh kosong'));
    }
    if (newUsername.length < 3) {
      return Left(ValidationFailure('Username minimal 3 karakter'));
    }

    return await repository.changeUsername(newUsername);
  }
}