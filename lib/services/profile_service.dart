import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ProfileService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static const String _apiKey = "7c1628f427a51eba2a74255c1ee00b82";

  /// Compress image before upload
  static Future<File> compressImage(File file, {int quality = 80}) async {
    final bytes = await file.readAsBytes();

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception("Failed to decode image");
    }

    // Encode image to JPEG with given quality
    final compressedBytes = img.encodeJpg(image, quality: quality);

    // Create temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressedBytes);

    return tempFile;
  }

  /// Upload image to imgbb
  static Future<String> uploadToImgbb(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse("https://api.imgbb.com/1/upload?key=$_apiKey"),
      body: {"image": base64Image},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["success"] == true) {
      return data["data"]["url"];
    } else {
      throw Exception(
        "Upload image failed: ${data["error"]?["message"] ?? response.body}",
      );
    }
  }

  /// Compress + Upload image automatically
  static Future<String> compressAndUpload(
    File imageFile, {
    int quality = 70,
  }) async {
    File compressed = await compressImage(imageFile, quality: quality);
    return await uploadToImgbb(compressed);
  }

  /// Update profile Auth + Firestore (doc = email)
  static Future<void> updateProfile({
    required String username,
    File? photoFile, // Bisa langsung kirim file untuk compress + upload
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("User not logged in");
    }

    final email = user.email!;
    String? photoUrl;

    if (photoFile != null) {
      photoUrl = await compressAndUpload(photoFile, quality: 70);
    }

    // 1. Update Firebase Auth
    await user.updateDisplayName(username);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // 2. Update Firestore (merge, tidak menghapus subcollection)
    await _firestore.collection("users").doc(email).set({
      "email": email,
      "username": username,
      "photoUrl": photoUrl ?? user.photoURL,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.reload();
  }
}
