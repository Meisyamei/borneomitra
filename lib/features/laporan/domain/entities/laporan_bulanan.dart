import 'package:equatable/equatable.dart';

class LaporanBulanan extends Equatable {
  final int bulan;
  final int tahun;
  final String namaBulan;
  
  final double totalSimpanan;
  final double totalSimpananMasuk;
  final double totalSimpananKeluar;
  final double totalAngsuran;
  final double totalDenda;
  final double totalBunga;
  final double totalPinjamanBaru;
  final double totalPemasukan;
  final double totalPengeluaran;
  final double saldoAkhir;
  final int jumlahAnggotaBaru;

  const LaporanBulanan({
    required this.bulan,
    required this.tahun,
    required this.namaBulan,
    required this.totalSimpanan,
    required this.totalSimpananMasuk,
    required this.totalSimpananKeluar,
    required this.totalAngsuran,
    required this.totalDenda,
    required this.totalBunga,
    required this.totalPinjamanBaru,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.saldoAkhir,
    required this.jumlahAnggotaBaru,
  });

  @override
  List<Object?> get props => [
    bulan, tahun, totalPemasukan, totalPengeluaran, saldoAkhir
  ];
}

class LaporanTahunanDetail extends Equatable {
  final int tahun;
  final List<LaporanBulanan> dataPerBulan;
  final double totalPemasukanTahun;
  final double totalPengeluaranTahun;
  final double saldoAkhirTahun;
  final int totalAnggotaBaruTahun;

  const LaporanTahunanDetail({
    required this.tahun,
    required this.dataPerBulan,
    required this.totalPemasukanTahun,
    required this.totalPengeluaranTahun,
    required this.saldoAkhirTahun,
    required this.totalAnggotaBaruTahun,
  });

  @override
  List<Object?> get props => [
    tahun, totalPemasukanTahun, totalPengeluaranTahun, saldoAkhirTahun
  ];
}