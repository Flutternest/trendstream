import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/features/movies/controllers/genre_list_provider.dart';

import '../../../core/models/paginated_response.dart';
import '../models/movie/movie.dart';
import '../repositories/movies_repository.dart';

final paginatedPopularMoviesProvider =
    FutureProvider.family<PaginatedResponse<Movie>, int>(
  (ref, int pageIndex) async {
    final moviesRepository = ref.watch(moviesRepositoryProvider);
    final selectedGenre = ref.watch(selectedMovieGenreProvider);
    return moviesRepository.getPopularMovies(
      page: pageIndex + 1,
      genre: selectedGenre?.id != 0 ? selectedGenre : null,
    );
  },
);
