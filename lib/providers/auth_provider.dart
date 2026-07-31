import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider for the [AuthService] instance.
final authServiceProvider = Provider((ref) => AuthService());

/// Authentication state for the current user session.
///
/// Contains the user data (if signed in), loading state, and any
/// error messages from authentication attempts.
class AuthState {
  final bool isLoading;
  final ChompUser? user;
  final String? error;

  const AuthState({this.isLoading = false, this.user, this.error});

  /// Creates a copy of this state with optional field overrides.
  AuthState copyWith({bool? isLoading, ChompUser? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error,
      );

  /// Whether the user is currently signed in.
  bool get isSignedIn => user != null;
}

/// Manages authentication state and operations.
///
/// Handles sign in, sign out, and session restoration. Wraps
/// [AuthService] and exposes the state via Riverpod.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState());
  final AuthService _authService;

  /// Initiates GitHub OAuth sign in flow.
  ///
  /// Sets loading state, calls [AuthService.signInWithGitHub],
  /// and updates the state with the result or error.
  Future<void> signInWithGitHub() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithGitHub();
      state = state.copyWith(isLoading: false, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Signs the user out and clears the session.
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState();
  }

  /// Restores the user's session on app startup.
  ///
  /// Checks if a session token exists in secure storage. If not,
  /// resets to the signed-out state.
  ///
  /// Note: This doesn't repopulate the user object — add a GET /me
  /// endpoint on the backend if you need the profile to survive
  /// app restarts cleanly.
  Future<void> restoreSession() async {
    final signedIn = await _authService.isSignedIn();
    if (!signedIn) state = const AuthState();
  }
}

/// Provider for the current authentication state.
///
/// Use this to watch auth changes in the UI and trigger navigation
/// based on sign-in status.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
