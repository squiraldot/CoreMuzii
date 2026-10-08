import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/ui/widgets/song_info_overlay.dart';

void main() {
  testWidgets('SongInfoOverlay renders without a route', (tester) async {
    final song = MediaItem(
      id: 'test-id',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              SongInfoOverlay(
                song: song,
                onClose: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('song_info_overlay_title')), findsOneWidget);
    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(find.text('test-id'), findsOneWidget);
  });

  testWidgets('showSongInfoOverlay inserts and removes an OverlayEntry',
      (tester) async {
    final song = MediaItem(
      id: 'test-id',
      title: 'Test Song',
      artist: 'Test Artist',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSongInfoOverlay(context, song),
                child: const Text('Open Info'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Info'));
    await tester.pump();

    expect(find.byKey(const Key('song_info_overlay_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('song_info_overlay_close')));
    await tester.pump();

    expect(find.byKey(const Key('song_info_overlay_title')), findsNothing);
  });
}
