import 'package:equatable/equatable.dart';
import '../../domain/entities/admin.dart';

abstract class LoginState extends Equatable {
  const LoginState();
  
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginAuthenticated extends LoginState {
  final Admin admin;
  
  const LoginAuthenticated(this.admin);
  
  @override
  List<Object> get props => [admin];
}

class LoginUnauthenticated extends LoginState {}

class LoginError extends LoginState {
  final String message;
  
  const LoginError(this.message);
  
  @override
  List<Object> get props => [message];
}