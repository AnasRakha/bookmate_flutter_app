import 'package:cloud_firestore/cloud_firestore.dart';

class BookFirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ===================================================================
  //                            ADD DATA
  // ===================================================================

  /// Menambahkan buku ke Library
  static Future<void> addToLibrary(
    String? email,
    Map<String, dynamic> book,
  ) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot add book to library.");
    }

    try {
      await _db.collection("users").doc(email).collection("library").add(book);
    } catch (e) {
      throw Exception("Failed to add book to library: $e");
    }
  }

  /// Menambahkan buku ke Wishlist
  static Future<void> addToWishlist(
    String? email,
    Map<String, dynamic> book,
  ) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot add book to wishlist.");
    }

    try {
      await _db.collection("users").doc(email).collection("wishlist").add(book);
    } catch (e) {
      throw Exception("Failed to add book to wishlist: $e");
    }
  }

  // ===================================================================
  //                            SAVE/UPDATE DATA
  // ===================================================================

  /// Save/Update data buku pada Library
  /// [docId] adalah ID dokumen pada Firestore
  static Future<void> saveLibraryBookMerge(
    String? email,
    String docId,
    Map<String, dynamic> updatedBook,
  ) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty.");
    }

    await _db
        .collection("users")
        .doc(email)
        .collection("library")
        .doc(docId)
        .set(updatedBook, SetOptions(merge: true));
  }

  /// Save/Update data buku pada Wishlist
  static Future<void> saveWishlistBook(
    String? email,
    String docId,
    Map<String, dynamic> updatedBook,
  ) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot save wishlist book.");
    }

    try {
      await _db
          .collection("users")
          .doc(email)
          .collection("wishlist")
          .doc(docId)
          .update(updatedBook);
    } catch (e) {
      throw Exception("Failed to save/update wishlist book: $e");
    }
  }

  // ===================================================================
  //                          GET DATA (REALTIME)
  // ===================================================================

  /// Mengambil semua buku di Library (Realtime)
  static Stream<List<Map<String, dynamic>>> getLibrary(String? email) {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot fetch library.");
    }

    return _db
        .collection("users")
        .doc(email)
        .collection("library")
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (e) => {
                  ...e.data(),
                  "id": e.id, // tambahkan ID dokumen untuk update/delete
                },
              )
              .toList(),
        );
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getBookStream(
    String email,
    String docId, {
    bool isLibrary = true,
  }) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(email)
        .collection(isLibrary ? "library" : "wishlist")
        .doc(docId)
        .snapshots();
  }

  /// Mengambil semua buku di Wishlist (Realtime)
  static Stream<List<Map<String, dynamic>>> getWishlist(String? email) {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot fetch wishlist.");
    }

    return _db
        .collection("users")
        .doc(email)
        .collection("wishlist")
        .snapshots()
        .map(
          (snap) => snap.docs.map((e) => {...e.data(), "id": e.id}).toList(),
        );
  }

  // ===================================================================
  //                          DELETE DATA
  // ===================================================================

  /// Menghapus satu buku dari Library
  static Future<void> deleteLibraryBook(String? email, String docId) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot delete book.");
    }

    try {
      await _db
          .collection("users")
          .doc(email)
          .collection("library")
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete library book: $e");
    }
  }

  /// Menghapus satu buku dari Wishlist
  static Future<void> deleteWishlistBook(String? email, String docId) async {
    if (email == null || email.isEmpty) {
      throw Exception("Email is empty. Cannot delete wishlist book.");
    }

    try {
      await _db
          .collection("users")
          .doc(email)
          .collection("wishlist")
          .doc(docId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete wishlist book: $e");
    }
  }
}
