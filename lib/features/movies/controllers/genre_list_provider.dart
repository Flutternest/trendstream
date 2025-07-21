import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/data/dummy_data.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';
import 'package:latest_movies/features/movies/repositories/movies_repository.dart';

final genreListProvider = FutureProvider<List<Genre>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    const Genre(id: 0, name: 'All'),
    ...dummyGenres,
  ];
});

final selectedMovieGenreProvider = StateProvider<Genre?>((ref) {
  final genres = ref.watch(genreListProvider).valueOrNull;
  return genres?.firstWhere((genre) => genre.id == 0,
      orElse: () => const Genre(id: 0, name: 'All'));
});

final selectedAdultGenreProvider = StateProvider<Genre?>((ref) {
  final genres = ref.watch(genreListProvider).valueOrNull;
  return genres?.firstWhere((genre) => genre.id == 0,
      orElse: () => const Genre(id: 0, name: 'All'));
});
