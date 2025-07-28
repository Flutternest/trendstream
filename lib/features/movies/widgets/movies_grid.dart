import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/core/shared_widgets/genre_selector.dart';
import 'package:latest_movies/features/movies/controllers/genre_list_provider.dart';
import 'package:latest_movies/features/movies/controllers/popular_movies_count_provider.dart';

import '../../../core/shared_widgets/app_loader.dart';
import '../../../core/utilities/responsive.dart';
import '../controllers/current_popular_movies_provider.dart';
import '../controllers/popular_paginated_movies_provider.dart';
import '../models/movie/movie.dart';
import 'movie_item.dart';

class MoviesGrid extends HookConsumerWidget {
  const MoviesGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularMoviesCount = ref.watch(popularMoviesCountProvider);
    final asyncGenres = ref.watch(genreListProvider);
    final selectedGenre = ref.watch(selectedMovieGenreProvider);
    final isGenreSelectorCollapsed = useState(false);
    return asyncGenres.when(
      data: (genres) {
        return FocusTraversalGroup(
          child: Row(
            children: [
              FocusTraversalOrder(
                order: const NumericFocusOrder(1),
                child: GenreSelector(
                    genres: genres,
                    selectedGenre: selectedGenre,
                    onGenreSelected: (genre) {
                      ref.read(selectedMovieGenreProvider.notifier).state =
                          genre;
                      Future.microtask(() {
                        ref.invalidate(popularMoviesCountProvider);
                        ref.invalidate(paginatedPopularMoviesProvider(0));
                      });
                    },
                    isCollapsed: isGenreSelectorCollapsed),
              ),
              Expanded(
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: popularMoviesCount.map(
                    data: (asyncData) {
                      return _MoviesGridWidget(
                        totalItems: asyncData.value,
                      );
                    },
                    error: (e) => ErrorView(
                      onRetry: () {
                        Future.microtask(() {
                          ref.invalidate(popularMoviesCountProvider);
                          ref.invalidate(paginatedPopularMoviesProvider(0));
                        });
                      },
                    ),
                    loading: (_) => const AppLoader(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      error: (e, _) => ErrorView(
        onRetry: () {
          Future.microtask(() {
            ref.invalidate(genreListProvider);
          });
        },
      ),
      loading: () => const AppLoader(),
    );
  }
}

class _MoviesGridWidget extends HookConsumerWidget {
  const _MoviesGridWidget({
    super.key,
    required this.totalItems,
  });

  final int totalItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNodes = useMemoized(() => List.generate(totalItems, (index) => FocusNode()),);
    return AlignedGridView.count(
      key: const PageStorageKey<String>(
          'preserve_movies_grid_scroll_and_focus'),
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
        final AsyncValue<Movie> currentPopularMovieFromIndex =
            ref
                .watch(paginatedPopularMoviesProvider(
                    index ~/ 20))
                .whenData((pageData) =>
                    pageData.results[index % 20]);
    
        return ProviderScope(
          overrides: [
            currentPopularMovieProvider.overrideWithValue(
                currentPopularMovieFromIndex)
          ],
          child: MovieTile(
            autofocus: false,
            index: index,
            focusNode: focusNodes[index],
          ),
        );
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

void printWidgetTreeAroundFocus() {
  final focusedNode = FocusManager.instance.primaryFocus;
  final context = focusedNode?.context;
  if (context == null) {
    print("No focused widget found.");
    return;
  }

  final ancestors = findAncestors(context);
  final descendants = findDescendants(context);

  print("==== 5 Ancestors ====");
  for (var e in ancestors) {
    if (e.widget is MovieTile) {
      print("Ancestor: ${(e.widget as MovieTile).index}");
    }
    print(e.widget.runtimeType);
  }

  print("==== 5 Descendants ====");
  for (var e in descendants) {
    print(e.widget.runtimeType);
  }
}
