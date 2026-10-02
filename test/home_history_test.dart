import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mdlovfimusic/utils/home_history.dart';

void main() {
  setUpAll(() async {
    Hive.init('test_hive_home_history');
    await Hive.openBox('AppPrefs');
  });

  tearDown(() async {
    await Hive.box('AppPrefs').clear();
  });

  test('stores newest played track first and removes duplicates', () async {
    final first = MediaItem(id: 'first', title: 'First');
    final second = MediaItem(id: 'second', title: 'Second');

    await saveRecentlyPlayed(first);
    await saveRecentlyPlayed(second);
    await saveRecentlyPlayed(first);

    final history = loadRecentlyPlayed();

    expect(history.map((item) => item.id).toList(), ['first', 'second']);
  });

  test('merge puts locally played tracks ahead of server history', () {
    final local = [
      MediaItem(id: 'local', title: 'Local'),
      MediaItem(id: 'same', title: 'Same local'),
    ];
    final remote = [
      MediaItem(id: 'same', title: 'Same remote'),
      MediaItem(id: 'remote', title: 'Remote'),
    ];

    final merged = mergeRecentlyPlayed(local, remote);

    expect(merged.map((item) => item.id).toList(), ['local', 'same', 'remote']);
    expect(merged[1].title, 'Same local');
  });
}
