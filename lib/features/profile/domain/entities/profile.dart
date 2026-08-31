class Profile {
  final String nama;
  final String email;
  final String? fotoPath; // Path foto profile

  Profile({
    required this.nama,
    required this.email,
    this.fotoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'foto_path': fotoPath,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      nama: map['nama'] ?? 'Administrator',
      email: map['email'] ?? 'admin@bms.com',
      fotoPath: map['foto_path'],
    );
  }
}