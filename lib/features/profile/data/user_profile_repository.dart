import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_fitness/features/profile/domain/user_profile.dart';

class UserProfileRepository {
  static const _key = 'user_profile_json';

  Future<UserProfile?> load() async {
    final sp = await SharedPreferences.getInstance();
    final json = sp.getString(_key);
    if (json == null || json.isEmpty) return null;
    try {
      return UserProfile.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserProfile profile) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, profile.toJson());
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
