import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CommunitySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          if (query.isEmpty) {
            close(context, '');
          } else {
            query = '';
            showSuggestions(context);
          }
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
      child: Text(
        'Searching for: "$query"',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search the community...'));
    }
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: Text('Search for "$query"'),
          onTap: () {
            showResults(context);
          },
        ),
      ],
    );
  }
}
