import 'package:flutter/material.dart';
import 'package:aurora/users/account_type.dart';

class AuthState {
  final String? uuid;
  final AccountType? accountType;
  final String? email;
  final String? name;
  final bool isAuthenticated;

  AuthState({
    this.uuid,
    this.accountType,
    this.email,
    this.name,
    this.isAuthenticated = false,
  });

  factory AuthState.authenticated({
    required String uuid,
    required AccountType accountType,
    String? email,
    String? name,
  }) {
    return AuthState(
      uuid: uuid,
      accountType: accountType,
      email: email,
      name: name,
      isAuthenticated: true,
    );
  }

  factory AuthState.unauthenticated() {
    return AuthState(isAuthenticated: false);
  }

  bool get isSeller => accountType == AccountType.seller;
  bool get isFactory => accountType == AccountType.factory;
  bool get isCustomer => accountType == AccountType.customser;
  bool get isMiddleman => accountType == AccountType.middleman;

  AuthState copyWith({
    String? uuid,
    AccountType? accountType,
    String? email,
    String? name,
    bool? isAuthenticated,
  }) {
    return AuthState(
      uuid: uuid ?? this.uuid,
      accountType: accountType ?? this.accountType,
      email: email ?? this.email,
      name: name ?? this.name,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthStateProvider extends ChangeNotifier {
  AuthState _authState = AuthState.unauthenticated();

  AuthState get authState => _authState;
  
  String? get uuid => _authState.uuid;
  AccountType? get accountType => _authState.accountType;
  bool get isAuthenticated => _authState.isAuthenticated;
  bool get isSeller => _authState.isSeller;
  bool get isFactory => _authState.isFactory;
  bool get isCustomer => _authState.isCustomer;

  void setAuthenticated({
    required String uuid,
    required AccountType accountType,
    String? email,
    String? name,
  }) {
    _authState = AuthState.authenticated(
      uuid: uuid,
      accountType: accountType,
      email: email,
      name: name,
    );
    notifyListeners();
  }

  void setUnauthenticated() {
    _authState = AuthState.unauthenticated();
    notifyListeners();
  }

  void updateProfile({String? name, String? email}) {
    if (_authState.isAuthenticated) {
      _authState = _authState.copyWith(
        name: name ?? _authState.name,
        email: email ?? _authState.email,
      );
      notifyListeners();
    }
  }
}