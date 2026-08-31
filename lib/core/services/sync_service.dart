// import 'package:sqflite/sqflite.dart';
// import 'package:Koperasi/core/services/database_service.dart';
// import 'package:Koperasi/core/services/api_service.dart';

// class SyncService {
//   final DatabaseService dbService;

//   SyncService(this.dbService);

//   // ============================================
//   // SYNC ALL DATA
//   // ============================================
//   Future<Map<String, int>> syncAllData() async {
//     final results = {
//       'anggota': 0,
//       'simpanan': 0,
//       'pinjaman': 0,
//       'angsuran': 0,
//     };

//     print('🔄 Memulai sinkronisasi data...');

//     try {
//       results['anggota'] = await syncAnggota();
//       results['simpanan'] = await syncSimpanan();
//       results['pinjaman'] = await syncPinjaman();
//       results['angsuran'] = await syncAngsuran();

//       print('✅ Sinkronisasi selesai!');
//       print('📊 Anggota: ${results['anggota']} data');
//       print('📊 Simpanan: ${results['simpanan']} data');
//       print('📊 Pinjaman: ${results['pinjaman']} data');
//       print('📊 Angsuran: ${results['angsuran']} data');

//       return results;
//     } catch (e) {
//       print('❌ Error sync: $e');
//       return results;
//     }
//   }

//   // ============================================
//   // SYNC ANGGOTA
//   // ============================================
//   Future<int> syncAnggota() async {
//     try {
//       final db = await dbService.database;
//       final serverData = await ApiService.getAnggota();
//       print('📡 Server: ${serverData.length} anggota');

//       int savedCount = 0;
//       for (var item in serverData) {
//         final existing = await db.query(
//           'anggota',
//           where: 'nik = ?',
//           whereArgs: [item['nik']],
//         );

//         if (existing.isNotEmpty) {
//           // Update data yang sudah ada
//           await db.update(
//             'anggota',
//             {
//               'nama': item['nama'],
//               'alamat': item['alamat'] ?? '',
//               'no_hp': item['no_hp'] ?? '',
//               'total_simpanan': item['total_simpanan']?.toDouble() ?? 0,
//               'total_pinjaman': item['total_pinjaman']?.toDouble() ?? 0,
//               'status': item['status'] ?? 'aktif',
//               'updated_at': DateTime.now().toIso8601String(),
//             },
//             where: 'nik = ?',
//             whereArgs: [item['nik']],
//           );
//         } else {
//           // Insert data baru
//           await db.insert('anggota', {
//             'nik': item['nik'],
//             'nama': item['nama'],
//             'alamat': item['alamat'] ?? '',
//             'no_hp': item['no_hp'] ?? '',
//             'total_simpanan': item['total_simpanan']?.toDouble() ?? 0,
//             'total_pinjaman': item['total_pinjaman']?.toDouble() ?? 0,
//             'status': item['status'] ?? 'aktif',
//             'tanggal_daftar': DateTime.now().toIso8601String(),
//             'created_at': DateTime.now().toIso8601String(),
//             'updated_at': DateTime.now().toIso8601String(),
//           });
//           savedCount++;
//         }
//       }

//       print('✅ Anggota: $savedCount data baru disimpan');
//       return savedCount;
//     } catch (e) {
//       print('❌ Error sync anggota: $e');
//       return 0;
//     }
//   }

//   // ============================================
//   // SYNC SIMPANAN
//   // ============================================
//   Future<int> syncSimpanan() async {
//     try {
//       final db = await dbService.database;
//       final serverData = await ApiService.getSimpanan();
//       print('📡 Server: ${serverData.length} simpanan');

//       int savedCount = 0;
//       for (var item in serverData) {
//         final existing = await db.query(
//           'simpanan',
//           where: 'id = ?',
//           whereArgs: [item['id']],
//         );

//         if (existing.isNotEmpty) {
//           // Update data yang sudah ada
//           await db.update(
//             'simpanan',
//             {
//               'anggota_id': item['anggota_id'],
//               'jenis': item['jenis'],
//               'tipe': item['tipe'] ?? 'masuk',
//               'nominal': item['nominal'],
//               'tanggal': item['tanggal'],
//               'keterangan': item['keterangan'],
//               'updated_at': DateTime.now().toIso8601String(),
//             },
//             where: 'id = ?',
//             whereArgs: [item['id']],
//           );
//         } else {
//           // Insert data baru
//           await db.insert('simpanan', {
//             'id': item['id'],
//             'anggota_id': item['anggota_id'],
//             'jenis': item['jenis'],
//             'tipe': item['tipe'] ?? 'masuk',
//             'nominal': item['nominal'],
//             'tanggal': item['tanggal'],
//             'keterangan': item['keterangan'],
//             'created_at': DateTime.now().toIso8601String(),
//           });
//           savedCount++;
//         }
//       }

