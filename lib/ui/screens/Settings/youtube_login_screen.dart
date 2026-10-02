import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:mdlovfimusic/services/music_service.dart';
import 'package:mdlovfimusic/ui/screens/Home/home_screen_controller.dart';
import 'package:mdlovfimusic/ui/screens/Library/library_controller.dart';

class YoutubeLoginScreen extends StatefulWidget {
  const YoutubeLoginScreen({super.key});

  @override
  State<YoutubeLoginScreen> createState() => _YoutubeLoginScreenState();
}

class _YoutubeLoginScreenState extends State<YoutubeLoginScreen> {
  late final WebViewController _webViewController;
  final WebViewCookieManager _cookieManager = WebViewCookieManager();
  bool _isLoading = true;
  bool _loginCompleting = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.104 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });
            await _checkAndExtractSession();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?service=youtube&continue=https://music.youtube.com/'));
  }

  Future<void> _checkAndExtractSession() async {
    if (_loginCompleting) return;

    try {
      final rawContext = await _webViewController.runJavaScriptReturningResult(
        '''
          (function () {
            var c = window.ytcfg;
            var y = window.yt && window.yt.config_;
            var get = c && c.get ? c.get.bind(c) : null;
            return JSON.stringify({
              visitorData: (get && get('VISITOR_DATA')) || (y && y.VISITOR_DATA) || null,
              dataSyncId: (get && get('DATASYNC_ID')) || (y && y.DATASYNC_ID) || null,
              authUser: String((get && get('SESSION_INDEX')) || (y && y.SESSION_INDEX) || 0)
            });
          })()
        ''',
      );
      final contextText = rawContext is String ? rawContext : rawContext.toString();
      dynamic decoded = contextText;
      try {
        decoded = jsonDecode(contextText);
      } catch (_) {}
      if (decoded is String) {
        try {
          decoded = jsonDecode(decoded);
        } catch (_) {}
      }
      final sessionContext = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};

      final merged = <String, String>{};
      for (final uri in const [
        'https://music.youtube.com',
        'https://www.youtube.com',
        'https://youtube.com',
      ]) {
        final cookies = await _cookieManager.getCookies(domain: Uri.parse(uri));
        for (final cookie in cookies) {
          if (cookie.name.isNotEmpty && cookie.value.isNotEmpty) {
            merged[cookie.name] = cookie.value;
          }
        }
      }

      final cookies = merged.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
      final hasSapIsid = merged.containsKey('SAPISID') ||
          merged.containsKey('__Secure-3PAPISID') ||
          merged.containsKey('__Secure-1PAPISID');
      final hasSessionCookie = merged.containsKey('SID') ||
          merged.containsKey('__Secure-3PSID') ||
          merged.containsKey('__Secure-3PSIDTS');

      if (!hasSapIsid || !hasSessionCookie || cookies.isEmpty) return;

      final musicServices = Get.isRegistered<MusicServices>()
          ? Get.find<MusicServices>()
          : null;
      if (musicServices == null) return;

      _loginCompleting = true;
      final authReady = await musicServices.updateAuthCookies(
        cookies,
        visitorData: sessionContext['visitorData']?.toString(),
        dataSyncId: sessionContext['dataSyncId']?.toString(),
        authUser: sessionContext['authUser']?.toString(),
      );
      if (!authReady) {
        _loginCompleting = false;
        return;
      }

      final sessionValid = await musicServices.validateYouTubeSession();
      if (!sessionValid) {
        musicServices.clearAuthCookies();
        _loginCompleting = false;
        if (mounted) {
          Get.snackbar(
            "YouTube Login",
            "The YouTube session could not be verified. Please finish signing in and try again.",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        return;
      }

      final box = Hive.box('AppPrefs');
      await box.put('yt_cookies', cookies);
      await box.put('yt_logged_in', true);
      if (sessionContext['visitorData']?.toString().trim().isNotEmpty == true) {
        await box.put('yt_visitor_data', sessionContext['visitorData'].toString());
      }
      if (sessionContext['dataSyncId']?.toString().trim().isNotEmpty == true) {
        await box.put('yt_data_sync_id', sessionContext['dataSyncId'].toString());
      }
      await box.put('yt_auth_user', sessionContext['authUser']?.toString() ?? '0');

      try {
        if (Get.isRegistered<HomeScreenController>()) {
          await Get.find<HomeScreenController>().loadContentFromNetwork(silent: true);
        }
        if (Get.isRegistered<LibraryPlaylistsController>()) {
          Get.find<LibraryPlaylistsController>().refreshLib();
        }
      } catch (_) {
        // Authentication is already verified; UI refresh can retry on the next screen load.
      }

      if (mounted) {
        Get.back(result: true);
        Get.snackbar(
          "YouTube Login",
          "YouTube account connected and verified.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
        );
      }
    } catch (_) {
      _loginCompleting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in to YouTube"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
