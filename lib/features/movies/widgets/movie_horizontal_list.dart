import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/app_loader.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/features/movies/controllers/current_popular_movies_provider.dart';
import 'package:latest_movies/features/movies/controllers/popular_movies_count_provider.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';
import 'package:latest_movies/features/movies/models/movie/movie.dart';
import 'package:latest_movies/features/movies/widgets/movie_item.dart';

class MovieHorizontalList extends HookConsumerWidget {
  const MovieHorizontalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresWithMoviesAsync = ref.watch(allGenresWithMoviesProvider);

    return genresWithMoviesAsync.when(
      data: (genresWithMovies) {
        // Focus management state
        final currentGenreIndex = useState(0);
        final currentMovieIndex = useState(0);

        // Create focus nodes for each genre section
        final genreFocusNodes = useMemoized(
          () => List.generate(genresWithMovies.length, (index) => FocusNode()),
        );

        // Create scroll controllers for each genre's horizontal list
        final genreScrollControllers = useMemoized(
          () => List.generate(
              genresWithMovies.length, (index) => ScrollController()),
        );

        // Global keys for each genre section
        final globalKeys = useMemoized(
          () => List.generate(genresWithMovies.length, (index) => GlobalKey()),
        );

        // Main vertical scroll controller for the entire list
        final mainScrollController = useScrollController();

        // Handle keyboard navigation
        final handleKeyPress = useCallback(
          (KeyEvent event) {
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              final genres = genresWithMovies.keys.toList();
              final currentGenre = genres[currentGenreIndex.value];
              final currentMovies = genresWithMovies[currentGenre]!;

              switch (event.logicalKey) {
                case LogicalKeyboardKey.arrowLeft:
                  if (currentMovieIndex.value > 0) {
                    currentMovieIndex.value--;
                    _scrollToMovieInGenre(
                      genreScrollControllers[currentGenreIndex.value],
                      currentMovieIndex.value,
                      currentMovies.length,
                    );
                    return false;
                  }

                case LogicalKeyboardKey.arrowRight:
                  if (currentMovieIndex.value < currentMovies.length - 1) {
                    currentMovieIndex.value++;
                    _scrollToMovieInGenre(
                      genreScrollControllers[currentGenreIndex.value],
                      currentMovieIndex.value,
                      currentMovies.length,
                    );
                    return false;
                  } else {
                    // Move to next genre if at the end of current genre
                    if (currentGenreIndex.value < genres.length - 1) {
                      currentGenreIndex.value++;
                      currentMovieIndex.value = 0;
                      _focusAndScrollToGenre(
                        genreFocusNodes[currentGenreIndex.value],
                        globalKeys[currentGenreIndex.value],
                        genreScrollControllers[currentGenreIndex.value],
                        mainScrollController,
                      );
                      return false;
                    }
                  }
                  return true;

                case LogicalKeyboardKey.arrowUp:
                  if (currentGenreIndex.value > 0) {
                    currentGenreIndex.value--;
                    currentMovieIndex.value = 0;
                    _focusAndScrollToGenre(
                      genreFocusNodes[currentGenreIndex.value],
                      globalKeys[currentGenreIndex.value],
                      genreScrollControllers[currentGenreIndex.value],
                      mainScrollController,
                    );
                    return false;
                  }
                  return true;

                case LogicalKeyboardKey.arrowDown:
                  if (currentGenreIndex.value < genres.length - 1) {
                    currentGenreIndex.value++;
                    currentMovieIndex.value = 0;
                    _focusAndScrollToGenre(
                      genreFocusNodes[currentGenreIndex.value],
                      globalKeys[currentGenreIndex.value],
                      genreScrollControllers[currentGenreIndex.value],
                      mainScrollController,
                    );
                    return false;
                  }
                  return true;

                case LogicalKeyboardKey.select:
                case LogicalKeyboardKey.enter:
                  // Handle movie selection (will be handled by MovieTile)
                  return false;
              }
            }
            return false;
          },
          [genresWithMovies, currentGenreIndex.value, currentMovieIndex.value],
        );

        // Set initial focus
        useEffect(() {
          if (genresWithMovies.isNotEmpty) {
            Future.microtask(() {
              genreFocusNodes[0].requestFocus();
            });
          }
          return null;
        }, []);

        return Focus(
          onKeyEvent: (node, event) => handleKeyPress(event)
              ? KeyEventResult.handled
              : KeyEventResult.ignored,
          child: ListView.builder(
            controller: mainScrollController,
            physics: const ClampingScrollPhysics(),
            itemCount: genresWithMovies.length,
            itemBuilder: (context, index) {
              final genre = genresWithMovies.keys.elementAt(index);
              final movies = genresWithMovies[genre]!;

              return _MovieHorizontalListWidget(
                genre: genre,
                movies: movies,
                globalKey: globalKeys[index],
                focusNode: genreFocusNodes[index],
                scrollController: genreScrollControllers[index],
                isFocused: currentGenreIndex.value == index,
                currentMovieIndex: currentMovieIndex.value,
                onMovieIndexChanged: (newIndex) {
                  currentMovieIndex.value = newIndex;
                },
              );
            },
          ),
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

  void _scrollToMovieInGenre(
    ScrollController scrollController,
    int movieIndex,
    int totalMovies,
  ) {
    if (!scrollController.hasClients) return;

    // Calculate the position to scroll to
    const movieWidth = 185.0; // Width of each movie tile
    final targetOffset = movieIndex * movieWidth;

    // Calculate the maximum scroll extent
    final maxScrollExtent = scrollController.position.maxScrollExtent;

    // Ensure we don't scroll beyond the available content
    final clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

    scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _focusAndScrollToGenre(
    FocusNode focusNode,
    GlobalKey globalKey,
    ScrollController scrollController,
    ScrollController mainScrollController,
  ) {
    Future.microtask(() {
      focusNode.requestFocus();

      // Use Scrollable.ensureVisible with proper alignment to show genre title
      if (globalKey.currentContext != null) {
        Scrollable.ensureVisible(
          globalKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.0, // Align to top to ensure genre title is visible
        );
      }

      // Reset horizontal scroll position to beginning of the genre
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _MovieHorizontalListWidget extends HookWidget {
  const _MovieHorizontalListWidget({
    super.key,
    required this.genre,
    required this.movies,
    required this.globalKey,
    required this.focusNode,
    required this.scrollController,
    required this.isFocused,
    required this.currentMovieIndex,
    required this.onMovieIndexChanged,
  });

  final Genre genre;
  final List<Movie> movies;
  final GlobalKey globalKey;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final bool isFocused;
  final int currentMovieIndex;
  final ValueChanged<int> onMovieIndexChanged;

  @override
  Widget build(BuildContext context) {
    // Create focus nodes for each movie in this genre
    final movieFocusNodes = useMemoized(
      () => List.generate(movies.length, (index) => FocusNode()),
    );

    // Effect to focus the current movie when this genre gains focus
    useEffect(() {
      if (isFocused && currentMovieIndex < movies.length) {
        Future.microtask(() {
          movieFocusNodes[currentMovieIndex].requestFocus();
        });
      }
      return null;
    }, [isFocused, currentMovieIndex]);

    return Container(
      key: globalKey,
      margin: const EdgeInsets.only(top: 16.0), // Reduced top margin
      child: Focus(
        focusNode: focusNode,
        skipTraversal: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genre title - always visible with better styling
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0), // Reduced vertical padding
              decoration: BoxDecoration(
                color: isFocused
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                genre.name ?? 'Unknown Genre',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white, // Always white for better visibility
                      fontWeight: isFocused ? FontWeight.bold : FontWeight.w600,
                    ),
              ),
            ),

            // Horizontal movie list
            SizedBox(
              height: 420, // Reduced height to prevent overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                controller: scrollController,
                physics:
                    const ClampingScrollPhysics(), // Remove bouncing physics
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 8.0), // Reduced vertical padding
                itemCount: movies.length,
                itemBuilder: (context, movieIndex) {
                  final AsyncValue<Movie> currentPopularMovieFromIndex =
                      AsyncValue.data(movies[movieIndex]);

                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      width: 185,
                      child: ProviderScope(
                        overrides: [
                          currentPopularMovieProvider
                              .overrideWithValue(currentPopularMovieFromIndex)
                        ],
                        child: MovieTile(
                          autofocus:
                              isFocused && currentMovieIndex == movieIndex,
                          index: movieIndex,
                          focusNode: movieFocusNodes[movieIndex],
                          onFocusChanged: (hasFocus) {
                            if (hasFocus) {
                              onMovieIndexChanged(movieIndex);
                            }
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12.0), // Reduced spacing between genres
          ],
        ),
      ),
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
