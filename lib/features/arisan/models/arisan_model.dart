class ArisanModel {
  final int? id;
  final String nama;
  final double iuran;
  final DateTime tanggalMulai;
  final DateTime? tanggalSelesai;
  final String status; // 'aktif', 'selesai'
  final List<PesertaArisan>? peserta;

  ArisanModel({
    this.id,
    required this.nama,
    required this.iuran,
    required this.tanggalMulai,
    this.tanggalSelesai,
    this.status = 'aktif',
    this.peserta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'iuran': iuran,
      'tanggal_mulai': tanggalMulai.toIso8601String(),
      'tanggal_selesai': tanggalSelesai?.toIso8601String(),
      'status': status,
    };
  }

  factory ArisanModel.fromMap(Map<String, dynamic> map) {
    return ArisanModel(
      id: map['id'],
      nama: map['nama'],
      iuran: map['iuran']?.toDouble() ?? 0,
      tanggalMulai: DateTime.parse(map['tanggal_mulai']),
      tanggalSelesai: map['tanggal_selesai'] != null
          ? DateTime.parse(map['tanggal_selesai'])
          : null,
      status: map['status'] ?? 'aktif',
    );
  }
}

class PesertaArisan {
  final int? id;
  final int arisanId;
  final int anggotaId;
  final String namaAnggota;
  final int nomorUrut;
  final String status; // 'aktif', 'sudah_menang'
  final DateTime? tanggalMenang;

  PesertaArisan({
    this.id,
    required this.arisanId,
    required this.anggotaId,
    required this.namaAnggota,
    required this.nomorUrut,
    this.status = 'aktif',
    this.tanggalMenang,
  });
}