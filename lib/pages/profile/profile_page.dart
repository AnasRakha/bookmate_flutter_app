import 'package:BookMate/pages/profile/edit_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:BookMate/pages/home/home_page.dart';
import 'package:BookMate/services/auth_service.dart';
import 'package:BookMate/pages/auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  final String? email;

  const ProfilePage({this.email});

  String? normalizeImgbbUrl(String? url) {
    if (url == null) return null;

    if (url.startsWith("https://i.ibb.co/")) {
      return url.replaceFirst("https://i.ibb.co/", "https://i.ibb.co.com/");
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? "User";
    final fixedPhotoUrl = normalizeImgbbUrl(user?.photoURL);

    bool isLoggedIn = email != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text(
          isLoggedIn ? "Profile" : "Profile",
          style: TextStyle(
            fontSize: 24,
            // fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),

            // Avatar
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.brown.shade300, width: 1),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.brown[400],
                backgroundImage: fixedPhotoUrl != null
                    ? NetworkImage(fixedPhotoUrl)
                    : null,
                child: fixedPhotoUrl == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),

            SizedBox(height: 18),

            // Email
            Column(
              children: [
                // Username
                Text(
                  isLoggedIn ? username : "Guest User",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[900],
                  ),
                ),
                SizedBox(height: 6),

                // Email
                Text(
                  isLoggedIn ? email! : "Please log in to access your profile.",
                  style: TextStyle(fontSize: 16, color: Colors.brown[700]),
                ),
              ],
            ),

            SizedBox(height: 35),

            if (isLoggedIn) ...[
              // Tombol Edit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.edit, color: Colors.white),
                  label: Text(
                    "Edit Profile",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );

                    if (result == true) {
                      // trigger rebuild
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              SizedBox(height: 20),

              // Tombol Logout
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    "Logout",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await AuthService().logout();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                ),
              ),
            ],

            // Tampilan Jika Tidak Login
            if (!isLoggedIn) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
