import 'dart:ui';

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

  // 🔴 PERBAIKI: Progress pelunasan maksimal 100%
  double get progressPelunasan {
    if (jumlah <= 0) return 0;
    
    final totalTerbayar = jumlah - sisaPinjaman;
    
    if (sisaPinjaman <= 0) return 100;
    
    double progress = (totalTerbayar / jumlah) * 100;
    
    if (progress > 100) progress = 100;
    if (progress < 0) progress = 0;
    
    return progress;
  }
  
  // 🔴 TAMBAHKAN: Display progress yang aman
  String get progressDisplay {
    final progress = progressPelunasan;
    if (progress >= 100) return 'LUNAS';
    return '${progress.toStringAsFixed(1)}%';
  }
  
  // 🔴 TAMBAHKAN: Warna progress
  Color get progressColor {
    final progress = progressPelunasan;
    if (progress >= 100) return Color(0xFF00FF00); 
    if (progress >= 75) return Color(0xFF0000FF); 
    if (progress >= 50) return Color(0xFFFFA500); 
    return Color(0xFFFF0000); 
  }

  @override
  List<Object?> get props => [id, anggotaId, jumlah, status, sisaPinjaman];
}