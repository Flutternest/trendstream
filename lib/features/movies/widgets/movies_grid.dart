import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/genre_selector.dart';
import 'package:latest_movies/core/utilities/app_logger.dart';
import 'package:latest_movies/features/movies/controllers/genre_list_provider.dart';
import 'package:latest_movies/features/movies/controllers/popular_movies_count_provider.dart';

import '../../../core/router/router.dart';
import '../../../core/shared_widgets/app_loader.dart';
import '../../../core/shared_widgets/error_view.dart';
import '../../../core/utilities/responsive.dart';
import '../controllers/current_popular_movies_provider.dart';
import '../controllers/popular_paginated_movies_provider.dart';
import '../models/movie/genre.dart';
import '../models/movie/movie.dart';
import '../repositories/movies_repository.dart';
import 'movie_item.dart';

// TMDB API providers
final tmdbMoviesProvider = FutureProvider<List<Movie>>((ref) async {
  final repository = ref.watch(moviesRepositoryProvider);
  final response =
      await repository.getPopularMovies(page: 1, forceRefresh: false);
  return response.results;
});

final tmdbMoviesByGenreProvider =
    FutureProvider.family<List<Movie>, int>((ref, genreId) async {
  final repository = ref.watch(moviesRepositoryProvider);
  if (genreId == 0) {
    // Return all movies for "All" genre
    final response =
        await repository.getPopularMovies(page: 1, forceRefresh: false);
    return response.results;
  }

  // Fetch movies by specific genre
  final response = await repository.getPopularMovies(
      page: 1, forceRefresh: false, genre: Genre(id: genreId, name: ''));
  return response.results;
});

final tmdbGenresProvider = FutureProvider((ref) async {
  final repository = ref.watch(moviesRepositoryProvider);
  return await repository.fetchGenres();
});

enum Sections {
  genre,
  movies,
}

class MoviesGrid extends HookConsumerWidget {
  const MoviesGrid({
    super.key,
    this.useTMDBAPI = false,
  });

  final bool useTMDBAPI;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSection = useState(Sections.genre);
    final selectedGenre = ref.watch(selectedMovieGenreProvider);

    // Use different providers based on the flag
    final popularMoviesCount = useTMDBAPI
        ? ref
            .watch(tmdbMoviesByGenreProvider(selectedGenre?.id ?? 0))
            .whenData((movies) => movies.length)
        : ref.watch(popularMoviesCountProvider);

    final asyncGenres = useTMDBAPI
        ? ref.watch(tmdbGenresProvider)
        : ref.watch(genreListProvider);

    final isGenreSelectorCollapsed = useState(false);

    // Focus management state
    final currentGenreIndex = useState(0);
    final currentMovieIndex = useState(0);

    // Focus nodes
    final genreSidebarFocus = useFocusNode(debugLabel: 'GenreSidebar');
    final moviesGridFocus = useFocusNode(debugLabel: 'MoviesGrid');

    // Scroll controller for genre sidebar
    final genreSidebarScrollController = useScrollController();

    // Scroll controller for movies grid
    final moviesScrollController = useScrollController();

