import 'package:flutter/material.dart';
import 'package:BookMate/pages/book/detail_page.dart';
import 'package:BookMate/services/book_firestore_service.dart';
import 'package:BookMate/pages/book/add_book_page.dart';

class HomeLibrary extends StatelessWidget {
  final String? email;

  const HomeLibrary({super.key, this.email});

  bool get isGuest => email == null || email!.isEmpty;

  // Normalisasi URL
  String? normalizeImgbbUrl(String? url) {
    if (url == null) return null;

    if (url.startsWith("https://i.ibb.co/")) {
      return url.replaceFirst("https://i.ibb.co/", "https://i.ibb.co.com/");
    }

    return url;
  }

  // ========================= BOOK LIST ===========================
  Widget buildBookList(List<Map<String, dynamic>> books, BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text("No books found", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.45,
      ),
      itemCount: books.length,
      itemBuilder: (_, index) {
        final book = books[index];
        final info = book["volumeInfo"];
        final title = info["title"] ?? "No Title";
        final authors = (info["authors"] ?? []).join(', ');
        final thumbnailUrl = info['imageLinks']?['thumbnail'] as String?;
        final fixedPhotoUrl = normalizeImgbbUrl(thumbnailUrl);

        return GestureDetector(
          onTap: () {
            // Cek apakah ini tab Library (index 0) atau Wishlist (index 1)
            final isLibraryTab = DefaultTabController.of(context).index == 0;

            if (isLibraryTab) {
              // Dari Library → buka LibraryDetailPage
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    book: book,
                    email: email!,
                    docId: book["id"], // dari Firestore
                    fromLibrary: true, // <— tambah flag
                  ),
                ),
              );
            } else {
              // Dari Wishlist → buka DetailPage versi wishlist (tanpa tombol wishlist)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(
                    book: book,
                    email: email!,
                    fromWishlist: true, // <— tambah flag
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.65, // semakin kecil → makin tinggi kotak
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: fixedPhotoUrl != null
                      ? Image.network(fixedPhotoUrl, fit: BoxFit.cover)
                      : _noImagePlaceholder(),
                ),
              ),

              SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              if (authors.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  "By: $authors",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ========================= STREAM WRAPPER ===========================
  Widget buildBookStream(
    Stream<List<Map<String, dynamic>>> stream,
    BuildContext context,
  ) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        return buildBookList(snapshot.data ?? [], context);
      },
    );
  }

  // ========================= GUEST DIALOG ===========================
  void showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.all(20),
          title: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.brown[300],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.brown[700], size: 28),
                SizedBox(width: 10),
                Text(
                  "Login Required",
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            "Please login first to add a book to your library.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(
                  color: Colors.brown[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _noImagePlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 40,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  // ========================= BUILD UI ===========================
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.grey[100],
          centerTitle: true,
          elevation: 0,
          title: Text(
            "Bookshelf",
            style: TextStyle(fontSize: 24, color: Colors.brown),
          ),
          bottom: TabBar(
            labelColor: Colors.brown,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.brown[700],
            tabs: [
              Tab(text: "My Library"),
              Tab(text: "My Wishlist"),
            ],
          ),
        ),
        backgroundColor: Colors.grey[100],
        body: isGuest
            ? Center(
                child: Text(
                  "Please login to access your library and wishlist.",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
            : TabBarView(
                children: [
                  buildBookStream(
                    BookFirestoreService.getLibrary(email!),
                    context,
                  ),
                  buildBookStream(
                    BookFirestoreService.getWishlist(email!),
                    context,
                  ),
                ],
              ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.brown[300],
          foregroundColor: Colors.brown[700],
          onPressed: () {
            if (isGuest) {
              showGuestDialog(context);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddBookPage(email: email!),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
