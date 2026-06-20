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

  DateTime _tanggalMulai = DateTime.now();
  bool _isLoading = false;

  final ArisanService _arisanService = ArisanService();

  @override
  void dispose() {
    _namaController.dispose();
    _iuranController.dispose();
    super.dispose();
  }

  Future<void> _saveArisan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final arisan = ArisanModel(
      nama: _namaController.text,
      iuran: double.parse(_iuranController.text),
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
              decoration: InputDecoration(
                labelText: 'Iuran per Peserta',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
                hintText: 'Contoh: 50000: ${NumberFormatter.formatNumber(50000)}',
                helperText: 'Contoh format: ${NumberFormatter.formatNumber(50000)}',
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