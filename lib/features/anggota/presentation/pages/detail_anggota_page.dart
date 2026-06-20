import 'package:flutter/material.dart';
import '../../domain/entities/anggota.dart';
import '../../domain/usecases/update_anggota.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../injection_container.dart';

class DetailAnggotaPage extends StatefulWidget {
  final Anggota anggota;
  
  const DetailAnggotaPage({super.key, required this.anggota});

  @override
  State<DetailAnggotaPage> createState() => _DetailAnggotaPageState();
}

class _DetailAnggotaPageState extends State<DetailAnggotaPage> {
  late Anggota _anggota;
  bool _isEditing = false;
  bool _isLoading = false;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _noHpController;

  @override
  void initState() {
    super.initState();
    _anggota = widget.anggota;
    _namaController = TextEditingController(text: _anggota.nama);
    _alamatController = TextEditingController(text: _anggota.alamat);
    _noHpController = TextEditingController(text: _anggota.noHp);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _updateAnggota() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final updatedAnggota = _anggota.copyWith(
      nama: _namaController.text,
      alamat: _alamatController.text,
      noHp: _noHpController.text,
    );
    
    final result = await sl<UpdateAnggota>().execute(updatedAnggota);
    
    setState(() => _isLoading = false);
    
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal update: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (_) {
        setState(() {
          _anggota = updatedAnggota;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anggota berhasil diupdate'), backgroundColor: Colors.green),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Anggota' : 'Detail Anggota'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildDetailView(),
    );
  }
  
  Widget _buildDetailView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Avatar
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _anggota.nama.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _anggota.isAktif ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _anggota.isAktif ? 'Anggota Aktif' : 'Anggota Non-Aktif',
              style: TextStyle(
                color: _anggota.isAktif ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('NIK', _anggota.nik, Icons.numbers),
                  const Divider(),
                  _buildInfoRow('Nama Lengkap', _anggota.nama, Icons.person),
                  const Divider(),
                  _buildInfoRow('Alamat', _anggota.alamat, Icons.location_on),
                  const Divider(),
                  _buildInfoRow('Nomor HP', _anggota.noHp, Icons.phone),
                  const Divider(),
                  _buildInfoRow('Tanggal Daftar', DateFormatter.formatDate(_anggota.tanggalDaftar), Icons.calendar_today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Financial Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Informasi Keuangan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFinancialItem(
                          'Total Simpanan',
                          NumberFormatter.formatRupiah(_anggota.totalSimpanan),
                          Icons.savings,
                          Colors.green,
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildFinancialItem(
                          'Total Pinjaman',
                          NumberFormatter.formatRupiah(_anggota.totalPinjaman),
                          Icons.credit_card,
                          Colors.orange,
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildFinancialItem(
                          'Sisa Limit',
                          NumberFormatter.formatRupiah(_anggota.sisaLimitPinjaman),
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          if (!_anggota.isAktif)
            ElevatedButton.icon(
              onPressed: () {
                // Reactivate member
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Aktivasi Kembali'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Nama Field
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Alamat Field
          TextFormField(
            controller: _alamatController,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Alamat tidak boleh kosong';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // No HP Field
          TextFormField(
            controller: _noHpController,
            decoration: const InputDecoration(
              labelText: 'Nomor HP',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nomor HP tidak boleh kosong';
              if (value.length < 10) return 'Nomor HP minimal 10 digit';
              return null;
            },
          ),
          const SizedBox(height: 30),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAnggota,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFinancialItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}