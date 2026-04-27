import 'UserModel.dart';

/// A singleton that holds the currently logged-in user.
/// Access it anywhere via UserSession.instance.
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  /// Call this after a successful login.
  void setUser(UserModel user) {
    _currentUser = user;
  }

  void updateProfilePicture(String url) {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      profilePicture: url,
      savedAddresses: _currentUser!.savedAddresses,
      avatarEmoji: _currentUser!.avatarEmoji,
    );
  }

  /// Call this on logout.
  void clearUser() {
    _currentUser = null;
  }

  /// Convenience getters
  String get displayName => _currentUser?.name ?? 'Guest';
  String get displayEmail => _currentUser?.email ?? '';
  String get firstName => _currentUser?.firstName ?? 'there';
  int get orderCount => _currentUser?.orderCount ?? 0;
  int get favouriteCount => _currentUser?.favouriteCount ?? 0;
  int get points => _currentUser?.points ?? 0;
}
