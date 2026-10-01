import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive/hive.dart';
import 'package:mdlovfimusic/services/music_service.dart';

class YoutubeLoginScreen extends StatefulWidget {
  const YoutubeLoginScreen({super.key});

  @override
  State<YoutubeLoginScreen> createState() => _YoutubeLoginScreenState();
}

class _YoutubeLoginScreenState extends State<YoutubeLoginScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

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
            await _checkAndExtractCookies();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://accounts.google.com/ServiceLogin?service=youtube&continue=https://music.youtube.com/'));
  }

  Future<void> _checkAndExtractCookies() async {
    try {
      final String cookiesString =
          await _webViewController.runJavaScriptReturningResult('document.cookie') as String;

      // Clean string if formatted by webview json encoding
      final cleanedCookies = cookiesString.replaceAll('"', '');

      if (cleanedCookies.contains('SAPISID') || cleanedCookies.contains('LOGIN_INFO')) {
        final box = Hive.box('AppPrefs');
        await box.put('yt_cookies', cleanedCookies);
        await box.put('yt_logged_in', true);

        if (Get.isRegistered<MusicServices>()) {
          await Get.find<MusicServices>().updateAuthCookies(cleanedCookies);
        }

        Get.back(result: true);
        Get.snackbar(
          "YouTube Login",
          "Successfully logged in to YouTube!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.grey[900],
          colorText: Colors.white,
        );
      }
    } catch (_) {}
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
