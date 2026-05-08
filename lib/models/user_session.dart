import 'UserModel.dart';

// Keeps track of who is currently logged in — like a "current user" holder
class UserSession {
  UserSession._();
  static final UserSession instance = UserSession._();

  UserModel? _currentUser;
  String _token = '';
  String _refreshToken = '';
  String _selectedDeliveryAddress = '';

  UserModel? get currentUser => _currentUser;
  String get token => _token;
  String get refreshToken => _refreshToken;

  // True if someone is logged in, false if not
  bool get isLoggedIn => _currentUser != null;

  // The address the user has chosen for delivery
  String get selectedDeliveryAddress {
    if (_selectedDeliveryAddress.isNotEmpty) return _selectedDeliveryAddress;
    // Use the first saved address if none is selected
    if (_currentUser != null && _currentUser!.savedAddresses.isNotEmpty) {
      return _currentUser!.savedAddresses.first;
    }
    return '';
  }

  // Saves the chosen delivery address
  void setSelectedDeliveryAddress(String address) {
    _selectedDeliveryAddress = address;
  }

  // Saves the logged-in user and picks their first address automatically
  void setUser(UserModel user) {
    _currentUser = user;
    // Auto-select first address on login
    if (user.savedAddresses.isNotEmpty && _selectedDeliveryAddress.isEmpty) {
      _selectedDeliveryAddress = user.savedAddresses.first;
    }
  }

  // Saves the login token
  void setToken(String token) {
    _token = token;
  }

  // Saves the refresh token
  void setRefreshToken(String token) {
    _refreshToken = token;
  }

  // Updates the user's profile picture with a new image URL
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

  // Adds a new address to the user's saved list if it's not already there
  void addSavedAddress(String address) {
    if (_currentUser == null) return;
    final updated = List<String>.from(_currentUser!.savedAddresses);
    if (!updated.contains(address)) {
      updated.add(address);
    }
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      profilePicture: _currentUser!.profilePicture,
      savedAddresses: updated,
      avatarEmoji: _currentUser!.avatarEmoji,
    );
  }

  // Removes an address from the user's saved list
  void removeSavedAddress(String address) {
    if (_currentUser == null) return;
    final updated = List<String>.from(_currentUser!.savedAddresses)
      ..remove(address);
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: _currentUser!.phone,
      profilePicture: _currentUser!.profilePicture,
      savedAddresses: updated,
      avatarEmoji: _currentUser!.avatarEmoji,
    );
    // If the removed address was selected, switch to the next one or clear it
    if (_selectedDeliveryAddress == address) {
      _selectedDeliveryAddress = updated.isNotEmpty ? updated.first : '';
    }
  }

  // Logs the user out and clears everything
  void clearUser() {
    _currentUser = null;
    _token = '';
    _refreshToken = '';
    _selectedDeliveryAddress = '';
  }

  String get displayName => _currentUser?.name ?? 'Guest';
  String get displayEmail => _currentUser?.email ?? '';
  String get firstName => _currentUser?.firstName ?? 'there';
  int get orderCount => _currentUser?.orderCount ?? 0;
  int get favouriteCount => _currentUser?.favouriteCount ?? 0;
  int get points => _currentUser?.points ?? 0;
}
