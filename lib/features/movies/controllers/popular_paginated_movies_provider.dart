import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/data/dummy_data.dart';
import 'package:latest_movies/features/movies/controllers/genre_list_provider.dart';

import '../../../core/models/paginated_response.dart';
import '../models/movie/movie.dart';

final paginatedPopularMoviesProvider =
    FutureProvider.family<PaginatedResponse<Movie>, int>(
  (ref, int pageIndex) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final selectedGenre = ref.watch(selectedMovieGenreProvider);

    // Filter movies by selected genre
    List<Movie> filteredMovies;
    if (selectedGenre?.id == 0 || selectedGenre == null) {
      filteredMovies = dummyMovies;
    } else {
      filteredMovies = dummyMovies
          .where((movie) =>
              movie.genres?.any((genre) => genre.id == selectedGenre.id) ??
              false)
          .toList();
    }

    // Simulate pagination (20 items per page)
    const int itemsPerPage = 20;
    final int startIndex = pageIndex * itemsPerPage;
    final int endIndex =
        (startIndex + itemsPerPage).clamp(0, filteredMovies.length);

    final List<Movie> pageResults =
        filteredMovies.sublist(startIndex, endIndex);

    return PaginatedResponse<Movie>(
      page: pageIndex + 1,
      results: pageResults,
      totalPages: (filteredMovies.length / itemsPerPage).ceil(),
      totalResults: filteredMovies.length,
    );
  },
);
