import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/anggota/domain/entities/anggota.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/tarik_simpanan.dart';

class TarikSimpananPage extends StatefulWidget {
  final Anggota anggota;
  final double saldoSekarang;

  const TarikSimpananPage({
    super.key,
    required this.anggota,
    required this.saldoSekarang,
  });

  @override
  State<TarikSimpananPage> createState() => _TarikSimpananPageState();
}

class _TarikSimpananPageState extends State<TarikSimpananPage> {
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nominalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _tarikSimpanan() async {
    if (!_formKey.currentState!.validate()) return;

    final nominal = double.parse(_nominalController.text);

    if (nominal > widget.saldoSekarang) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo tidak mencukupi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await sl<TarikSimpanan>().execute(
      anggotaId: widget.anggota.id!,
      nominal: nominal,
      keterangan: _keteranganController.text,
    );

    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${failure.message}'), backgroundColor: Colors.red),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penarikan berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarik Simpanan - ${widget.anggota.nama}'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info Saldo
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Saldo Saat Ini'),
                      Text(
                        NumberFormatter.formatRupiah(widget.saldoSekarang),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nominal
              TextFormField(
                controller: _nominalController,
                decoration: InputDecoration(
                  labelText: 'Nominal Penarikan',
                  prefixIcon: const Icon(Icons.money_off),
                  border: const OutlineInputBorder(),
                  helperText: 'Maksimal ${NumberFormatter.formatRupiah(widget.saldoSekarang)}',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  final nominal = double.tryParse(value);
                  if (nominal == null || nominal <= 0) {
                    return 'Nominal harus lebih dari 0';
                  }
                  if (nominal > widget.saldoSekarang) {
                    return 'Melebihi saldo yang tersedia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Keterangan
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
                      onPressed: _isLoading ? null : _tarikSimpanan,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Tarik Dana', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}