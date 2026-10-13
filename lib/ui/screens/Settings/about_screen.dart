import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mdlovfimusic/ui/screens/Settings/settings_screen_controller.dart';
import 'package:url_launcher/url_launcher.dart';

/// Project and application information for MuziiNap.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color _muted = Color(0xFF9B9B9B);
  static const Color _divider = Color(0xFF292929);

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsScreenController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('About'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _divider),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF383838)),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'MuziiNap',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your music, your way.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: _muted),
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF202020),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Version ${controller.currentVersion}',
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(color: _divider),
            const SizedBox(height: 18),
            Text(
              'About MuziiNap',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'MuziiNap is a music streaming app built on the MDLovFi Music project. '
              'It brings music discovery, playback, playlists, a personal library, '
              'YouTube account support, and audio customization features together '
              'in one place.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Project & source code',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _AboutLinkTile(
              icon: Icons.code_rounded,
              title: 'MuziiNap source code',
              subtitle: 'Explore the app source and its improvements',
              onTap: () => _openLink('https://github.com/squiraldot/CoreMuzii'),
            ),
            _AboutLinkTile(
              icon: Icons.history_rounded,
              title: 'Original project',
              subtitle: 'MDLovFi Music by anandnet',
              onTap: () => _openLink('https://github.com/anandnet/MDLovFi-Music'),
            ),
            const SizedBox(height: 18),
            const Divider(color: _divider),
            const SizedBox(height: 18),
            Text(
              'Open source',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MuziiNap builds on an existing open-source music app. We appreciate '
              'the original project and the open-source tools and libraries that '
              'help make this app possible.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(color: _divider),
            const SizedBox(height: 18),
            Text(
              'Made for music lovers.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _muted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLinkTile extends StatelessWidget {
  const _AboutLinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF9B9B9B),
            ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9B9B9B)),
      onTap: onTap,
    );
  }
}
