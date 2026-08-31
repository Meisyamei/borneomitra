class PesertaArisan {
  final int? id;
  final int arisanId;
  final int anggotaId;
  final String namaAnggota;
  final int nomorUrut;
  final String status; // 'aktif', 'sudah_menang'
  final DateTime? tanggalMenang;
  final List<bool> pembayaranBulan; // ← TAMBAHKAN (true = sudah bayar)

  PesertaArisan({
    this.id,
    required this.arisanId,
    required this.anggotaId,
    required this.namaAnggota,
    required this.nomorUrut,
    this.status = 'aktif',
    this.tanggalMenang,
    this.pembayaranBulan = const [], // ← TAMBAHKAN
  });

  // Hitung sudah bayar berapa bulan
  int get jumlahBayar {
    return pembayaranBulan.where((b) => b).length;
  }

  // Hitung sisa bayar
  int get sisaBayar {
    return pembayaranBulan.length - jumlahBayar;
  }

  // Cek apakah sudah lunas
  bool get isLunas {
    return sisaBayar == 0 && pembayaranBulan.isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arisan_id': arisanId,
      'anggota_id': anggotaId,
      'nomor_urut': nomorUrut,
      'status': status,
      'tanggal_menang': tanggalMenang?.toIso8601String(),
    };
  }

  factory PesertaArisan.fromMap(
    Map<String, dynamic> map, {
    bool? sudahBayar,
    int? totalBulan,
    List<bool>? pembayaranBulan,
  }) {
    return PesertaArisan(
      id: map['id'],
      arisanId: map['arisan_id'],
      anggotaId: map['anggota_id'],
      namaAnggota: map['nama_anggota'] ?? 'Unknown',
      nomorUrut: map['nomor_urut'],
      status: map['status'] ?? 'aktif',
      tanggalMenang: map['tanggal_menang'] != null
          ? DateTime.parse(map['tanggal_menang'])
          : null,
      pembayaranBulan: pembayaranBulan ?? [],
    );
  }
}