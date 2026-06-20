import '../models/profile.dart';
import 'supabase_client.dart';
import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

class ProfileService {
  Future<Profile?> getMe() async {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) return null;
    final res = await supa.from('profiles').select().eq('id', uid).single();
    return Profile.fromMap(res);
  }

  Future<void> update(Profile p) async {
    await supa.from('profiles').update(p.toUpdate()).eq('id', p.id);
  }

  Future<void> setInvitedBy(String inviterRefCode) async {
    final uid = supa.auth.currentUser!.id;
    // Basic sanity: don't set your own code, and ensure exists
    final exists = await supa
        .from('profiles')
        .select('id')
        .eq('referral_code', inviterRefCode)
        .maybeSingle();
    if (exists != null && exists['id'] != uid) {
      await supa
          .from('profiles')
          .update({'invited_by': inviterRefCode}).eq('id', uid);
    }
  }

  Future<String> uploadAvatar(File image) async {
    final user = supa.auth.currentUser;
    if (user == null) throw Exception('Utente non loggato');

    final fileExt = path.extension(image.path);
    final fileName = 'avatars/${user.id}$fileExt';
    final fileBytes = await image.readAsBytes();
    final mimeType = lookupMimeType(image.path);

    final response = await supa.storage.from('avatars').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: true,
          ),
        );

    final url = supa.storage.from('avatars').getPublicUrl(fileName);
    return url;
  }
}
