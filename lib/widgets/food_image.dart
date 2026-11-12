import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FoodImage extends StatelessWidget {
  final String base64Image;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  const FoodImage({
    super.key,
    required this.base64Image,
    this.height,
    this.width,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (base64Image.isEmpty) {
      child = Container(
        height: height,
        width: width,
        color: AppColors.primaryLight,
        child: const Icon(Icons.fastfood, size: 40, color: AppColors.primary),
      );
    } else {
      child = Image.memory(
        base64Decode(base64Image),
        height: height,
        width: width,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}