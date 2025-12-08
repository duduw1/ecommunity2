import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/user_model.dart'; // Make sure to import your User model

class UserRepository {
  // Get a reference to the 'users' collection
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  /// CREATE: Adds a new user document to Firestore.
  /// The user object's 'id' will be ignored as Firestore generates a new one.
  Future<void> addUser(User user) async {
    try {
      // Use AWAIT to wait for the operation to complete.
      await _usersCollection.doc(user.id).set(user.toMap());
      print("User data successfully added to Firestore.");
    } catch (e) {
      print("Error adding user to Firestore: $e");
      // Re-throw the error so the UI's catch block can handle it
      throw e;
    }
  }


  /// READ: Fetches a single user by their document ID.
  /// Returns a User object if found, otherwise returns null.
  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      if (docSnapshot.exists) {
        // Use the factory constructor to create a User object from the snapshot
        return User.fromFirestore(docSnapshot);
      }
      return null; // Document does not exist
    } on FirebaseException catch (e) {
      print("Firebase Error getting user by ID: ${e.message}");
      return null;
    }
  }

  /// READ: Fetches a single user by their email.
  /// This is useful for checking if an email already exists or for logging in.
  /// Returns a User object if found, otherwise returns null.
  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // The user exists, convert the first document to a User object
        return User.fromFirestore(querySnapshot.docs.first);
      }
      return null; // No user found with that email
    } on FirebaseException catch (e) {
      print("Firebase Error getting user by email: ${e.message}");
      return null;
    }
  }

  /// UPDATE: Updates an existing user document in Firestore.
  /// The user object must have a valid 'id'.
  Future<void> updateUser(User user) async {
    await _usersCollection.doc(user.id).update(user.toMap());
  }

  /// DELETE: Deletes a user document from Firestore using its ID.
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}
