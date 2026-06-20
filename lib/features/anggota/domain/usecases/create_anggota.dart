import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/anggota.dart';
import '../repositories/anggota_repository.dart';

class CreateAnggota {
  final AnggotaRepository repository;
  
  CreateAnggota(this.repository);
  
  Future<Either<Failure, void>> execute(Anggota anggota) async {
    if (anggota.nik.isEmpty) {
      return Left(ValidationFailure('NIK tidak boleh kosong'));
    }
    if (anggota.nama.isEmpty) {
      return Left(ValidationFailure('Nama tidak boleh kosong'));
    }
    if (anggota.noHp.isEmpty) {
      return Left(ValidationFailure('Nomor HP tidak boleh kosong'));
    }
    return await repository.createAnggota(anggota);
  }
}