// import 'package:BookMate/pages/book/edit_book_page.dart';
import 'package:flutter/material.dart';
import 'package:BookMate/services/book_firestore_service.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final String email;

  // Jika berasal dari Library → wajib mengirim docId
  final bool fromLibrary;
  final bool fromWishlist;
  final String? docId;

  const DetailPage({
    super.key,
    required this.book,
    required this.email,
    this.fromLibrary = false,
    this.fromWishlist = false,
    this.docId,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  // Library attributes
  late double pagesRead;
  late int totalPages;
  late TextEditingController pagesController;
  DateTime? startDate;
  DateTime? finishDate;

  @override
  void initState() {
    super.initState();

    final info = widget.book["volumeInfo"];
    totalPages = info["pageCount"] ?? 0;

    if (widget.fromLibrary) {
      pagesRead = (widget.book["pagesRead"] ?? 0).toDouble();
      pagesController = TextEditingController(
        text: pagesRead.toInt().toString(),
      );

      if (widget.book["startDate"] != null) {
        startDate = DateTime.tryParse(widget.book["startDate"]);
      }
      if (widget.book["finishDate"] != null) {
        finishDate = DateTime.tryParse(widget.book["finishDate"]);
      }
    } else {
      pagesRead = 0;
      pagesController = TextEditingController(text: "0");
    }
  }

  @override
  void dispose() {
    pagesController.dispose();
    super.dispose();
  }

  // LOGIN POPUP
  void showLoginPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        content: const Text("You must login first to use this feature."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: Colors.brown)),
          ),
        ],
      ),
    );
  }

  // -------------------
  // FUNGSI SAVE PROGRESS
  // -------------------
  Future<void> saveProgress() async {
    if (!widget.fromLibrary || widget.docId == null) return;

    double progress = totalPages == 0 ? 0 : (pagesRead / totalPages * 100);

    Map<String, dynamic> updatedData = {
      "pagesRead": pagesRead.toInt(),
      "startDate": startDate?.toIso8601String(),
      "finishDate": finishDate?.toIso8601String(),
      "progress": progress,
    };

    await BookFirestoreService.saveLibraryBookMerge(
      widget.email,
      widget.docId!,
      updatedData,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Progress saved!",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[300],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(14),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // -------------------
  // FUNGSI DELETE BOOK
  // -------------------
  Future<void> deleteBook() async {
    if (!widget.fromLibrary || widget.docId == null) return;

    await BookFirestoreService.deleteLibraryBook(widget.email, widget.docId!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Book removed",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red[300],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(14),
        ),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  void showDeleteConfirmation() {
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
                Icon(Icons.delete_outline, color: Colors.brown[700], size: 28),
                SizedBox(width: 10),
                Text(
                  "Delete Book",
                  style: TextStyle(
                    color: Colors.brown[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          content: Text(
            "Are you sure you want to delete this from library?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                deleteBook();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // DATE PICKERS
  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickFinishDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: finishDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => finishDate = picked);
  }

  // DATE WIDGET
  Widget datePickerCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(
                  date == null
                      ? "Select date"
                      : date.toIso8601String().substring(0, 10),
                ),
                Spacer(),
                Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Normalisasi URL
  String? normalizeImgbbUrl(String? url) {
    if (url == null) return null;

    if (url.startsWith("https://i.ibb.co/")) {
      return url.replaceFirst("https://i.ibb.co/", "https://i.ibb.co.com/");
    }

    return url;
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.book['volumeInfo'];
    final title = info['title'] ?? 'No Title';
    final authors = (info['authors'] ?? []).join(', ');
    final description = info['description'] ?? 'No Description';
    final publisher = info['publisher'] ?? 'Unknown Publisher';
    final publishedDate = info['publishedDate'] ?? 'Unknown Date';
    final thumbnailUrl = info['imageLinks']?['thumbnail'] as String?;
    final fixedPhotoUrl = normalizeImgbbUrl(thumbnailUrl);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text("Detail Book", style: TextStyle(color: Colors.brown[700])),
        iconTheme: IconThemeData(color: Colors.brown[700]),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COVER + TEXT
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Thumbnail Buku ---
                Container(
                  width: 110,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: fixedPhotoUrl != null
                        ? Image.network(fixedPhotoUrl, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade300),
                  ),
                ),

                SizedBox(width: 15),

                // --- Info Buku ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Buku
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Tombol Edit
                          // if (widget.fromLibrary || widget.fromWishlist)
                          //   IconButton(
                          //     icon: Icon(Icons.edit, color: Colors.brown[700]),
                          //     onPressed: () async {
                          //       final updated = await Navigator.push(
                          //         context,
                          //         MaterialPageRoute(
                          //           builder: (_) => EditBookPage(
                          //             email: widget.email,
                          //             docId: widget.docId!,
                          //             book: widget.book,
                          //           ),
                          //         ),
                          //       );

                          //       if (updated == true) {
                          //         setState(() {});
                          //       }
                          //     },
                          //   ),
                        ],
                      ),

                      SizedBox(height: 6),

                      // Penulis
                      Text(authors, style: TextStyle(color: Colors.grey[700])),

                      // Publisher
                      Text(
                        publisher,
                        style: TextStyle(color: Colors.grey[700]),
                      ),

                      // Tanggal terbit
                      Text(
                        publishedDate,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // ====================================================
            // UPDATE PROGRESS BACA $ TOMBOL DELETE
            // ====================================================
            if (widget.fromLibrary) ...[
              Text("Pages read"),
              Row(
                children: [
                  // Slider
                  Expanded(
                    child: Slider(
                      min: 0,
                      max: totalPages.toDouble(),
                      value: pagesRead,
                      activeColor: Colors.brown,
                      onChanged: (val) {
                        setState(() {
                          pagesRead = val;
                          pagesController.text = val.toInt().toString();
                        });
                      },
                    ),
                  ),
                  // Manual Input
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: pagesController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        int? v = int.tryParse(value);
                        if (v == null) return;
                        if (v < 0) v = 0;
                        if (v > totalPages) v = totalPages;
                        setState(() {
                          pagesRead = v!.toDouble();
                        });
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  Text("/ $totalPages"),
                ],
              ),

              SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: datePickerCard(
                      label: "Started Reading",
                      date: startDate,
                      onTap: pickStartDate,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: datePickerCard(
                      label: "Finished Reading",
                      date: finishDate,
                      onTap: pickFinishDate,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveProgress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[300],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "SAVE",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showDeleteConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "DELETE FROM LIBRARY",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],

            // ====================================================
            // TOMBOL ADD TO LIBRARY $ ADD TO WISHLIST
            // ====================================================
            if (!widget.fromLibrary) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: Icon(Icons.library_add),
                      label: Text(
                        widget.fromWishlist
                            ? "Moved to Library"
                            : "Added to Library",
                      ),
                      onPressed: () async {
                        if (widget.email.isEmpty) {
                          showLoginPopup();
                          return;
                        }
                        await BookFirestoreService.addToLibrary(
                          widget.email,
                          widget.book,
                        );
                        if (widget.fromWishlist && widget.book['id'] != null) {
                          await BookFirestoreService.deleteWishlistBook(
                            widget.email,
                            widget.book['id'],
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              widget.fromWishlist
                                  ? "Moved to Library"
                                  : "Added to Library",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: Colors.blue[300],
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 25,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(14),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!widget.fromWishlist) SizedBox(width: 12),
                  if (!widget.fromWishlist)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(Icons.favorite_border),
                        label: Text("Add to Wishlist"),
                        onPressed: () async {
                          if (widget.email.isEmpty) {
                            showLoginPopup();
                            return;
                          }
                          await BookFirestoreService.addToWishlist(
                            widget.email,
                            widget.book,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Added to Wishlist",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: Colors.green[300],
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 25,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(14),
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],

            SizedBox(height: 30),

            // DESCRIPTION
            Text(
              "Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(description, textAlign: TextAlign.justify),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
