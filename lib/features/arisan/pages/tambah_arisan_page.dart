import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import '../models/arisan_model.dart';
import '../services/arisan_service.dart';

class TambahArisanPage extends StatefulWidget {
  const TambahArisanPage({super.key});

  @override
  State<TambahArisanPage> createState() => _TambahArisanPageState();
}

class _TambahArisanPageState extends State<TambahArisanPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _iuranController = TextEditingController();
  final _biayaAdminController = TextEditingController(text: '20');  // ← TAMBAHKAN
  final _totalBulanController = TextEditingController();

  DateTime _tanggalMulai = DateTime.now();
  bool _isLoading = false;
  bool _isPersen = true;  // true = persen, false = nominal

  final ArisanService _arisanService = ArisanService();

  @override
  void dispose() {
    _namaController.dispose();
    _iuranController.dispose();
    _biayaAdminController.dispose();
    super.dispose();
  }

  Future<void> _saveArisan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    double biayaAdmin = 0;
    final iuran = double.parse(_iuranController.text);
    final totalBulan = int.parse(_totalBulanController.text);
    if (_isPersen) {
      // Hitung dari persen
      final persen = double.parse(_biayaAdminController.text) / 100;
      biayaAdmin = iuran * persen;
    } else {
      // Nominal tetap
      biayaAdmin = double.parse(_biayaAdminController.text);
    }

    final arisan = ArisanModel(
      nama: _namaController.text,
      iuran: iuran,
      biayaAdmin: biayaAdmin,
      totalBulan: totalBulan,  
      tanggalMulai: _tanggalMulai,
      status: 'aktif',
    );

    await _arisanService.createArisan(arisan);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arisan berhasil ditambahkan'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Arisan'),
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Icon(Icons.groups, size: 64, color: Colors.purple),
            ),
            const SizedBox(height: 20),
            const Text(
              'Form Tambah Arisan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // durasi arisan
            TextFormField(
              controller: _totalBulanController,
              decoration: const InputDecoration(
                labelText: 'Durasi Arisan (Bulan)',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
                hintText: 'Contoh: 5',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Durasi tidak boleh kosong';
                }
                final bulan = int.tryParse(value);
                if (bulan == null || bulan < 2) {
                  return 'Minimal 2 bulan';
                }
                return null;
              },
            ),
            // Nama Arisan
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Arisan',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama arisan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Iuran
            TextFormField(
              controller: _iuranController,
              decoration: const InputDecoration(
                labelText: 'Iuran per Peserta',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
                hintText: 'Contoh: 50000',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Iuran tidak boleh kosong';
                }
                final iuran = double.tryParse(value);
                if (iuran == null || iuran <= 0) {
                  return 'Iuran harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            //biaya admin
            const Text(
              'Biaya Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Toggle persen / nominal
                Expanded(
                  flex: 2,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('%')),
                      ButtonSegment(value: false, label: Text('Rp')),
                    ],
                    selected: {_isPersen},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isPersen = newSelection.first;
                        _biayaAdminController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _biayaAdminController,
                    decoration: InputDecoration(
                      hintText: _isPersen ? 'Masukkan persen (contoh: 20)' : 'Masukkan nominal',
                      border: const OutlineInputBorder(),
                      prefixText: _isPersen ? '' : 'Rp ',
                      suffixText: _isPersen ? '%' : '',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Biaya admin tidak boleh kosong';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val < 0) {
                        return 'Masukkan angka yang valid';
                      }
                      if (_isPersen && val > 100) {
                        return 'Persen tidak boleh lebih dari 100%';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_isPersen)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '* Biaya admin akan dihitung dari persen x iuran',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 16),

            // Tanggal Mulai
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal Mulai'),
              subtitle: Text('${_tanggalMulai.day}/${_tanggalMulai.month}/${_tanggalMulai.year}'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _tanggalMulai,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _tanggalMulai = date);
              },
            ),
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
                    onPressed: _isLoading ? null : _saveArisan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.purple,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Simpan', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}