    return asyncGenres.when(
      data: (genres) {
        // Get the list of genres for focus management
        final genreList = genres;
        final genreGlobalKeys = genreList.map((genre) => GlobalKey()).toList();

        final crossAxisCount = ResponsiveWidget.isMediumScreen(context)
            ? 4
            : ResponsiveWidget.isSmallScreen(context)
                ? 2
                : 6;

        // Handle keyboard navigation
        final handleKeyPress = useCallback(
          (KeyEvent event) {
            AppLogger(identifier: 'MoviesGrid').d('onKeyEvent: $event');
            if (event is KeyDownEvent || event is KeyRepeatEvent) {
              switch (event.logicalKey) {
                case LogicalKeyboardKey.arrowUp:
                  if (selectedSection.value == Sections.genre) {
                    // Navigate up in genre sidebar
                    if (currentGenreIndex.value > 0) {
                      currentGenreIndex.value--;
                      _scrollToGenreItem(
                        genreGlobalKeys[currentGenreIndex.value],
                      );
                    } else {
                      return true;
                    }
                  } else {
                    // Navigate up in movies grid
                    final totalMovies = popularMoviesCount.asData?.value ?? 0;
                    final newIndex = currentMovieIndex.value - crossAxisCount;
                    if (newIndex >= 0 && totalMovies > 0) {
                      currentMovieIndex.value = newIndex;
                      _scrollToMovieItem(
                        currentMovieIndex.value,
                        totalMovies,
                        moviesScrollController,
                        crossAxisCount,
                      );
                    }
                  }
                  return true;

                case LogicalKeyboardKey.arrowDown:
                  if (selectedSection.value == Sections.genre) {
                    // Navigate down in genre sidebar
                    if (currentGenreIndex.value < genreList.length - 1) {
                      currentGenreIndex.value++;
                      _scrollToGenreItem(
                        genreGlobalKeys[currentGenreIndex.value],
                      );
                    } else {
                      return true;
                    }
                  } else {
                    // Navigate down in movies grid
                    final totalMovies = popularMoviesCount.asData?.value ?? 0;

                    final newIndex = currentMovieIndex.value + crossAxisCount;
                    if (newIndex < totalMovies) {
                      currentMovieIndex.value = newIndex;
                      _scrollToMovieItem(
                        currentMovieIndex.value,
                        totalMovies,
                        moviesScrollController,
                        crossAxisCount,
                      );
                    }
                  }
                  return true;

                case LogicalKeyboardKey.arrowLeft:
                  if (selectedSection.value == Sections.movies) {
                    // Move from movies to genre sidebar or navigate left in movies
                    if (currentMovieIndex.value % crossAxisCount > 0) {
                      currentMovieIndex.value--;
                    } else {
                      // Go back to genre sidebar
                      selectedSection.value = Sections.genre;
                      isGenreSelectorCollapsed.value = false;
                      genreSidebarFocus.requestFocus();
                      _scrollToGenreItem(
                        genreGlobalKeys[currentGenreIndex.value],
                      );
                    }
                  } else {
                    return false;
                  }
                  return true;

                case LogicalKeyboardKey.arrowRight:
                  if (selectedSection.value == Sections.genre) {
                    // Move from genre sidebar to movies
                    isGenreSelectorCollapsed.value = true;
                    selectedSection.value = Sections.movies;
                    currentMovieIndex.value = 0;

                    // Scroll to top when moving to movies grid
                    Future.microtask(() {
                      if (moviesScrollController.hasClients) {
                        moviesScrollController.animateTo(
                          moviesScrollController.position.minScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    moviesGridFocus.requestFocus();
                  } else {
                    // Navigate right in movies grid
                    final totalMovies = popularMoviesCount.asData?.value ?? 0;
                    if ((currentMovieIndex.value + 1) % crossAxisCount != 0 &&
                        currentMovieIndex.value + 1 < totalMovies) {
                      currentMovieIndex.value++;
                    } else {
                      return false;
                    }
                  }
                  return true;

                case LogicalKeyboardKey.select:
                case LogicalKeyboardKey.enter:
                  if (selectedSection.value == Sections.genre &&
                      genreList.isNotEmpty) {
                    // Select genre and move to movies
                    ref.read(selectedMovieGenreProvider.notifier).state =
                        genreList[currentGenreIndex.value];
                    selectedSection.value = Sections.movies;
                    isGenreSelectorCollapsed.value = true;
                    currentMovieIndex.value = 0;

                    // Scroll to top when selecting a genre
                    Future.microtask(() {
                      if (moviesScrollController.hasClients) {
                        moviesScrollController.animateTo(
                          moviesScrollController.position.minScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    moviesGridFocus.requestFocus();
                  } else if (selectedSection.value == Sections.movies) {
                    // Navigate to movie detail using the callback
                    final totalMovies = popularMoviesCount.asData?.value ?? 0;
                    log(
                        'MoviesGrid: select/enter pressed on movies section, totalMovies: $totalMovies, currentFocusedIndex: ${currentMovieIndex.value}');
                    if (currentMovieIndex.value < totalMovies) {
                      // Get the movie ID from the current focused index
                      if (useTMDBAPI) {
                        log('MoviesGrid: using TMDB API for movie selection');
                        final moviesAsync = ref.read(
                            tmdbMoviesByGenreProvider(selectedGenre?.id ?? 0));
                        moviesAsync.whenData((movies) {
                          if (currentMovieIndex.value < movies.length) {
                            final movie = movies[currentMovieIndex.value];
                            log(
                                'MoviesGrid: navigating to movie details with ID: ${movie.id}');
                            AppRouter.navigateToPage(Routes.detailsView,
                                arguments: {'id': movie.id, 'movie': movie});
                          }
                        });
                      } else {
                        log(
                            'MoviesGrid: using non-TMDB API for movie selection');
                        // For non-TMDB API, we need to get the movie from the paginated provider
                        final movieAsync = ref.read(
                            paginatedPopularMoviesProvider(
                                currentMovieIndex.value ~/ 20));
                        movieAsync.whenData((pageData) {
                          final movie =
                              pageData.results[currentMovieIndex.value % 20];
                          log(
                              'MoviesGrid: navigating to movie details with ID: ${movie.id}');
                          AppRouter.navigateToPage(Routes.detailsView,
                              arguments: {'id': movie.id, 'movie': movie});
                        });
                      }
                    }
                  }
                  return true;
              }
            }
            return false;
          },
          [
            genreList,
            selectedSection.value,
            currentGenreIndex.value,
            currentMovieIndex.value,
            popularMoviesCount.asData?.value,
          ],
        );

        // Set up initial focus
        useEffect(() {
          genreSidebarFocus.requestFocus();
          currentGenreIndex.value = 0;

          return null;
        }, []);

        useEffect(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (genreList.isNotEmpty) {
              ref.read(selectedMovieGenreProvider.notifier).state =
                  genreList[currentGenreIndex.value];
            }
          });
          return null;
        }, [currentGenreIndex.value]);

        return Focus(
          onKeyEvent: (node, event) => handleKeyPress(event)
              ? KeyEventResult.handled
              : KeyEventResult.ignored,
          child: Row(
            children: [
              // Genre Selector with enhanced focus management
              Focus(
                focusNode: genreSidebarFocus,
                child: GenreSelector(
                  genres: genres,
                  selectedGenre: selectedGenre,
                  onGenreSelected: (genre) {
                    ref.read(selectedMovieGenreProvider.notifier).state = genre;
                    // Update current genre index
                    final genreIndex =
                        genres.indexWhere((g) => g.id == genre.id);
                    if (genreIndex != -1) {
                      currentGenreIndex.value = genreIndex;
                    }

                    Future.microtask(() {
                      if (useTMDBAPI) {
                        ref.invalidate(
                            tmdbMoviesByGenreProvider(genre.id ?? 0));
                      } else {
                        ref.invalidate(popularMoviesCountProvider);
                        ref.invalidate(paginatedPopularMoviesProvider(0));
                      }
                    });
                  },
                  isCollapsed: isGenreSelectorCollapsed,
                  currentFocusedIndex: currentGenreIndex.value,
                  isFocused: selectedSection.value == Sections.genre,
                  scrollController: genreSidebarScrollController,
                  genreGlobalKeys: genreGlobalKeys,
                ),
              ),
              Expanded(
                child: popularMoviesCount.map(
                  data: (asyncData) {
                    return Focus(
                      focusNode: moviesGridFocus,
                      child: _MoviesGridWidget(
                        totalItems: asyncData.value,
                        currentFocusedIndex: currentMovieIndex.value,
                        isFocused: selectedSection.value == Sections.movies,
                        scrollController: moviesScrollController,
                        useTMDBAPI: useTMDBAPI,
                        selectedGenre: selectedGenre,
                        onMovieSelected: (movie) {
                          // Navigate to movie details
                          log(
                              'MoviesGrid: onMovieSelected callback called with movie: ${movie.title} (ID: ${movie.id})');
                          AppRouter.navigateToPage(Routes.detailsView,
                              arguments: {'id': movie.id, 'movie': movie});
                        },
                      ),
                    );
                  },
                  error: (e) => ErrorView(
                    onRetry: () {
                      Future.microtask(() {
                        if (useTMDBAPI) {
                          ref.invalidate(tmdbMoviesByGenreProvider(
                              selectedGenre?.id ?? 0));
                        } else {
                          ref.invalidate(popularMoviesCountProvider);
                          ref.invalidate(paginatedPopularMoviesProvider(0));
                        }
                      });
                    },
                  ),
                  loading: (_) => const AppLoader(),
                ),
              ),
            ],
          ),
        );
      },
      error: (e, _) => ErrorView(
        onRetry: () {
          Future.microtask(() {
            if (useTMDBAPI) {
              ref.invalidate(tmdbGenresProvider);
            } else {
              ref.invalidate(genreListProvider);
            }
          });
        },
      ),
      loading: () => const AppLoader(),
    );
  }

  void _scrollToMovieItem(
    int itemIndex,
    int totalItems,
    ScrollController controller,
    int crossAxisCount,
  ) {
    if (totalItems == 0) return;

    final currentRow = itemIndex ~/ crossAxisCount;

    // Calculate approximate item height including spacing
    const itemHeight =
        400.0; // Approximate height based on aspect ratio and spacing
    final targetScrollOffset = currentRow * itemHeight;

    // Get the viewport height to determine if scrolling is needed
    final viewportHeight = controller.position.viewportDimension;
    final maxScrollOffset = controller.position.maxScrollExtent;

    // Only scroll if the item is outside the current viewport
    final currentScrollOffset = controller.offset;
    final itemTopOffset = targetScrollOffset;
    final itemBottomOffset = targetScrollOffset + itemHeight;

    if (itemTopOffset < currentScrollOffset) {
      // Item is above viewport, scroll up
      controller.animateTo(
        itemTopOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else if (itemBottomOffset > currentScrollOffset + viewportHeight) {
      // Item is below viewport, scroll down
      final newOffset = itemBottomOffset - viewportHeight;
      controller.animateTo(
        newOffset.clamp(0.0, maxScrollOffset),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToGenreItem(
    GlobalKey genreGlobalKey,
  ) {
    // final context = genreGlobalKey.currentContext;
    // if (context != null) {
    //   Scrollable.ensureVisible(
    //     context,
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeOut,
    //     alignment: 0.5,
    //   );
    // }
  }
}

class _MoviesGridWidget extends HookConsumerWidget {
  const _MoviesGridWidget({
    super.key,
    required this.totalItems,
    required this.currentFocusedIndex,
    required this.isFocused,
    required this.scrollController,
    required this.useTMDBAPI,
    required this.selectedGenre,
    required this.onMovieSelected,
  });

  final int totalItems;
  final int currentFocusedIndex;
  final bool isFocused;
  final ScrollController scrollController;
  final bool useTMDBAPI;
  final Genre? selectedGenre;
  final Function(Movie movie)? onMovieSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNodes = useMemoized(
      () => List.generate(totalItems, (index) => FocusNode()),
    );

    // Set focus to current focused index when section becomes focused
    useEffect(() {
      if (isFocused && currentFocusedIndex < totalItems) {
        Future.microtask(() {
          focusNodes[currentFocusedIndex].requestFocus();
        });
      }
      return null;
    }, [isFocused, currentFocusedIndex, totalItems]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.minScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
      return null;
    }, [totalItems]);

    return AlignedGridView.count(
      key:
          const PageStorageKey<String>('preserve_movies_grid_scroll_and_focus'),
      controller: scrollController,
      itemCount: totalItems,
      crossAxisCount: ResponsiveWidget.isMediumScreen(context)
          ? 4
          : ResponsiveWidget.isSmallScreen(context)
              ? 2
              : 6,
      mainAxisSpacing: 10.0,
      crossAxisSpacing: 10.0,
      cacheExtent: 100,
      itemBuilder: (BuildContext context, int index) {
        if (useTMDBAPI) {
          final moviesAsync =
              ref.watch(tmdbMoviesByGenreProvider(selectedGenre?.id ?? 0));
          log(
              'MoviesGrid: TMDB API - Watching provider for genre ${selectedGenre?.id ?? 0}, moviesAsync: $moviesAsync');
          return moviesAsync.when(
            data: (movies) {
              log(
                  'MoviesGrid: TMDB API - Got movies data, count: ${movies.length}');
              if (index >= movies.length) {
                log(
                    'MoviesGrid: TMDB API - Index $index out of bounds for ${movies.length} movies');
                return const SizedBox.shrink(); // Hide if index out of bounds
              }
              final movie = movies[index];
              log(
                  'MoviesGrid: TMDB API - Movie at index $index: ${movie.title} (ID: ${movie.id})');

              return ProviderScope(
                overrides: [
                  currentPopularMovieProvider
                      .overrideWithValue(AsyncValue.data(movie))
                ],
                child: MovieTile(
                  autofocus: false,
                  index: index,
                  focusNode: focusNodes[index],
                  isFocused: isFocused && currentFocusedIndex == index,
                  onMovieSelected: onMovieSelected,
                ),
              );
            },
            error: (e, stackTrace) {
              log('MoviesGrid: TMDB API - Error loading movies: $e');
              return ErrorView(
                error: e.toString(),
                onRetry: () {
                  ref.invalidate(
                      tmdbMoviesByGenreProvider(selectedGenre?.id ?? 0));
                },
              );
            },
            loading: () {
              log('MoviesGrid: TMDB API - Loading movies...');
              return const AppLoader();
            },
          );
        } else {
          log('MoviesGrid: Non-TMDB API - Loading movie for index $index');
          final movieAsync =
              ref.watch(paginatedPopularMoviesProvider(index ~/ 20));

          return movieAsync.when(
            data: (pageData) {
              if (index % 20 >= pageData.results.length) {
                log(
                    'MoviesGrid: Non-TMDB API - Index out of bounds for page data');
                return const SizedBox.shrink();
              }

              final movie = pageData.results[index % 20];
              log(
                  'MoviesGrid: Non-TMDB API - Movie at index $index: ${movie.title} (ID: ${movie.id})');

              return ProviderScope(
                overrides: [
                  currentPopularMovieProvider
                      .overrideWithValue(AsyncValue.data(movie))
                ],
                child: MovieTile(
                  autofocus: false,
                  index: index,
                  focusNode: focusNodes[index],
                  isFocused: isFocused && currentFocusedIndex == index,
                  onMovieSelected: onMovieSelected,
                ),
              );
            },
            error: (e, stackTrace) {
              log('MoviesGrid: Non-TMDB API - Error loading page data: $e');
              return ErrorView(
                error: e.toString(),
                onRetry: () {
                  ref.invalidate(paginatedPopularMoviesProvider(index ~/ 20));
                },
              );
            },
            loading: () {
              log('MoviesGrid: Non-TMDB API - Loading page data...');
              return const AppLoader();
            },
          );
        }
      },
    );
  }
}

List<Element> findDescendants(BuildContext context, [int max = 10]) {
  final descendants = <Element>[];
  void recurse(Element element, int depth) {
    if (descendants.length >= max) return;
    element.visitChildElements((child) {
      if (descendants.length >= max) return;
      descendants.add(child);
      recurse(child, depth + 1);
    });
  }

  recurse(context as Element, 0);
  return descendants;
}

List<Element> findAncestors(BuildContext context, [int max = 10]) {
  final ancestors = <Element>[];
  context.visitAncestorElements((element) {
    if (ancestors.length < max) {
      ancestors.add(element);

      return true;
    }
    return false;
  });
  return ancestors;
}

void logWidgetTreeAroundFocus() {
  final focusedNode = FocusManager.instance.primaryFocus;
  final context = focusedNode?.context;
  if (context == null) {
    log("No focused widget found.");
    return;
  }

  final ancestors = findAncestors(context);
  final descendants = findDescendants(context);

  log("==== 5 Ancestors ====");
  for (var e in ancestors) {
    if (e.widget is MovieTile) {
      log("Ancestor: ${(e.widget as MovieTile).index}");
    }
    log(e.widget.runtimeType.toString());
  }

  log("==== 5 Descendants ====");
  for (var e in descendants) {
    log(e.widget.runtimeType.toString());
  }
}
