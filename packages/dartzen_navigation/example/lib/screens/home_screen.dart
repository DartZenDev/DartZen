import 'package:flutter/material.dart';

/// Home screen showing an overview
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home,
              size: 120,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to DartZen Navigation Demo',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This app demonstrates the adaptive navigation '
                'capabilities of the dartzen_navigation package.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Features:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _FeatureItem(
              text: '✓ Adaptive navigation (mobile, tablet, desktop)',
            ),
            const _FeatureItem(text: '✓ Platform-specific highlights'),
            const _FeatureItem(text: '✓ Overflow handling'),
            const _FeatureItem(text: '✓ Badge support'),
            const _FeatureItem(text: '✓ Riverpod integration'),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text),
    );
  }
}
