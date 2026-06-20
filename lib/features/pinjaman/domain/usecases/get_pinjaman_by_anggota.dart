import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pinjaman.dart';
import '../repositories/pinjaman_repository.dart';

class GetPinjamanByAnggota {
  final PinjamanRepository repository;

  GetPinjamanByAnggota(this.repository);

  Future<Either<Failure, List<Pinjaman>>> execute(int anggotaId) async {
    if (anggotaId <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.getPinjamanByAnggota(anggotaId);
  }
}