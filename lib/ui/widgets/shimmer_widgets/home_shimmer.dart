import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'basic_container.dart';

class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: Colors.grey[500]!,
        highlightColor: Colors.grey[300]!,
        enabled: true,
        direction: ShimmerDirection.ltr,
        child: Column(
          children: [_discoverWidget(), _contentWidget(), _contentWidget()],
        ));
  }

  Widget _discoverWidget() {
    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BasicShimmerContainer(Size(150, 24)),
                    SizedBox(height: 6),
                    BasicShimmerContainer(Size(95, 14)),
                  ],
                ),
              ),
              BasicShimmerContainer(Size(40, 40)),
              SizedBox(width: 12),
              BasicShimmerContainer(Size(40, 40)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) =>
                  const BasicShimmerContainer(Size(82, 36)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 16,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 8.2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (_, item) {
                return const Row(
                  children: [
                    BasicShimmerContainer(Size(48, 48)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BasicShimmerContainer(Size(130, 16)),
                          SizedBox(height: 5),
                          BasicShimmerContainer(Size(82, 12)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 5),
          child: BasicShimmerContainer(Size(220, 30)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 175,
          //color: Colors.blueAccent,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, index) {
                return Container(
                  width: 132,
                  padding: const EdgeInsets.only(left: 5.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 112,
                          child: BasicShimmerContainer(Size(120, 120))),
                      SizedBox(height: 5),
                      BasicShimmerContainer(Size(115, 20)),
                      SizedBox(height: 5),
                      BasicShimmerContainer(Size(90, 15)),
                    ],
                  ),
                );
              }),
        ),
      ],
    );
  }
}
