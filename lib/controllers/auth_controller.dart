import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthController() {
    _init();
  }

  void _init() {
    // Listen to auth state changes from Supabase
    _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        await _fetchUserProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });

    // Check existing session on startup
    final existingSession = _supabase.auth.currentSession;
    if (existingSession != null) {
      _fetchUserProfile(existingSession.user.id);
    } else {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromMap(response);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to load profile: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  /// Login with email & password
  Future<bool> login({required String email, required String password}) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned.');
      }

      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
    // Di auth_controller.dart, tambahkan method ini untuk testing
  Future<bool> loginDummy({required String role}) async {
    _status = AuthStatus.loading;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // simulasi network

    _currentUser = UserModel(
      id: 'dummy-id',
      name: 'Test User',
      email: 'test@test.com',
      role: role, // 'customer' atau 'driver'
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }

  /// Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}