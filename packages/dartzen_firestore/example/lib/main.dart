import 'package:flutter/material.dart';

/// Simple example demonstrating dartzen_firestore package structure.
///
/// Note: This example shows the API but cannot run without:
/// 1. Firebase initialization
/// 2. Firestore emulator or production setup
/// 3. Proper localization setup
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DartZen Firestore Example',
    home: Scaffold(
      appBar: AppBar(title: const Text('DartZen Firestore')),
      body: const Center(
        child: Text(
          'See README.md for usage examples.\n\n'
          'This package provides:\n'
          '- FirestoreConnection\n'
          '- FirestoreConverters\n'
          '- FirestoreBatch\n'
          '- FirestoreTransaction\n'
          '- FirestoreErrorMapper',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
