import '../screens/Search/search_result_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/widgets/content_list_widget_item.dart';

class ContentListWidget extends StatelessWidget {
  const ContentListWidget({
    super.key,
    this.content,
    this.isHomeContent = true,
    this.scrollController,
  });

  final dynamic content;
  final bool isHomeContent;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final isAlbumContent = content.runtimeType.toString() == "AlbumContent";
    final width = MediaQuery.of(context).size.width;
    final cardWidth = (width * 0.40).clamp(190.0, 430.0);
    final imageSize = cardWidth;
    final sectionHeight = imageSize + 100;

    return SizedBox(
      height: sectionHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  content.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                ),
              ),
              if (!isHomeContent)
                TextButton(
                  onPressed: () {
                    final controller = Get.find<SearchResultScreenController>();
                    controller.viewAllCallback(content.title);
                  },
                  child: Text(
                    "viewAll".tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: isAlbumContent
                  ? content.albumList.length
                  : content.playlistList.length,
              separatorBuilder: (_, __) =>
                  SizedBox(width: width >= 760 ? 36 : 18),
              itemBuilder: (_, index) => SizedBox(
                width: cardWidth,
                child: ContentListItem(
                  content: isAlbumContent
                      ? content.albumList[index]
                      : content.playlistList[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
