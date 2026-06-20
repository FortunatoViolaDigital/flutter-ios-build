import '../models/wallet.dart';
import 'supabase_client.dart';

class WalletService {
  Future<Wallet> getMyWallet() async {
    final uid = supa.auth.currentUser!.id;
    final res = await supa.from('wallets').select().eq('id', uid).single();
    return Wallet.fromMap(res);
  }

  Future<void> awardTutorialCredit() async {
    await supa.rpc('award_tutorial_credit');
  }
}
