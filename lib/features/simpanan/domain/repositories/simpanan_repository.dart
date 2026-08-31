import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';

abstract class SimpananRepository {
  Future<Either<Failure, List<Simpanan>>> getAllSimpanan();
  Future<Either<Failure, List<Simpanan>>> getSimpananByAnggota(int anggotaId);
  Future<Either<Failure, Simpanan>> getSimpananById(int id);
  Future<Either<Failure, void>> createSimpanan(Simpanan simpanan);
  Future<Either<Failure, void>> tarikSimpanan(
    int anggotaId,
    double nominal,
    String? keterangan,
  );
  Future<Either<Failure, double>> getTotalSimpanan();
  Future<Either<Failure, double>> getTotalSimpananByAnggota(int anggotaId);
  Future<Either<Failure, Map<String, double>>> getTotalSimpananPerJenis();
  Future<Either<Failure, List<Simpanan>>> getSimpananByPeriode(
    DateTime startDate,
    DateTime endDate,
  );
}