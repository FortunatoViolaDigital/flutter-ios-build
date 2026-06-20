import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/wallet_service.dart';
import '../../../data/models/wallet.dart';

final walletServiceProvider = Provider((ref) => WalletService());

final walletProvider = FutureProvider<Wallet>((ref) async {
  final service = ref.watch(walletServiceProvider);
  return await service.getMyWallet();
});
