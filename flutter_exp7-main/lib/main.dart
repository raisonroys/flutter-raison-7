import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library Book Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LibraryPage(),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _titleCtr = TextEditingController();
  final _authorCtr = TextEditingController();
  final _copiesCtr = TextEditingController();
  final CollectionReference booksCol =
      FirebaseFirestore.instance.collection('books');

  Future<void> _addBook() async {
    final title = _titleCtr.text.trim();
    final author = _authorCtr.text.trim();
    final copiesText = _copiesCtr.text.trim();

    if (title.isEmpty || author.isEmpty || copiesText.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    final copies = int.tryParse(copiesText);
    if (copies == null || copies < 0) {
      _showSnack('Copies must be a non-negative integer');
      return;
    }

    // Save to Firestore (auto id)
    await booksCol.add({
      'title': title,
      'author': author,
      'copies': copies,
    });

    _titleCtr.clear();
    _authorCtr.clear();
    _copiesCtr.clear();
    _showSnack('Book added');
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _titleCtr.dispose();
    _authorCtr.dispose();
    _copiesCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Book Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Form area
            TextField(
              controller: _titleCtr,
              decoration: const InputDecoration(labelText: 'Book Title'),
            ),
            TextField(
              controller: _authorCtr,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            TextField(
              controller: _copiesCtr,
              decoration: const InputDecoration(labelText: 'Number of Copies'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addBook,
              child: const Text('Add Book'),
            ),
            const SizedBox(height: 12),

            // List and totals
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: booksCol.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No books added yet.'));
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final title = data['title'] ?? '';
                            final author = data['author'] ?? '';
                            final copies = (data['copies'] is int)
                                ? data['copies'] as int
                                : int.tryParse('${data['copies']}') ?? 0;

                            return ListTile(
                              title: Text('$title – $author – Copies: $copies'),
                              subtitle: copies == 0
                                  ? const Text(
                                      'Not Available – All Copies Issued',
                                      style: TextStyle(color: Colors.red),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await booksCol.doc(doc.id).delete();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      // Total count at bottom of screen area
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Total Books in Library: ${docs.length}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}