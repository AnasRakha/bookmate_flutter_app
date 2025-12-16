import 'package:flutter/material.dart';
import 'package:BookMate/pages/book/detail_page.dart';
import 'package:BookMate/services/book_service.dart';

class SearchPage extends StatefulWidget {
  final String? email; // Email menjadi nullable

  const SearchPage({this.email, Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  List<dynamic> _searchResults = [];
  List<dynamic> _categoryBooks = [];
  bool _isLoading = false;
  bool _isSearching = false;

  // List kategori
  final List<String> categories = [
    "Education",
    "Fiction",
    "Science",
    "Romance",
    "Business",
    "History",
    "Technology",
    "Fantasy",
  ];

  final Map<String, String> categoryThumbnails = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryThumbnails();
  }

  // Load thumbnail pertama tiap kategori
  Future<void> _loadCategoryThumbnails() async {
    // Jalankan semua request secara paralel
    final futures = categories.map((category) async {
      final books = await BookService.getBooksByCategory(category);
      if (books.isNotEmpty) {
        final volume = books[0]['volumeInfo'];
        final thumb = volume['imageLinks']?['thumbnail'] ?? '';
        return MapEntry(category, thumb);
      } else {
        return MapEntry(category, '');
      }
    }).toList();

    // Tunggu semua selesai sekaligus
    final results = await Future.wait(futures);

    // Simpan hasil ke map sekaligus lalu rebuild UI sekali saja
    for (var result in results) {
      categoryThumbnails[result.key] = result.value;
    }

    setState(() {});
  }

  // Search Books by Query
  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    final books = await BookService.searchBooks(query);

    setState(() {
      _searchResults = books;
      _isLoading = false;
    });
  }

  // Load Books by Category
  Future<void> _loadBooksByCategory(String category) async {
    setState(() {
      _isLoading = true;
      _isSearching = false;
    });

    final books = await BookService.getBooksByCategory(category);

    setState(() {
      _categoryBooks = books;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text(
          "Search Books",
          style: TextStyle(
            fontSize: 24,
            // fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child:
                      widget.email ==
                          null // Cek jika email null (guest)
                      ? Center(
                          child: Text(
                            "Please login to search books.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : (!_isSearching
                            ? SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCategoryList(),
                                    const SizedBox(height: 20),
                                    _buildCategoryResults(),
                                  ],
                                ),
                              )
                            : _buildSearchResults()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (v) => setState(() => _isSearching = v.isNotEmpty),
      onSubmitted: _searchBooks,
      decoration: InputDecoration(
        hintText: 'Enter book name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: IconButton(
          icon: Icon(_controller.text.isNotEmpty ? Icons.close : Icons.search),
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              _controller.clear();
              setState(() {
                _searchResults = [];
                _isSearching = false;
              });
            } else {
              _searchBooks(_controller.text);
            }
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
      ),
    );
  }

  // Category List Widget (Circle Avatar + Thumbnail)
  Widget _buildCategoryList() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((category) {
          final thumb = categoryThumbnails[category] ?? '';

          return GestureDetector(
            onTap: () => _loadBooksByCategory(category),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: thumb.isNotEmpty
                        ? NetworkImage(thumb)
                        : null,
                    backgroundColor: Colors.brown[300],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Category Results Grid
  Widget _buildCategoryResults() {
    if (_categoryBooks.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Category Results",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categoryBooks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.45,
          ),
          itemBuilder: (_, index) {
            final book = _categoryBooks[index];
            final volume = book["volumeInfo"];
            final title = volume["title"] ?? "No Title";
            final thumb = volume["imageLinks"]?["thumbnail"];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DetailPage(book: book, email: widget.email!),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 0.65,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: thumb != null
                          ? Image.network(thumb, fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Search Results Grid
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text("No books found"));
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.45,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (_, index) {
        final book = _searchResults[index];
        final info = book["volumeInfo"];
        final title = info["title"] ?? "No Title";
        final thumb = info["imageLinks"]?["thumbnail"];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailPage(book: book, email: widget.email!),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 0.65,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: thumb != null
                      ? Image.network(thumb, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
