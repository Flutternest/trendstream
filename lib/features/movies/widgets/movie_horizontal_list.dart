import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/app_loader.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/features/movies/controllers/current_popular_movies_provider.dart';
import 'package:latest_movies/features/movies/controllers/popular_movies_count_provider.dart';
import 'package:latest_movies/features/movies/models/movie/movie.dart';
import 'package:latest_movies/features/movies/widgets/movie_item.dart';

class MovieHorizontalList extends HookConsumerWidget {
  const MovieHorizontalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresWithMoviesAsync = ref.watch(allGenresWithMoviesProvider);

    return genresWithMoviesAsync.when(
      data: (genresWithMovies) {
        return ListView.builder(
          itemCount: genresWithMovies.length,
          itemBuilder: (context, index) {
            final genre = genresWithMovies.keys.elementAt(index);
            final movies = genresWithMovies[genre]!;

            return SizedBox(
              height: 475,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Genre title
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      genre.name ?? 'Unknown Genre',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  // Horizontal movie list
                  Expanded(
                    // Fixed height for movie tiles
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      itemCount: movies.length,
                      itemBuilder: (context, movieIndex) {
                        final AsyncValue<Movie> currentPopularMovieFromIndex =
                            AsyncValue.data(movies[movieIndex]);

                        return SizedBox(
                          width: 185,
                          child: ProviderScope(
                            overrides: [
                              currentPopularMovieProvider.overrideWithValue(
                                  currentPopularMovieFromIndex)
                            ],
                            child: MovieTile(autofocus: index == 0),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24.0), // Spacing between genres
                ],
              ),
            );
          },
        );
      },
      error: (error, stackTrace) => ErrorView(
        onRetry: () {
          ref.invalidate(allGenresWithMoviesProvider);
        },
      ),
      loading: () => const AppLoader(),
    );
  }
}

class MovieHorizontalTile extends StatelessWidget {
  const MovieHorizontalTile({
    super.key,
    required this.movie,
  });

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Movie info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie title
                  Text(
                    movie.title ?? 'Unknown Title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4.0),

                  // Release year
                  if (movie.releaseDate != null)
                    Text(
                      movie.releaseDate!.split('-').first,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),

                  const SizedBox(height: 4.0),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16.0,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        movie.voteAverage?.toStringAsFixed(1) ?? 'N/A',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative version with more compact design
class MovieHorizontalListCompact extends HookConsumerWidget {
  const MovieHorizontalListCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresWithMoviesAsync = ref.watch(allGenresWithMoviesProvider);

    return genresWithMoviesAsync.when(
      data: (genresWithMovies) {
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: genresWithMovies.length,
          itemBuilder: (context, index) {
            final genre = genresWithMovies.keys.elementAt(index);
            final movies = genresWithMovies[genre]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Genre title with movie count
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      Text(
                        genre.name ?? 'Unknown Genre',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(width: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          '${movies.length} movies',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal movie list
                SizedBox(
                  height: 200, // Smaller height for compact design
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: movies.length,
                    itemBuilder: (context, movieIndex) {
                      final movie = movies[movieIndex];
                      return Container(
                        width: 140, // Smaller width for compact design
                        margin: const EdgeInsets.only(right: 8.0),
                        child: MovieCompactTile(movie: movie),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16.0),
              ],
            );
          },
        );
      },
      error: (error, stackTrace) => ErrorView(
        onRetry: () {
          ref.invalidate(allGenresWithMoviesProvider);
        },
      ),
      loading: () => const AppLoader(),
    );
  }
}

class MovieCompactTile extends StatelessWidget {
  const MovieCompactTile({
    super.key,
    required this.movie,
  });

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8.0),
                ),
                image: DecorationImage(
                  image: NetworkImage(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Movie info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Movie title
                  Text(
                    movie.title ?? 'Unknown Title',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2.0),

                  // Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12.0,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2.0),
                      Text(
                        movie.voteAverage?.toStringAsFixed(1) ?? 'N/A',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
