import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pinjaman.dart';

abstract class PinjamanRepository {
  Future<Either<Failure, List<Pinjaman>>> getAllPinjaman();
  Future<Either<Failure, Pinjaman>> getPinjamanById(int id);
  Future<Either<Failure, List<Pinjaman>>> getPinjamanByAnggota(int anggotaId);
  Future<Either<Failure, void>> createPinjaman(Pinjaman pinjaman);
  Future<Either<Failure, void>> updateStatusPinjaman(int id, String status);
  Future<Either<Failure, void>> updateSisaPinjaman(int id, double sisaBaru);
}