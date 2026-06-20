import 'package:equatable/equatable.dart';

class Pinjaman extends Equatable {
  final int? id;
  final int anggotaId;
  final double jumlah;
  final double bunga;
  final int tenor;
  final DateTime tanggalPinjam;
  final String status;
  final double dendaKeterlambatan;
  final double sisaPinjaman;
  final String namaAnggota;

  const Pinjaman({
    this.id,
    required this.anggotaId,
    required this.jumlah,
    required this.bunga,
    required this.tenor,
    required this.tanggalPinjam,
    this.status = 'aktif',
    this.dendaKeterlambatan = 50000,
    this.sisaPinjaman = 0,
    this.namaAnggota = '',
  });

  double get angsuranPerBulan {
    final totalBunga = jumlah * (bunga / 100);
    final totalPinjaman = jumlah + totalBunga;
    return totalPinjaman / tenor;
  }

  double get totalHarusBayar {
    final totalBunga = jumlah * (bunga / 100);
    return jumlah + totalBunga;
  }

  DateTime get tanggalJatuhTempo {
    return tanggalPinjam.add(Duration(days: tenor * 30));
  }

  bool get isLunas => status == 'lunas';
  bool get isMenunggak => status == 'menunggak';
  bool get isAktif => status == 'aktif';

  double get progressPelunasan {
    if (jumlah == 0) return 0;
    final terbayar = jumlah - sisaPinjaman;
    return (terbayar / jumlah) * 100;
  }

  @override
  List<Object?> get props => [id, anggotaId, jumlah, status];
}