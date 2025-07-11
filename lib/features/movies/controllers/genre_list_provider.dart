import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';
import 'package:latest_movies/features/movies/repositories/movies_repository.dart';

final genreListProvider = FutureProvider<List<Genre>>((ref) async {
  final repository = ref.read(moviesRepositoryProvider);
  final allGenres = await repository.fetchGenres();
  return [
    const Genre(id: 0, name: 'All'),
    ...allGenres,
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
