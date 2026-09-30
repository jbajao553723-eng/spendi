import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle._(this.icon, this.color);

  final IconData icon;
  final Color color;

  static CategoryStyle forName(String category) {
    return switch (category.toLowerCase()) {
      'food' => const CategoryStyle._(
        Icons.restaurant_rounded,
        Color(0xFFF97316),
      ),
      'transportation' => const CategoryStyle._(
        Icons.directions_car_rounded,
        Color(0xFF0EA5E9),
      ),
      'education' => const CategoryStyle._(
        Icons.school_rounded,
        Color(0xFF8B5CF6),
      ),
      'shopping' => const CategoryStyle._(
        Icons.shopping_bag_rounded,
        Color(0xFFEC4899),
      ),
      'bills' => const CategoryStyle._(
        Icons.receipt_rounded,
        Color(0xFF14B8A6),
      ),
      'entertainment' => const CategoryStyle._(
        Icons.movie_rounded,
        Color(0xFFF43F5E),
      ),
      'health' => const CategoryStyle._(
        Icons.health_and_safety_rounded,
        Color(0xFF16A34A),
      ),
      _ => const CategoryStyle._(Icons.payments_rounded, Color(0xFF5B5BD6)),
    };
  }
}
