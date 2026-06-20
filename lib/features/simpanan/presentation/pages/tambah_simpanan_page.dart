import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/anggota/domain/entities/anggota.dart';
import 'package:Koperasi/features/anggota/domain/usecases/get_all_anggota.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/create_simpanan.dart';

class TambahSimpananPage extends StatefulWidget {
  const TambahSimpananPage({super.key});

  @override
  State<TambahSimpananPage> createState() => _TambahSimpananPageState();
}

class _TambahSimpananPageState extends State<TambahSimpananPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();

  List<Anggota> _anggotaList = [];
  Anggota? _selectedAnggota;
  String _selectedJenis = 'wajib';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingAnggota = true;

  final List<Map<String, dynamic>> _jenisOptions = [
    {'value': 'wajib', 'label': 'Simpanan Wajib', 'min': 50000},
    {'value': 'sukarela', 'label': 'Simpanan Sukarela', 'min': 10000},
    {'value': 'pokok', 'label': 'Simpanan Pokok', 'min': 100000},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _loadAnggota() async {
    setState(() => _isLoadingAnggota = true);

    final result = await sl<GetAllAnggota>().execute();

    result.fold(
      (failure) => _showError('Gagal load anggota: ${failure.message}'),
      (anggota) {
        setState(() {
          _anggotaList = anggota;
          _isLoadingAnggota = false;
        });
      },
    );
  }

  Future<void> _saveSimpanan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAnggota == null) {
      _showError('Pilih anggota terlebih dahulu');
      return;
    }

    setState(() => _isLoading = true);

    final simpanan = Simpanan(
      anggotaId: _selectedAnggota!.id!,
      jenis: _selectedJenis,
      nominal: double.parse(_nominalController.text),
      tanggal: _selectedDate,
      keterangan: _keteranganController.text.isEmpty ? null : _keteranganController.text,
    );

    final result = await sl<CreateSimpanan>().execute(simpanan);

    setState(() => _isLoading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (_) {
        _showSuccess('Simpanan berhasil ditambahkan');
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
    final selectedJenisData = _jenisOptions.firstWhere((j) => j['value'] == _selectedJenis);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Simpanan'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            const Center(
              child: Icon(Icons.savings, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 20),
            const Text(
              'Form Tambah Simpanan',
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
                        child: Text('${anggota.nama} - ${anggota.nik}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedAnggota = value),
                    validator: (value) => value == null ? 'Pilih anggota' : null,
                  ),
            const SizedBox(height: 16),

            // Jenis Simpanan
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Jenis Simpanan',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              value: _selectedJenis,
              items: _jenisOptions.map((jenis) {
                return DropdownMenuItem<String>(
                  value: jenis['value'] as String,  
                  child: Text(jenis['label'] as String),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedJenis = value!),
            ),
            const SizedBox(height: 16),

            // Nominal
            TextFormField(
              controller: _nominalController,
              decoration: InputDecoration(
                labelText: 'Nominal Simpanan',
                prefixIcon: const Icon(Icons.money),
                border: const OutlineInputBorder(),
                hintText: 'Masukkan nominal',
                helperText: 'Minimal ${NumberFormatter.formatRupiah((selectedJenisData['min'] as num).toDouble())}',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Nominal tidak boleh kosong';
                final nominal = double.tryParse(value);
                if (nominal == null) return 'Nominal tidak valid';
                if (nominal < (selectedJenisData['min'] as num).toDouble()) {
                  return 'Minimal simpanan ${selectedJenisData['label']} adalah ${NumberFormatter.formatRupiah((selectedJenisData['min'] as num).toDouble())}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Tanggal Simpanan'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
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
            const SizedBox(height: 16),

            // Keterangan (Opsional)
            TextFormField(
              controller: _keteranganController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (Opsional)',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
                    onPressed: _isLoading ? null : _saveSimpanan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
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