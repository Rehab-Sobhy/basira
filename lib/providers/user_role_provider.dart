import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  unselected,
  blind,
  volunteer,
}

class UserRoleProvider with ChangeNotifier {
  static const String _roleKey = 'user_role_key';
  
  UserRole _role = UserRole.unselected;
  bool _isInitialized = false;

  UserRole get role => _role;
  bool get isInitialized => _isInitialized;
  
  bool get isBlind => _role == UserRole.blind;
  bool get isVolunteer => _role == UserRole.volunteer;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_roleKey);
    
    if (roleString == 'blind') {
      _role = UserRole.blind;
    } else if (roleString == 'volunteer') {
      _role = UserRole.volunteer;
    } else {
      _role = UserRole.unselected;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setRole(UserRole newRole) async {
    _role = newRole;
    final prefs = await SharedPreferences.getInstance();
    
    String roleString;
    switch (newRole) {
      case UserRole.blind:
        roleString = 'blind';
        break;
      case UserRole.volunteer:
        roleString = 'volunteer';
        break;
      case UserRole.unselected:
        roleString = 'unselected';
        break;
    }
    
    await prefs.setString(_roleKey, roleString);
    notifyListeners();
  }
}
