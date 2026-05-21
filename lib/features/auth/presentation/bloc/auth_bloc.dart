import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../backend/services/auth_service.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _client = Supabase.instance.client;

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final session = _client.auth.currentSession;
    if (session != null) {
      try {
        await AuthService.fetchCurrentUserProfile();
        final profile = currentProfile.value;
        if (profile.id.isNotEmpty) {
          emit(AuthAuthenticated(profile: profile));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await AuthService.signIn(email: event.email, password: event.password);
      await AuthService.fetchCurrentUserProfile();
      final profile = currentProfile.value;
      emit(AuthAuthenticated(profile: profile));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await AuthService.signUp(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        batch: event.batch,
        session: event.session,
        duReg: event.duReg,
        phone: event.phone,
        profilePic: event.profilePic,
        universityId: event.universityId,
        classRoll: event.classRoll,
      );
      emit(AuthUnauthenticated()); // Signup complete, usually waits for approval or login
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await AuthService.signOut();
      currentProfile.value = ProfileData(name: 'Guest', email: '', duRegNo: '', session: '');
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await AuthService.updateProfile(event.profile);
      final profile = currentProfile.value;
      emit(AuthAuthenticated(profile: profile));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      // Stay authenticated on error, but emit error state temporarily or restore authenticated state
      final profile = currentProfile.value;
      emit(AuthAuthenticated(profile: profile));
    }
  }
}
