import 'package:flutter/material.dart';

/// Screen for selecting the detection source (camera or gallery).
class SourceSelectionScreen extends StatelessWidget {
  const SourceSelectionScreen({super.key});

  static const Color _primary = Color(0xFF5B3FD8);
  static const Color _primaryDark = Color(0xFF4527A0);
  static const Color _bgTop = Color(0xFFF7F4FF);
  static const Color _bgBottom = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1C1B1F);
  static const Color _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Choose detection source',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select how you want to detect objects. You can use the live camera for real-time detection or choose a photo from your gallery.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _primary.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: _primaryDark,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'All detection stays on your device',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      _SourceCard(
                        icon: Icons.camera_alt_rounded,
                        title: 'Live Camera',
                        description:
                        'Detect objects in real time as your camera sees them.',
                        badge: 'Recommended',
                        accentColor: const Color(0xFF5B3FD8),
                        onTap: () {
                          Navigator.of(context).pushNamed('/camera-detection');
                        },
                      ),

                      const SizedBox(height: 18),

                      _SourceCard(
                        icon: Icons.photo_library_rounded,
                        title: 'Gallery Photo',
                        description:
                        'Choose an existing image and analyze objects in it.',
                        badge: 'Quick pick',
                        accentColor: const Color(0xFF7C4DFF),
                        onTap: () {
                          Navigator.of(context).pushNamed('/gallery-detection');
                        },
                      ),

                      const SizedBox(height: 28),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: const [
                            _MiniTip(
                              icon: Icons.flash_on_rounded,
                              text: 'Live camera works best for immediate detection.',
                            ),
                            SizedBox(height: 12),
                            _MiniTip(
                              icon: Icons.crop_free_rounded,
                              text: 'Gallery is ideal when you already have a saved photo.',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color accentColor;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: description,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF9F7FF)],
              ),
              border: Border.all(
                color: accentColor.withOpacity(0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: accentColor.withOpacity(0.10),
                    ),
                    child: Icon(
                      icon,
                      size: 34,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              'Select source',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: accentColor,
                            ),
                          ],
                        ),
                      ],
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
}

class _MiniTip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniTip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: SourceSelectionScreen._primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: SourceSelectionScreen._textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}