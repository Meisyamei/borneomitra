import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/anggota.dart';

abstract class AnggotaRepository {
  Future<Either<Failure, List<Anggota>>> getAllAnggota();
  Future<Either<Failure, Anggota>> getAnggotaById(int id);
  Future<Either<Failure, Anggota>> getAnggotaByNik(String nik);
  Future<Either<Failure, void>> createAnggota(Anggota anggota);
  Future<Either<Failure, void>> updateAnggota(Anggota anggota);
  Future<Either<Failure, void>> deleteAnggota(int id);
  Future<Either<Failure, List<Anggota>>> searchAnggota(String keyword);
  Future<Either<Failure, void>> updateTotalSimpanan(int anggotaId, double nominal);
  Future<Either<Failure, void>> updateTotalPinjaman(int anggotaId, double nominal);
}