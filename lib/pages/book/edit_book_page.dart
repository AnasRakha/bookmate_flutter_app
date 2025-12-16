import 'package:flutter/material.dart';
import 'package:BookMate/services/book_firestore_service.dart';

class EditBookPage extends StatefulWidget {
  final String email;
  final String docId; // id dokumen di Library
  final Map<String, dynamic> book;

  const EditBookPage({
    super.key,
    required this.email,
    required this.docId,
    required this.book,
  });

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController publisherController;
  late TextEditingController publishedDateController;
  late TextEditingController pageCountController;
  late TextEditingController descriptionController;
  late TextEditingController imageUrlController;

  @override
  void initState() {
    super.initState();
    final info = widget.book["volumeInfo"];

    titleController = TextEditingController(text: info["title"] ?? "");
    authorController = TextEditingController(
      text: (info["authors"] ?? []).join(", "),
    );
    publisherController = TextEditingController(text: info["publisher"] ?? "");
    publishedDateController = TextEditingController(
      text: info["publishedDate"] ?? "",
    );
    pageCountController = TextEditingController(
      text: info["pageCount"]?.toString() ?? "",
    );
    descriptionController = TextEditingController(
      text: info["description"] ?? "",
    );
    imageUrlController = TextEditingController(
      text: info["imageLinks"]?["thumbnail"] ?? "",
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    publisherController.dispose();
    publishedDateController.dispose();
    pageCountController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    final updatedInfo = {
      "volumeInfo": {
        "title": titleController.text,
        "authors": authorController.text
            .split(",")
            .map((e) => e.trim())
            .toList(),
        "publisher": publisherController.text,
        "publishedDate": publishedDateController.text,
        "pageCount": int.tryParse(pageCountController.text) ?? 0,
        "description": descriptionController.text,
        "imageLinks": {"thumbnail": imageUrlController.text},
      },
    };

    await BookFirestoreService.saveLibraryBookMerge(
      widget.email,
      widget.docId,
      updatedInfo,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue[300],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: Duration(seconds: 2),
        content: Text(
          "Book updated successfully",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );

    Navigator.pop(context, true); // kembali dan refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.brown,
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Edit Book",
          style: TextStyle(fontSize: 24, color: Colors.brown),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Preview Gambar
              Container(
                width: 130,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.broken_image),
                  ),
                ),
              ),
              SizedBox(height: 15),

              _buildField("Title", titleController),
              _buildField("Author(s) — separated by comma", authorController),
              _buildField("Publisher", publisherController),
              _buildField("Published Date", publishedDateController),
              _buildField(
                "Page Count",
                pageCountController,
                keyboard: TextInputType.number,
              ),
              _buildField("Image URL", imageUrlController),
              _buildField("Description", descriptionController, maxLines: 6),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.brown),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
