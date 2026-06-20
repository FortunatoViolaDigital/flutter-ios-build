class Wallet {
  final String id;
  final double balance;
  final double tutorialLocked;

  Wallet(
      {required this.id, required this.balance, required this.tutorialLocked});

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
        id: m['id'],
        balance: double.tryParse(m['balance'].toString()) ?? 0,
        tutorialLocked: double.tryParse(m['tutorial_locked'].toString()) ?? 0,
      );
}
