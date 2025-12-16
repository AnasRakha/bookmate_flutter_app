import 'package:flutter/material.dart';
import 'package:BookMate/services/book_firestore_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:BookMate/services/profile_service.dart';
import 'package:BookMate/services/url_helper.dart';

class AddBookPage extends StatefulWidget {
  final String email;
  const AddBookPage({super.key, required this.email});

  @override
  _AddBookPageState createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController publisherController = TextEditingController();
  final TextEditingController publishedDateController = TextEditingController();
  final TextEditingController pageCountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  File? _bookImage;
  bool _isUploadingImage = false;

  String _saveTo = 'library';
  bool _isSaving = false;

  Future<void> saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final bookData = {
      "volumeInfo": {
        "title": titleController.text.trim(),
        "authors": [authorController.text.trim()],
        "publisher": publisherController.text.trim(),
        "publishedDate": publishedDateController.text.trim(),
        "pageCount":
            int.tryParse(pageCountController.text.trim()) ??
            0, // default ke 0 jika tidak valid
        "description": descriptionController.text.trim(),
        "imageLinks": imageUrlController.text.isNotEmpty
            ? {"thumbnail": imageUrlController.text.trim()}
            : null,
      },
    };

    try {
      if (_saveTo == 'library') {
        await BookFirestoreService.addToLibrary(widget.email, bookData);
      } else {
        await BookFirestoreService.addToWishlist(widget.email, bookData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _saveTo == 'library'
                ? Colors.blue[300]
                : Colors.green[300],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusGeometry.circular(14),
            ),
            content: Text(
              'Added to ${_saveTo == 'library' ? 'Library' : 'Wishlist'}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save book: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    setState(() {
      _bookImage = File(picked.path);
      _isUploadingImage = true;
    });

    try {
      final url = await ProfileService.uploadToImgbb(_bookImage!);

      imageUrlController.text = url;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image uploaded successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to upload image")));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = normalizeImgbbUrl(imageUrlController.text);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Add Book"),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: Colors.brown,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  field("Title", titleController, required: true),
                  field("Author", authorController, required: true),
                  field("Publisher", publisherController),
                  field(
                    "Published Date",
                    publishedDateController,
                    hint: "e.g. 2023",
                  ),
                  field("Page Count", pageCountController),
                  field("Description", descriptionController, maxLines: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Book Cover",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[800],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Preview Image
                      if (normalizedUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            normalizedUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Upload Text Button
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Text(
                          _isUploadingImage
                              ? "Uploading..."
                              : "Upload Book Cover",
                          style: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save To Label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Save to:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.brown[800],
                      ),
                    ),
                  ),

                  // Radio Buttons (Styled)
                  Theme(
                    data: Theme.of(context).copyWith(
                      radioTheme: RadioThemeData(
                        fillColor: MaterialStateProperty.all(Colors.brown),
                      ),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text('Library'),
                          value: 'library',
                          groupValue: _saveTo,
                          onChanged: (val) => setState(() => _saveTo = val!),
                        ),
                        RadioListTile<String>(
                          title: const Text('Wishlist'),
                          value: 'wishlist',
                          groupValue: _saveTo,
                          onChanged: (val) => setState(() => _saveTo = val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  _isSaving
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            label: Text(
                              "Save Book",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[400],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: saveBook,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable TextField Builder
  Widget field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[100],
          labelStyle: TextStyle(color: Colors.brown[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.brown[400]!),
          ),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? "$label cannot be empty" : null
            : null,
      ),
    );
  }
}