//       print('✅ Simpanan: $savedCount data baru disimpan');
//       return savedCount;
//     } catch (e) {
//       print('❌ Error sync simpanan: $e');
//       return 0;
//     }
//   }

//   // ============================================
//   // SYNC PINJAMAN
//   // ============================================
//   Future<int> syncPinjaman() async {
//     try {
//       final db = await dbService.database;
//       final serverData = await ApiService.getPinjaman();
//       print('📡 Server: ${serverData.length} pinjaman');

//       int savedCount = 0;
//       for (var item in serverData) {
//         final existing = await db.query(
//           'pinjaman',
//           where: 'id = ?',
//           whereArgs: [item['id']],
//         );

//         if (existing.isNotEmpty) {
//           // Update data yang sudah ada
//           await db.update(
//             'pinjaman',
//             {
//               'anggota_id': item['anggota_id'],
//               'jumlah': item['jumlah'],
//               'bunga': item['bunga'] ?? 12,
//               'tenor': item['tenor'],
//               'tanggal_pinjam': item['tanggal_pinjam'],
//               'status': item['status'] ?? 'aktif',
//               'denda_keterlambatan': item['denda_keterlambatan'] ?? 50000,
//               'sisa_pinjaman': item['sisa_pinjaman'] ?? item['jumlah'],
//               'updated_at': DateTime.now().toIso8601String(),
//             },
//             where: 'id = ?',
//             whereArgs: [item['id']],
//           );
//         } else {
//           // Insert data baru
//           await db.insert('pinjaman', {
//             'id': item['id'],
//             'anggota_id': item['anggota_id'],
//             'jumlah': item['jumlah'],
//             'bunga': item['bunga'] ?? 12,
//             'tenor': item['tenor'],
//             'tanggal_pinjam': item['tanggal_pinjam'],
//             'status': item['status'] ?? 'aktif',
//             'denda_keterlambatan': item['denda_keterlambatan'] ?? 50000,
//             'sisa_pinjaman': item['sisa_pinjaman'] ?? item['jumlah'],
//             'created_at': DateTime.now().toIso8601String(),
//             'updated_at': DateTime.now().toIso8601String(),
//           });
//           savedCount++;
//         }
//       }

//       print('✅ Pinjaman: $savedCount data baru disimpan');
//       return savedCount;
//     } catch (e) {
//       print('❌ Error sync pinjaman: $e');
//       return 0;
//     }
//   }

//   // ============================================
//   // SYNC ANGSURAN
//   // ============================================
//   Future<int> syncAngsuran() async {
//     try {
//       final db = await dbService.database;
//       final serverData = await ApiService.getAngsuran();
//       print('📡 Server: ${serverData.length} angsuran');

//       int savedCount = 0;
//       for (var item in serverData) {
//         final existing = await db.query(
//           'angsuran',
//           where: 'id = ?',
//           whereArgs: [item['id']],
//         );

//         if (existing.isNotEmpty) {
//           // Update data yang sudah ada
//           await db.update(
//             'angsuran',
//             {
//               'pinjaman_id': item['pinjaman_id'],
//               'angsuran_ke': item['angsuran_ke'],
//               'nominal': item['nominal'],
//               'denda': item['denda'] ?? 0,
//               'tanggal_jatuh_tempo': item['tanggal_jatuh_tempo'],
//               'tanggal_bayar': item['tanggal_bayar'],
//               'status': item['status'] ?? 'belum_bayar',
//             },
//             where: 'id = ?',
//             whereArgs: [item['id']],
//           );
//         } else {
//           // Insert data baru
//           await db.insert('angsuran', {
//             'id': item['id'],
//             'pinjaman_id': item['pinjaman_id'],
//             'angsuran_ke': item['angsuran_ke'],
//             'nominal': item['nominal'],
//             'denda': item['denda'] ?? 0,
//             'tanggal_jatuh_tempo': item['tanggal_jatuh_tempo'],
//             'tanggal_bayar': item['tanggal_bayar'],
//             'status': item['status'] ?? 'belum_bayar',
//             'created_at': DateTime.now().toIso8601String(),
//           });
//           savedCount++;
//         }
//       }

//       print('✅ Angsuran: $savedCount data baru disimpan');
//       return savedCount;
//     } catch (e) {
//       print('❌ Error sync angsuran: $e');
//       return 0;
//     }
//   }
// }