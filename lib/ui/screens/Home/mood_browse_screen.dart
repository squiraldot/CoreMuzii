import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/models/album.dart';
import '/models/home_mood.dart';
import '/models/playlist.dart';
import '/models/quick_picks.dart';
import '/services/music_service.dart';
import '/ui/widgets/content_list_widget.dart';
import '/ui/widgets/quickpickswidget.dart';

class MoodBrowseScreen extends StatelessWidget {
  const MoodBrowseScreen({super.key, required this.mood});

  final HomeMood mood;

  @override
  Widget build(BuildContext context) {
    final service = Get.find<MusicServices>();

    return Scaffold(
      appBar: AppBar(title: Text(mood.title)),
      body: FutureBuilder<List<dynamic>>(
        future: service.getMoodBrowse(mood.browseId, params: mood.params),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Unable to load the selected mood'));
          }

          final sections = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.only(top: 20, bottom: 120),
            itemCount: sections.length,
            itemBuilder: (_, index) {
              final section = sections[index];
              if (section is QuickPicks) {
                return QuickPicksWidget(content: section);
              }
              if (section is PlaylistContent || section is AlbumContent) {
                return ContentListWidget(content: section);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}
