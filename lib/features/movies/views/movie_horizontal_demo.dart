import 'package:flutter/material.dart';
import 'package:latest_movies/features/movies/widgets/movie_horizontal_list.dart';

class MovieHorizontalDemo extends StatefulWidget {
  const MovieHorizontalDemo({super.key});

  @override
  State<MovieHorizontalDemo> createState() => _MovieHorizontalDemoState();
}

class _MovieHorizontalDemoState extends State<MovieHorizontalDemo> {
  bool _useCompactVersion = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie Horizontal List Demo'),
        actions: [
          // Toggle between regular and compact versions
          IconButton(
            icon: Icon(_useCompactVersion ? Icons.view_agenda : Icons.view_compact),
            onPressed: () {
              setState(() {
                _useCompactVersion = !_useCompactVersion;
              });
            },
            tooltip: _useCompactVersion ? 'Switch to Regular View' : 'Switch to Compact View',
          ),
        ],
      ),
      body: _useCompactVersion 
        ? const MovieHorizontalListCompact()
        : const MovieHorizontalList(),
    );
  }
} 