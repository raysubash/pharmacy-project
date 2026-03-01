import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Create a simple Auth State class
class AuthState {
  final bool isLoading;
  final String? token;
  final String? userName;
  final String? role; // Added role
  final String? error;

  AuthState({
    this.isLoading = false,
    this.token,
    this.userName,
    this.role,
    this.error,
  });

  bool get isAuthenticated => token != null;
  bool get isAdmin => role == 'admin';

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? userName,
    String? role,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  static const String _baseUrl =
      'https://pharmacy-project-wkdo.onrender.com/api/auth'; // Use live server URL

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // Add local bypass for demo/offline logic if desired
    // For now, let's try network first, then check local if needed (not fully implemented yet)

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);

          String? userName;
          String? role;
          if (data['user'] != null) {
            userName = data['user']['name'];
            role = data['user']['role'];
            await prefs.setString('userName', userName ?? '');
            await prefs.setString('role', role ?? 'pharmacist');
          }

          state = AuthState(
            isLoading: false,
            token: token,
            userName: userName,
            role: role,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Token missing in response',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', 'guest_token');
    await prefs.setString('userName', 'Pharmacist (Offline)');
    await prefs.setString('role', 'pharmacist');

    state = AuthState(
      isLoading: false,
      token: 'guest_token',
      userName: 'Pharmacist (Offline)',
      role: 'pharmacist',
    );
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Automatically login or just stop loading
        state = state.copyWith(isLoading: false);
        // We can optionally login here directly if the backend returns a token on signup
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);

          String? userName;
          if (data['user'] != null && data['user']['name'] != null) {
            userName = data['user']['name'];
            await prefs.setString('userName', userName!);
          }

          state = state.copyWith(token: data['token'], userName: userName);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] ?? 'Signup failed',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    state = AuthState();
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userName = prefs.getString('userName');
    final role = prefs.getString('role');
    if (token != null) {
      state = state.copyWith(token: token, userName: userName, role: role);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
