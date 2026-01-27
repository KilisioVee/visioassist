import 'package:flutter/material.dart';

/// Screen for selecting the detection source (camera or gallery).
class SourceSelectionScreen extends StatelessWidget {
  const SourceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Source'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live Camera Option
            _SourceCard(
              icon: Icons.camera_alt_outlined,
              title: 'Live Camera Detection',
              description: 'Detect objects in real-time using your camera',
              onTap: () {
                Navigator.of(context).pushNamed('/camera-detection');
              },
            ),
            const SizedBox(height: 24),
            // Gallery Option
            _SourceCard(
              icon: Icons.image_outlined,
              title: 'Gallery Detection',
              description: 'Pick an image and detect objects in it',
              onTap: () {
                Navigator.of(context).pushNamed('/gallery-detection');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable card widget for source selection options.
class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.deepPurple.withOpacity(0.2),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tap to select',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
