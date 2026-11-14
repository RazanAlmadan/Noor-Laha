import 'package:flutter/material.dart';
import 'upcoming_screen.dart';

// Favorites screen. It is a placeholder for now,
// we will replace it with the real saved ayahs list later.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UpcomingScreen(
      title: 'المفضلة',
      icon: Icons.favorite_rounded,
      showBackButton: true,
    );
  }
}