import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(home: BookSearchScreen()));
}

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({Key? key}) : super(key: key);

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  List<QueryDocumentSnapshot> _results = [];
  String? _message;

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _message = 'Enter a book title';
      });
      return;
    }

    setState(() {
      _loading = true;
      _results = [];
      _message = null;
    });

    try {
      // Prefer server-side query to avoid fetching the whole collection.
      // If Firestore titles are exact, use title field:
      final snap = await FirebaseFirestore.instance
          .collection('books')
          .where('title', isEqualTo: query)
          .limit(10)
          .get();

      // If you stored a lowercase version (recommended for case-insensitive):
      // final snap = await FirebaseFirestore.instance
      //     .collection('books')
      //     .where('title_lower', isEqualTo: query.toLowerCase())
      //     .limit(10)
      //     .get();

      final matches = snap.docs;

      setState(() {
        _results = matches;
        _message = matches.isEmpty ? 'Book not found' : null;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _message = 'Error searching books';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildResultItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Unknown Title';
    final author = data['author'] ?? 'Unknown Author';
    final copies = data['copies'] is num ? (data['copies'] as num).toInt() : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text('$title — $author'),
        subtitle: copies == 0
            ? const Text(
                'Not Available – All Copies Issued',
                style: TextStyle(color: Colors.red),
              )
            : Text('Copies Available: $copies'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library Book Search')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter book title',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _search,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Search'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _message != null
                  ? Center(child: Text(_message!))
                  : _results.isEmpty
                      ? const Center(child: Text('No search performed'))
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, i) => _buildResultItem(_results[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}