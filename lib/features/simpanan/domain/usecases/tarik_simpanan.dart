import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../repositories/simpanan_repository.dart';

class TarikSimpanan {
  final SimpananRepository repository;

  TarikSimpanan(this.repository);

  Future<Either<Failure, void>> execute({
    required int anggotaId,
    required double nominal,
    required String keterangan,
  }) async {
    if (nominal <= 0) {
      return Left(ValidationFailure('Nominal harus lebih dari 0'));
    }

    // Cek saldo simpanan anggota
    final saldoResult = await repository.getTotalSimpananByAnggota(anggotaId);
    double saldoSekarang = 0;
    saldoResult.fold(
      (failure) => saldoSekarang = 0,
      (saldo) => saldoSekarang = saldo,
    );

    if (nominal > saldoSekarang) {
      return Left(ValidationFailure('Saldo tidak mencukupi'));
    }

    return await repository.tarikSimpanan(anggotaId, nominal, keterangan);
  }
}