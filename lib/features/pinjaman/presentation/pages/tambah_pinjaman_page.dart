import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/constants/app_constants.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/anggota/domain/entities/anggota.dart';
import 'package:Koperasi/features/anggota/domain/usecases/get_all_anggota.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';
import 'package:Koperasi/features/pinjaman/domain/usecases/create_pinjaman.dart';
import 'package:Koperasi/features/pinjaman/domain/usecases/hitung_angsuran.dart';

class TambahPinjamanPage extends StatefulWidget {
  const TambahPinjamanPage({super.key});

  @override
  State<TambahPinjamanPage> createState() => _TambahPinjamanPageState();
}

class _TambahPinjamanPageState extends State<TambahPinjamanPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _bungaController =
      TextEditingController(text: AppConstants.defaultBunga.toString());
  final _tenorController = TextEditingController();

  List<Anggota> _anggotaList = [];
  Anggota? _selectedAnggota;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingAnggota = true;

  // Hasil perhitungan
  Map<String, double> _perhitungan = {};

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    _bungaController.dispose();
    _tenorController.dispose();
    super.dispose();
  }

  Future<void> _loadAnggota() async {
    setState(() => _isLoadingAnggota = true);

    final result = await sl<GetAllAnggota>().execute();

    result.fold(
      (failure) => _showError('Gagal load anggota: ${failure.message}'),
      (anggota) {
        setState(() {
          _anggotaList = anggota.where((a) => a.isAktif).toList();
          _isLoadingAnggota = false;
        });
      },
    );
  }

  Future<void> _hitungPerhitungan() async {
    final jumlah = double.tryParse(_jumlahController.text) ?? 0;
    final bunga = double.tryParse(_bungaController.text) ?? 0;
    final tenor = int.tryParse(_tenorController.text) ?? 0;

    if (jumlah > 0 && tenor > 0) {
      final result = await sl<HitungAngsuran>().execute(jumlah, bunga, tenor);

      result.fold(
        (failure) => _showError(failure.message),
        (hasil) {
          setState(() => _perhitungan = hasil);
        },
      );
    } else {
      setState(() => _perhitungan = {});
    }
  }

  Future<void> _savePinjaman() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnggota == null) {
      _showError('Pilih anggota terlebih dahulu');
      return;
    }

    final jumlah = double.parse(_jumlahController.text);

    // Validasi limit pinjaman
    if (_selectedAnggota!.sisaLimitPinjaman < jumlah) {
      _showError('Jumlah pinjaman melebihi limit maksimal Rp50.000.000');
      return;
    }

    setState(() => _isLoading = true);

    final pinjaman = Pinjaman(
      anggotaId: _selectedAnggota!.id!,
      jumlah: jumlah,
      bunga: double.parse(_bungaController.text),
      tenor: int.parse(_tenorController.text),
      tanggalPinjam: _selectedDate,
      status: 'aktif',
      dendaKeterlambatan: AppConstants.dendaPerBulan,
      sisaPinjaman: jumlah,
    );

    final result = await sl<CreatePinjaman>().execute(pinjaman);

    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (_) {
        _showSuccess('Pinjaman berhasil ditambahkan');
        Navigator.pop(context, true);
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pinjaman'),
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            const Center(
              child: Icon(Icons.credit_card, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            const Text(
              'Form Pengajuan Pinjaman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Pilih Anggota
            _isLoadingAnggota
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<Anggota>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Anggota',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedAnggota,
                    items: _anggotaList.map((anggota) {
                      return DropdownMenuItem(
                        value: anggota,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(anggota.nama),
                            Text(
                              'Sisa limit: ${NumberFormatter.formatRupiah(anggota.sisaLimitPinjaman)}',
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedAnggota = value),
                    validator: (value) => value == null ? 'Pilih anggota' : null,
                  ),
            const SizedBox(height: 16),

            // Jumlah Pinjaman
            TextFormField(
              controller: _jumlahController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Pinjaman',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
                hintText: 'Contoh: 5000000',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _hitungPerhitungan(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah pinjaman tidak boleh kosong';
                }
                final jumlah = double.tryParse(value);
                if (jumlah == null) return 'Jumlah tidak valid';
                if (jumlah < 500000) return 'Minimal pinjaman Rp500.000';
                if (jumlah > AppConstants.maxPinjaman) {
                  return 'Maksimal pinjaman Rp50.000.000';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bunga
            TextFormField(
              controller: _bungaController,
              decoration: const InputDecoration(
                labelText: 'Bunga (%)',
                prefixIcon: Icon(Icons.percent),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _hitungPerhitungan(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bunga tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tenor
            TextFormField(
              controller: _tenorController,
              decoration: const InputDecoration(
                labelText: 'Tenor (Bulan)',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _hitungPerhitungan(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tenor tidak boleh kosong';
                }
                final tenor = int.tryParse(value);
                if (tenor == null) return 'Tenor tidak valid';
                if (tenor < 1) return 'Minimal 1 bulan';
                if (tenor > 24) return 'Maksimal 24 bulan';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal Pinjam
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal Pinjaman'),
              subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 24),

            // Hasil Perhitungan
            if (_perhitungan.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Perhitungan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(),
                      _buildResultRow(
                          'Jumlah Pinjaman',
                          NumberFormatter.formatRupiah(
                              double.parse(_jumlahController.text))),
                      _buildResultRow(
                          'Bunga (${_bungaController.text}%)',
                          NumberFormatter.formatRupiah(
                              _perhitungan['total_bunga'] ?? 0)),
                      _buildResultRow(
                          'Total Harus Dibayar',
                          NumberFormatter.formatRupiah(
                              _perhitungan['total_harus_bayar'] ?? 0),
                          isBold: true),
                      const SizedBox(height: 8),
                      _buildResultRow(
                          'Biaya Admin/Bulan',
                          NumberFormatter.formatRupiah(
                              _perhitungan['biaya_admin'] ?? 0)),
                      _buildResultRow(
                          'Angsuran Pokok + Bunga/Bulan',
                          NumberFormatter.formatRupiah(
                              _perhitungan['angsuran_per_bulan'] ?? 0)),
                      _buildResultRow(
                          'Total Angsuran/Bulan',
                          NumberFormatter.formatRupiah(
                              _perhitungan['total_angsuran_per_bulan'] ?? 0),
                          isBold: true,
                          color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePinjaman,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Ajukan Pinjaman', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}