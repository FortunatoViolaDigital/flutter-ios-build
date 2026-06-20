import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.onAuthState;
});

final currentUserProvider = Provider((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.user;
});
