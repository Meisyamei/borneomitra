import 'package:equatable/equatable.dart';

class Anggota extends Equatable {
  final int? id;
  final String nik;
  final String nama;
  final String alamat;
  final String noHp;
  final DateTime tanggalDaftar;
  final double totalSimpanan;
  final double totalPinjaman;
  final String status;

  const Anggota({
    this.id,
    required this.nik,
    required this.nama,
    required this.alamat,
    required this.noHp,
    required this.tanggalDaftar,
    this.totalSimpanan = 0,
    this.totalPinjaman = 0,
    this.status = 'aktif',
  });

  double get sisaLimitPinjaman {
    const maxPinjaman = 50000000;
    return maxPinjaman - totalPinjaman;
  }

  bool get isAktif => status == 'aktif' && totalPinjaman < 50000000;
  
  bool get memilikiTunggakan => totalPinjaman > totalSimpanan * 0.3;

  Anggota copyWith({
    int? id,
    String? nik,
    String? nama,
    String? alamat,
    String? noHp,
    DateTime? tanggalDaftar,
    double? totalSimpanan,
    double? totalPinjaman,
    String? status,
  }) {
    return Anggota(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      alamat: alamat ?? this.alamat,
      noHp: noHp ?? this.noHp,
      tanggalDaftar: tanggalDaftar ?? this.tanggalDaftar,
      totalSimpanan: totalSimpanan ?? this.totalSimpanan,
      totalPinjaman: totalPinjaman ?? this.totalPinjaman,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nik,
        nama,
        alamat,
        noHp,
        tanggalDaftar,
        totalSimpanan,
        totalPinjaman,
        status,
      ];
}