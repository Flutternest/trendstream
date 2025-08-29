import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/data/dummy_data.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/features/movies/controllers/movie_search_controller.dart';
import 'package:latest_movies/features/movies/controllers/search_movie_count_provider.dart';
import 'package:latest_movies/features/movies/controllers/search_paginated_movies_provider.dart';

import '../../../core/shared_widgets/app_loader.dart';
import '../../../core/utilities/responsive.dart';
import '../controllers/current_popular_movies_provider.dart';
import '../models/movie/movie.dart';
import 'movie_item.dart';

class MovieSearchGrid extends HookConsumerWidget {
  const MovieSearchGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchedMoviesCount = ref.watch(searchMovieCountProvider);
    final pageBucket = useMemoized(() => PageStorageBucket());

    return PageStorage(
      bucket: pageBucket,
      child: searchedMoviesCount.map(
        data: (asyncData) {
          return _SearchGridWidget(
            totalItems: asyncData.value,
          );
        },
        error: (e) {
          if (e.error is DioError) {
            try {
              if ((e.error as DioError)
                  .response
                  ?.data['errors']
                  .contains('query must be provided')) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.search,
                      size: 100,
                      color: kPrimaryColor,
                    ),
                    verticalSpaceRegular,
                    Text(
                        "${context.localisations.trySearchingFor}\"Top Gun Maverick...\""),
                  ],
                );
              }
            } catch (e) {}
          }
          return const ErrorView();
        },
        loading: (_) => const AppLoader(),
      ),
    );
  }
}

class _SearchGridWidget extends HookConsumerWidget {
  const _SearchGridWidget({
    super.key,
    required this.totalItems,
  });

  final int totalItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNodes = useMemoized(
      () => List.generate(totalItems, (index) => FocusNode()),
    );

    // Focus management state
    final currentFocusedIndex = useState(0);
    final isFocused = useState(true);

    // Scroll controller for movies grid
    final moviesScrollController = useScrollController();

    // Handle keyboard navigation
    final handleKeyPress = useCallback(
      (KeyEvent event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          final crossAxisCount = ResponsiveWidget.isMediumScreen(context)
              ? 3
              : ResponsiveWidget.isSmallScreen(context)
                  ? 2
                  : 6;

          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowUp:
              // Navigate up in movies grid
              final newIndex = currentFocusedIndex.value - crossAxisCount;
              if (newIndex >= 0 && totalItems > 0) {
                currentFocusedIndex.value = newIndex;
                _scrollToMovieItem(
                  currentFocusedIndex.value,
                  totalItems,
                  moviesScrollController,
                  crossAxisCount,
                );
                return true;
              }
              return false;

            case LogicalKeyboardKey.arrowDown:
              // Navigate down in movies grid
              final newIndex = currentFocusedIndex.value + crossAxisCount;
              if (newIndex < totalItems) {
                currentFocusedIndex.value = newIndex;
                _scrollToMovieItem(
                  currentFocusedIndex.value,
                  totalItems,
                  moviesScrollController,
                  crossAxisCount,
                );
              }
              return true;

            case LogicalKeyboardKey.arrowLeft:
              // Navigate left in movies grid
              if (currentFocusedIndex.value % crossAxisCount > 0) {
                currentFocusedIndex.value--;
                return true;
              }
              return false;

            case LogicalKeyboardKey.arrowRight:
              // Navigate right in movies grid
              if ((currentFocusedIndex.value + 1) % crossAxisCount != 0 &&
                  currentFocusedIndex.value + 1 < totalItems) {
                currentFocusedIndex.value++;
              }
              return true;

            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
              // Navigate to movie detail (handled by MovieTile)
              return false;
          }
        }
        return false;
      },
      [totalItems, currentFocusedIndex.value],
    );

    // Set up initial focus
    useEffect(() {
      if (totalItems > 0) {
        currentFocusedIndex.value = 0;
        Future.microtask(() {
          if (focusNodes.isNotEmpty) {
            focusNodes[0].requestFocus();
          }
        });
      }
      return null;
    }, [totalItems]);

    // Set focus to current focused index when section becomes focused
    useEffect(() {
      if (isFocused.value &&
          currentFocusedIndex.value < totalItems &&
          totalItems > 0) {
        Future.microtask(() {
          if (focusNodes.isNotEmpty &&
              currentFocusedIndex.value < focusNodes.length) {
            focusNodes[currentFocusedIndex.value].requestFocus();
          }
        });
      }
      return null;
    }, [isFocused.value, currentFocusedIndex.value, totalItems]);

    return Focus(
      onKeyEvent: (node, event) => handleKeyPress(event)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: AlignedGridView.count(
        key: const PageStorageKey<String>(
            'preserve_search_grid_scroll_and_focus'),
        controller: moviesScrollController,
        itemCount: totalItems,
        crossAxisCount: ResponsiveWidget.isMediumScreen(context)
            ? 3
            : ResponsiveWidget.isSmallScreen(context)
                ? 2
                : 6,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        itemBuilder: (BuildContext context, int index) {
          final AsyncValue<Movie> currentPopularPersonFromIndex = ref
              .watch(paginatedSearchMoviesProvider(PaginatedSearchProviderArgs(
                  page: index ~/ 20, query: ref.watch(searchKeywordProvider))))
              .whenData((pageData) => pageData.results[index % 20]);
          // final AsyncValue<Movie> currentMovie =
          //     AsyncValue.data(dummyMovies[index]);

          return ProviderScope(
            overrides: [
              currentPopularMovieProvider.overrideWithValue(currentPopularPersonFromIndex)
            ],
            child: MovieTile(
              autofocus: false,
              index: index,
              focusNode: focusNodes[index],
              isFocused: isFocused.value && currentFocusedIndex.value == index,
            ),
          );
        },
      ),
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
}
