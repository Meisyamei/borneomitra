// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:Koperasi/core/services/server_config.dart';

// class ApiService {
//   // 🔴 BASE URL dari ServerConfig
//   static String get baseUrl => ServerConfig.baseUrl;

//   static Map<String, String> get headers => {
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',
//   };

//   // ============================================
//   // 1. ANGGOTA
//   // ============================================

//   // GET /api/anggota
//   static Future<List<Map<String, dynamic>>> getAnggota() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/anggota'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/anggota/{id}
//   static Future<Map<String, dynamic>?> getAnggotaById(int id) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/anggota/$id'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return data['data'];
//       }
//     }
//     return null;
//   }

//   // GET /api/anggota/search?q=keyword
//   static Future<List<Map<String, dynamic>>> searchAnggota(String keyword) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/anggota/search?q=$keyword'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/anggota/total
//   static Future<int> getTotalAnggota() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/anggota/total'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return data['data']['total'] ?? 0;
//       }
//     }
//     return 0;
//   }

//   // POST /api/anggota
//   static Future<Map<String, dynamic>> postAnggota(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/anggota'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal simpan anggota: ${response.body}');
//   }

//   // PUT /api/anggota/{id}
//   static Future<Map<String, dynamic>> putAnggota(int id, Map<String, dynamic> data) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/anggota/$id'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal update anggota: ${response.body}');
//   }

//   // DELETE /api/anggota/{id}
//   static Future<Map<String, dynamic>> deleteAnggota(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/anggota/$id'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal hapus anggota: ${response.body}');
//   }

//   // ============================================
//   // 2. SIMPANAN
//   // ============================================

//   // GET /api/simpanan
//   static Future<List<Map<String, dynamic>>> getSimpanan() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/simpanan'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/simpanan/{id}
//   static Future<Map<String, dynamic>?> getSimpananById(int id) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/simpanan/$id'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return data['data'];
//       }
//     }
//     return null;
//   }

//   // GET /api/simpanan/anggota/{id}
//   static Future<List<Map<String, dynamic>>> getSimpananByAnggota(int anggotaId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/simpanan/anggota/$anggotaId'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/simpanan/total/{id}
//   static Future<double> getTotalSimpananByAnggota(int anggotaId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/simpanan/total/$anggotaId'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return (data['data']['total'] ?? 0).toDouble();
//       }
//     }
//     return 0;
//   }

//   // GET /api/simpanan/total
//   static Future<double> getTotalSimpananAll() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/simpanan/total'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return (data['data']['total'] ?? 0).toDouble();
//       }
//     }
//     return 0;
//   }

//   // POST /api/simpanan
//   static Future<Map<String, dynamic>> postSimpanan(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/simpanan'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal simpan simpanan: ${response.body}');
//   }

//   // POST /api/simpanan/tarik
//   static Future<Map<String, dynamic>> postTarikSimpanan(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/simpanan/tarik'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal tarik simpanan: ${response.body}');
//   }

//   // ============================================
//   // 3. PINJAMAN
//   // ============================================

//   // GET /api/pinjaman
//   static Future<List<Map<String, dynamic>>> getPinjaman() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/pinjaman'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/pinjaman/{id}
//   static Future<Map<String, dynamic>?> getPinjamanById(int id) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/pinjaman/$id'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return data['data'];
//       }
//     }
//     return null;
//   }

//   // GET /api/pinjaman/anggota/{id}
//   static Future<List<Map<String, dynamic>>> getPinjamanByAnggota(int anggotaId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/pinjaman/anggota/$anggotaId'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/pinjaman/status/{status}
//   static Future<List<Map<String, dynamic>>> getPinjamanByStatus(String status) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/pinjaman/status/$status'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // POST /api/pinjaman
//   static Future<Map<String, dynamic>> postPinjaman(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/pinjaman'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal simpan pinjaman: ${response.body}');
//   }

//   // PUT /api/pinjaman/{id}
//   static Future<Map<String, dynamic>> putPinjaman(int id, Map<String, dynamic> data) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/pinjaman/$id'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal update pinjaman: ${response.body}');
//   }

//   // PUT /api/pinjaman/{id}/status
//   static Future<Map<String, dynamic>> putStatusPinjaman(int id, String status) async {
//     final response = await http.put(
//       Uri.parse('$baseUrl/pinjaman/$id/status'),
//       headers: headers,
//       body: jsonEncode({'status': status}),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal update status pinjaman: ${response.body}');
//   }

//   // DELETE /api/pinjaman/{id}
//   static Future<Map<String, dynamic>> deletePinjaman(int id) async {
//     final response = await http.delete(
//       Uri.parse('$baseUrl/pinjaman/$id'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal hapus pinjaman: ${response.body}');
//   }

//   // POST /api/pinjaman/hitung-angsuran
//   static Future<Map<String, dynamic>> hitungAngsuran(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/pinjaman/hitung-angsuran'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal hitung angsuran: ${response.body}');
//   }

//   // ============================================
//   // 4. ANGSURAN
//   // ============================================

//   // GET /api/angsuran
//   static Future<List<Map<String, dynamic>>> getAngsuran() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/angsuran'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/angsuran/pinjaman/{id}
//   static Future<List<Map<String, dynamic>>> getAngsuranByPinjaman(int pinjamanId) async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/angsuran/pinjaman/$pinjamanId'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/angsuran/tunggakan
//   static Future<List<Map<String, dynamic>>> getTunggakan() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/angsuran/tunggakan'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/angsuran/jatuh-tempo-hari-ini
//   static Future<List<Map<String, dynamic>>> getJatuhTempoHariIni() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/angsuran/jatuh-tempo-hari-ini'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // GET /api/angsuran/hampir-jatuh-tempo
//   static Future<List<Map<String, dynamic>>> getHampirJatuhTempo() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/angsuran/hampir-jatuh-tempo'),
//       headers: headers,
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data['status'] == 'success') {
//         return List<Map<String, dynamic>>.from(data['data'] ?? []);
//       }
//     }
//     return [];
//   }

//   // POST /api/angsuran/hitung-denda
//   static Future<Map<String, dynamic>> hitungDenda(Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/angsuran/hitung-denda'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal hitung denda: ${response.body}');
//   }

//   // POST /api/angsuran/{id}/bayar
//   static Future<Map<String, dynamic>> bayarAngsuran(int id, Map<String, dynamic> data) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/angsuran/$id/bayar'),
//       headers: headers,
//       body: jsonEncode(data),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }
//     throw Exception('Gagal bayar angsuran: ${response.body}');
//   }
// }