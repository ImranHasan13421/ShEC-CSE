import 'package:equatable/equatable.dart';
import 'package:ShEC_CSE/features/profile/models/profile_state.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String batch;
  final String session;
  final String duReg;
  final String phone;
  final String? profilePic;
  final String universityId;
  final String classRoll;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.batch,
    required this.session,
    required this.duReg,
    required this.phone,
    this.profilePic,
    this.universityId = '',
    this.classRoll = '',
  });

  @override
  List<Object?> get props => [
        email,
        password,
        firstName,
        lastName,
        batch,
        session,
        duReg,
        phone,
        profilePic,
        universityId,
        classRoll,
      ];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final ProfileData profile;

  const AuthProfileUpdateRequested({required this.profile});

  @override
  List<Object?> get props => [profile];
}
