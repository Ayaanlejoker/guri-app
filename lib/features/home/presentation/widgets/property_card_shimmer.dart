import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PropertyCardShimmer extends StatelessWidget {
  final bool isGrid;
  const PropertyCardShimmer({Key? key, this.isGrid = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isGrid ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.05),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          height: isGrid ? 220 : 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: isGrid ? 120 : 200,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20, width: 200, color: Colors.black),
                    const SizedBox(height: 10),
                    Container(height: 14, width: 150, color: Colors.black),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(height: 20, width: 60, color: Colors.black),
                        const SizedBox(width: 15),
                        Container(height: 20, width: 60, color: Colors.black),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
