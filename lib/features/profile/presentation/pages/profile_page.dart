import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/profile/domain/entities/profile.dart';
import 'package:Koperasi/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:Koperasi/features/auth/domain/usecases/change_username_usecase.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileLocalDataSource _profileSource;
  final ImagePicker _imagePicker = ImagePicker();

  Profile _profile = Profile(nama: 'Administrator', email: 'admin@bms.com');
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers untuk edit
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordLamaController = TextEditingController();
  final TextEditingController _passwordBaruController = TextEditingController();
  final TextEditingController _konfirmasiPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileSource = ProfileLocalDataSource(DatabaseService());
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // Ambil profile dari database
      _profile = await _profileSource.getProfile();
      
      // Ambil username dari database admin
      final db = await DatabaseService().database;
      final adminResult = await db.query(
        'admin',
        where: 'id = ?',
        whereArgs: [1],
      );
      
      if (adminResult.isNotEmpty) {
        _usernameController.text = adminResult.first['username'] as String? ?? 'admin';
      } else {
        _usernameController.text = 'admin';
      }
      
      _namaController.text = _profile.nama;
      _emailController.text = _profile.email;
      print('✅ Profile loaded: ${_profile.nama}');
    } catch (e) {
      print('❌ Error load profile: $e');
      _profile = Profile(nama: 'Administrator', email: 'admin@bms.com');
      _usernameController.text = 'admin';
      _namaController.text = 'Administrator';
      _emailController.text = 'admin@bms.com';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final newProfile = Profile(
      nama: _namaController.text.trim(),
      email: _emailController.text.trim(),
      fotoPath: _profile.fotoPath,
    );

    await _profileSource.saveProfile(newProfile);
    setState(() {
      _profile = newProfile;
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile berhasil diupdate'), backgroundColor: Colors.green),
    );
    Navigator.pop(context, true);
  }

  Future<void> _changeUsername() async {
    final newUsername = _usernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak boleh kosong'), backgroundColor: Colors.red),
      );
      return;
    }

    if (newUsername.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username minimal 3 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final db = await DatabaseService().database;

      // Cek apakah username sudah dipakai
      final existing = await db.query(
        'admin',
        where: 'username = ? AND id != ?',
        whereArgs: [newUsername, 1],
      );

      if (existing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username sudah digunakan'), backgroundColor: Colors.red),
        );
        return;
      }

      // Update username
      await db.update(
        'admin',
        {'username': newUsername},
        where: 'id = ?',
        whereArgs: [1],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username berhasil diubah menjadi "$newUsername"'), backgroundColor: Colors.green),
      );

      await _loadProfile(); // Refresh profile
      setState(() {});
      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error change username: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ganti username: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===== CHANGE PASSWORD =====
  Future<void> _changePassword() async {
    // Validasi password baru
    if (_passwordBaruController.text != _konfirmasiPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password baru tidak cocok'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordBaruController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal 6 karakter'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final db = await DatabaseService().database;

      // Ambil admin
      final adminResult = await db.query(
        'admin',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (adminResult.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin tidak ditemukan'), backgroundColor: Colors.red),
        );
        return;
      }

      final admin = adminResult.first;
      final passwordHash = admin['password_hash'] as String;

      // Verifikasi password lama
      if (!BCrypt.checkpw(_passwordLamaController.text, passwordHash)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password lama salah'), backgroundColor: Colors.red),
        );
        return;
      }

      // Hash password baru
      final newHash = BCrypt.hashpw(
        _passwordBaruController.text,
        BCrypt.gensalt(logRounds: 12),
      );

      // Update di database
      await db.update(
        'admin',
        {'password_hash': newHash},
        where: 'id = ?',
        whereArgs: [1],
      );

      // Clear form
      _passwordLamaController.clear();
      _passwordBaruController.clear();
      _konfirmasiPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah!'), backgroundColor: Colors.green),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error change password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ganti password: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===== PICK IMAGE =====
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      try {
        final imageFile = File(image.path);
        final savedPath = await _profileSource.saveFoto(imageFile);

        if (savedPath != null) {
          final newProfile = Profile(
            nama: _profile.nama,
            email: _profile.email,
            fotoPath: savedPath,
          );

          await _profileSource.saveProfile(newProfile);
          setState(() {
            _profile = newProfile;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profile berhasil diupdate'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      try {
        final imageFile = File(image.path);
        final savedPath = await _profileSource.saveFoto(imageFile);

        if (savedPath != null) {
          final newProfile = Profile(
            nama: _profile.nama,
            email: _profile.email,
            fotoPath: savedPath,
          );

          await _profileSource.saveProfile(newProfile);
          setState(() {
            _profile = newProfile;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profile berhasil diupdate'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Foto Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.delete_outline,
                    label: 'Hapus Foto',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _profileSource.deleteFoto(_profile.fotoPath);
      final newProfile = Profile(
        nama: _profile.nama,
        email: _profile.email,
        fotoPath: null,
      );
      await _profileSource.saveProfile(newProfile);
      setState(() {
        _profile = newProfile;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profile dihapus'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.blue,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ===== FOTO PROFILE =====
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _profile.fotoPath != null && _profile.fotoPath!.isNotEmpty
                              ? FileImage(File(_profile.fotoPath!))
                              : null,
                          child: _profile.fotoPath == null || _profile.fotoPath!.isEmpty
                              ? Text(
                                  _profile.nama.isNotEmpty
                                      ? _profile.nama[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap foto untuk ganti',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // ===== FORM EDIT =====
                  if (_isEditing) ...[
                    // 🔴 USERNAME FIELD
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    // 🔴 TOMBOL UPDATE USERNAME
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _changeUsername,
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('Update Username'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 36),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    // ===== PASSWORD CHANGE SECTION =====
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ganti Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _passwordLamaController,
                            label: 'Password Lama',
                            icon: Icons.lock,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _passwordBaruController,
                            label: 'Password Baru',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _konfirmasiPasswordController,
                            label: 'Konfirmasi Password Baru',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _changePassword,
                              icon: const Icon(Icons.save),
                              label: const Text('Simpan Password'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _isEditing = false);
                              _loadProfile();
                            },
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Simpan Profile'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // ===== TAMPILAN PROFILE =====
                    _buildInfoRow('Username', _usernameController.text, Icons.person_outline),
                    const Divider(),
                    _buildInfoRow('Nama', _profile.nama, Icons.person),
                    const Divider(),
                    _buildInfoRow('Email', _profile.email, Icons.email),
                    const Divider(),
                    _buildInfoRow(
                      'Status',
                      'Admin',
                      Icons.verified,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}