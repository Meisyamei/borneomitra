import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/tunggakan.dart';
import '../repositories/tunggakan_repository.dart';

class GetTunggakanByAnggota {
  final TunggakanRepository repository;

  GetTunggakanByAnggota(this.repository);

  Future<Either<Failure, List<Tunggakan>>> execute(int anggotaId) async {
    if (anggotaId <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.getTunggakanByAnggota(anggotaId);
  }
}