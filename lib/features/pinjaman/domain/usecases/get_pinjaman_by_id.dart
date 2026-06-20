import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pinjaman.dart';
import '../repositories/pinjaman_repository.dart';

class GetPinjamanById {
  final PinjamanRepository repository;

  GetPinjamanById(this.repository);

  Future<Either<Failure, Pinjaman>> execute(int id) async {
    if (id <= 0) {
      return Left(ValidationFailure('ID pinjaman tidak valid'));
    }
    return await repository.getPinjamanById(id);
  }
}