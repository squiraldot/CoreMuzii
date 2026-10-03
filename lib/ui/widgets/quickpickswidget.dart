import 'package:audio_service/audio_service.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/models/quick_picks.dart';
import '../player/player_controller.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget({
    super.key,
    required this.content,
    this.scrollController,
  });

  final QuickPicks content;
  final ScrollController? scrollController;

  bool _isQuickPicks(String title) =>
      title.trim().toLowerCase() == 'quick picks' ||
      title.trim().toLowerCase() == 'quick pick';

  bool _isWideShelf(String title) {
    final normalized = title.trim().toLowerCase();
    final titleHint = normalized.contains('listen again') ||
        normalized.contains('forgotten') ||
        normalized.contains('long listens') ||
        normalized.contains('music video') ||
        normalized.contains('music videos');
    final videoCount = content.songList.where((song) {
      final type = song.extras?['videoType']?.toString() ?? '';
      return type.isNotEmpty && type != 'MUSIC_VIDEO_TYPE_ATV';
    }).length;
    return titleHint ||
        (content.songList.isNotEmpty &&
            videoCount * 2 >= content.songList.length);
  }

  void _play(BuildContext context, int index) {
    Get.find<PlayerController>().pushSongToQueue(content.songList[index]);
  }

  void _showSongMenu(BuildContext context, MediaItem song) {
    final player = Get.find<PlayerController>();
    showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      context: player.homeScaffoldkey.currentState!.context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (_) => SongInfoBottomSheet(song),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  Widget _heading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Text(
        content.title.trim().isEmpty ? 'YouTube Music' : content.title.trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
      ),
    );
  }

  Widget _quickPicksList(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final rowHeight = wide ? 92.0 : 76.0;
        final artwork = wide ? 78.0 : 62.0;
        const rowCount = 4;
        // Match SimpMusic: portrait quick-pick cells use the full content width,
        // so four songs form one vertical page and the next page peeks in.
        final itemWidth = wide ? widthClamp(constraints.maxWidth, 430.0) : constraints.maxWidth;

        return SizedBox(
          height: rowHeight * rowCount + 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context),
          Expanded(
            child: Scrollbar(
              thickness: GetPlatform.isDesktop ? null : 0,
              controller: scrollController,
              child: GridView.builder(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: content.songList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: itemWidth / (rowHeight - 4),
                  crossAxisSpacing: wide ? 8 : 4,
                  mainAxisSpacing: wide ? 14 : 8,
                ),
                itemBuilder: (_, index) {
                  final song = content.songList[index];
                  return Listener(
                    onPointerDown: (event) {
                      if (event.buttons == kSecondaryMouseButton) {
                        _showSongMenu(context, song);
                      }
                    },
                    child: InkWell(
                      onTap: () => _play(context, index),
                      onLongPress: () => _showSongMenu(context, song),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: ImageWidget(song: song, size: artwork),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.15,
                                      ),
                                ),
                                if ((song.artist ?? '').trim().isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    song.artist ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  double widthClamp(double width, double maxWidth) =>
      width < maxWidth ? width : maxWidth;

  Widget _cardShelf(BuildContext context, {required bool wideCards}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = wideCards
            ? (width * 0.74).clamp(260.0, 540.0)
            : (width * 0.46).clamp(170.0, 320.0);
        final imageHeight = wideCards ? cardWidth * 9 / 16 : cardWidth;
        final imageRadius = wideCards ? 18.0 : 16.0;
        // Keep the title area compact so the next Home shelf never overlaps it.
        final sectionHeight = imageHeight + (wideCards ? 150.0 : 142.0);

        return SizedBox(
          height: sectionHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(context),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: content.songList.length,
              separatorBuilder: (_, __) => SizedBox(width: width >= 760 ? 36 : 18),
              itemBuilder: (_, index) {
                final song = content.songList[index];
                return SizedBox(
                  width: cardWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(imageRadius),
                    onTap: () => _play(context, index),
                    onLongPress: () => _showSongMenu(context, song),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(imageRadius),
                          child: SizedBox(
                            width: cardWidth,
                            height: imageHeight,
                            child: Image.network(
                              song.artUri.toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/icons/song.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                        ),
                        if ((song.artist ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            song.artist ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (content.songList.isEmpty) return const SizedBox.shrink();
    final title = content.title;
    if (_isQuickPicks(title)) {
      return _quickPicksList(context);
    }
    return _cardShelf(context, wideCards: _isWideShelf(title));
  }
}
