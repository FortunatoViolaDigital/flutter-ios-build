class Profile {
  final String id;
  final String? email;
  final String? fullName;
  final String? avatarUrl;
  final bool anonymousMode;
  final String? referralCode;
  final String? invitedBy;
  final bool tutorialAwarded;

  final int xp; // 🆕 XP totale dell’utente
  final int level; // 🆕 Livello attuale

  Profile({
    required this.id,
    this.email,
    this.fullName,
    this.avatarUrl,
    this.anonymousMode = false,
    this.referralCode,
    this.invitedBy,
    this.tutorialAwarded = false,
    this.xp = 0,
    this.level = 1,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'],
        email: m['email'],
        fullName: m['full_name'],
        avatarUrl: m['avatar_url'],
        anonymousMode: m['anonymous_mode'] ?? false,
        referralCode: m['referral_code'],
        invitedBy: m['invited_by'],
        tutorialAwarded: m['tutorial_awarded'] ?? false,
        xp: m['xp'] ?? 0,
        level: m['level'] ?? 1,
      );

  Map<String, dynamic> toUpdate() => {
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'anonymous_mode': anonymousMode,
        'invited_by': invitedBy,
      }..removeWhere((k, v) => v == null);
}
