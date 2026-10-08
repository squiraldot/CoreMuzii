import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:mdlovfimusic/ui/widgets/song_info_dialog.dart';
import 'package:mdlovfimusic/ui/widgets/standalone_song_info_dialog.dart';

void main() {
  testWidgets('song info dialog renders without cached stream metadata',
      (tester) async {
    final song = MediaItem(
      id: 'test-song',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: const Duration(minutes: 3),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => SongInfoDialog(song: song),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('song info content renders inside a modal bottom sheet',
      (tester) async {
    final song = MediaItem(
      id: 'test-song',
      title: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => Material(
                    child: SizedBox(
                      height: 500,
                      child: SongInfoContent(song: song),
                    ),
                  ),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone song info dialog renders metadata and actions',
      (tester) async {
    final song = MediaItem(
      id: 'standalone-song',
      title: 'Standalone Song',
      artist: 'Standalone Artist',
      album: 'Standalone Album',
      extras: const {
        'artists': [
          {'id': 'artist-id', 'name': 'Standalone Artist'},
        ],
      },
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: StandaloneSongInfoDialog(song: song),
                  ),
                );
              },
              child: const Text('Open Standalone'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Standalone'));
    await tester.pumpAndSettle();

    expect(find.text('Standalone Song'), findsOneWidget);
    expect(find.text('Standalone Artist'), findsOneWidget);
    expect(find.text('Standalone Album'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Start radio'), findsOneWidget);
    expect(find.text('Add to playlist'), findsOneWidget);
    expect(find.text('Share this song'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    expect(find.text('QR Code'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
