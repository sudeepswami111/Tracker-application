import 'package:flutter/material.dart';
import '../../screens/community_screen.dart';

class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityScreen(isEmbedded: true);
  }
}
