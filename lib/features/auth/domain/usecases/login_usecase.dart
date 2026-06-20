import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/admin.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  
  LoginUseCase(this.repository);
  
  Future<Either<Failure, Admin>> execute(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      return Left(ValidationFailure('Username dan password tidak boleh kosong'));
    }
    return await repository.login(username, password);
  }
}