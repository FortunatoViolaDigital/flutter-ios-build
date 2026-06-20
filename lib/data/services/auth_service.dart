import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AuthService {
  Future<AuthResponse> signUp(
      {required String email, required String password}) async {
    // If you want email confirmation, add emailRedirectTo
    return await supa.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(
      {required String email, required String password}) {
    return supa.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supa.auth.signOut();

  Stream<AuthState> get onAuthState => supa.auth.onAuthStateChange;
  Session? get session => supa.auth.currentSession;
  User? get user => supa.auth.currentUser;
}
