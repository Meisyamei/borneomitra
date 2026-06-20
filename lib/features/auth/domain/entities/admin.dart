import 'package:equatable/equatable.dart';

class Admin extends Equatable {
  final int? id;
  final String username;
  final String namaLengkap;
  final DateTime createdAt;
  
  const Admin({
    this.id,
    required this.username,
    required this.namaLengkap,
    required this.createdAt,
  });
  
  @override
  List<Object?> get props => [id, username, namaLengkap];
}