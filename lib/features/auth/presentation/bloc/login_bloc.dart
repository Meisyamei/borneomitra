import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;

  LoginBloc({required this.loginUseCase, required this.logoutUseCase})
    : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await loginUseCase.execute(event.username, event.password);
    result.fold(
      (failure) => emit(LoginError(failure.message)),
      (admin) => emit(LoginAuthenticated(admin)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    await logoutUseCase.execute();
    emit(LoginUnauthenticated());
  }
}
