// import 'package:ecommunity/models/user_model.dart'; // Import your User model
// import 'package:shared_preferences/shared_preferences.dart';
//
// class SessionManager {
//   // The Singleton pattern: A single instance of this class throughout the app
//   static final SessionManager _instance = SessionManager._internal();
//   factory SessionManager() {
//     return _instance;
//   }
//   SessionManager._internal();
//
//   User? currentUser; // This will hold the logged-in user's data
//   static const String _userKey = 'currentUser';
//   Future<void> loadUserFromPreferences() async {
//     final prefs = await SharedPreferences.getInstance();
//     final String? userJson = prefs.getString(_userKey);
//
//     if (userJson != null) {
//       try {
//         // If we found a user string, convert it back from JSON to a User object
//         currentUser = User.fromJson(userJson);
//         print("User loaded from storage: ${currentUser!.name}");
//       } catch (e) {
//         print("Error decoding user from json: $e");
//         // If there's an error (e.g., you changed the User model), log them out
//         await logout();
//       }
//     }
//   }
//
//   // --- MODIFIED: Login now saves to local storage ---
//   Future<void> login(User user) async {
//     currentUser = user;
//     final prefs = await SharedPreferences.getInstance();
//     // Convert the User object to a JSON string and save it
//     await prefs.setString(_userKey, user.toJson());
//     print("User logged in and session saved: ${user.name}");
//   }
//
//   // --- MODIFIED: Logout now clears local storage ---
//   Future<void> logout() async {
//     currentUser = null;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_userKey); // Remove the user data from storage
//     print("User logged out and session cleared.");
//   }
//
//
//   bool isLoggedIn() {
//     return currentUser != null;
//   }
//
//   String? getCurrentUserId() {
//     return currentUser?.id;
//   }
// }
