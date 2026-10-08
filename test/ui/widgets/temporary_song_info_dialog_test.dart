import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coremuzii/ui/widgets/temporary_song_info_dialog.dart';

void main() {
  final song = MediaItem(
    id: 'song-123',
    title: 'A Very Long Test Song Title',
    album: 'Test Album',
    artist: 'Test Artist',
    duration: const Duration(minutes: 3, seconds: 42),
  );

  testWidgets('renders song metadata and closes without Flutter errors',
      (tester) async {
    Object? buildException;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => TemporarySongInfoDialog(song: song),
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
    buildException = tester.takeException();

    expect(buildException, isNull);
    expect(find.byKey(const Key('temporary_song_info_title')), findsOneWidget);
    expect(find.text(song.title), findsOneWidget);
    expect(find.text(song.artist!), findsOneWidget);
    expect(find.text(song.album!), findsOneWidget);
    expect(find.byKey(const Key('temporary_song_info_close')), findsOneWidget);
    expect(find.text('NA'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('temporary_song_info_close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('temporary_song_info_title')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
