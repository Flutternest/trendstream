import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/exceptions/app_error_codes.dart';
import 'package:latest_movies/core/exceptions/general_exception.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/core/utilities/responsive.dart';
import 'package:latest_movies/features/movies/controllers/current_multi_program_provider.dart';
import 'package:latest_movies/features/movies/controllers/search_multi_programs_count_provider.dart';
import 'package:latest_movies/features/movies/controllers/search_paginated_multi_programs.dart';
import 'package:latest_movies/features/movies/widgets/multi_program_item.dart';

import '../../../core/shared_widgets/app_loader.dart';
import '../../../core/shared_widgets/error_view.dart';
import '../controllers/movie_search_controller.dart';
import '../controllers/search_paginated_movies_provider.dart';

class MultiProgramsSearchGrid extends HookConsumerWidget {
  const MultiProgramsSearchGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchedMultiProgramsCount =
        ref.watch(searchMultiProgramsCountProvider);
    final pageBucket = useMemoized(() => PageStorageBucket());

    return PageStorage(
      bucket: pageBucket,
      child: searchedMultiProgramsCount.map(
        data: (asyncData) {
          return _MultiProgramsSearchGridWidget(
            totalItems: asyncData.value,
          );
        },
        error: (e) {
          if (e.error is DioError) {
            final DioError dioError = e.error as DioError;

            if (dioError.response != null &&
                dioError.response?.data['errors']
                    .contains('query must be provided')) {
              return SearchErrorWidget(
                  message: context.localisations.trySearchingForMovieOrTvShow);
            }
          } else if (e.error is GeneralException) {
            final GeneralException generalException =
                e.error as GeneralException;

            if (generalException.code == AppErrorCodes.noItems) {
              return SearchErrorWidget(message: generalException.message!);
            }
          }
          return const ErrorView();
        },
        loading: (_) => const AppLoader(),
      ),
    );
  }
}

class _MultiProgramsSearchGridWidget extends HookConsumerWidget {
  const _MultiProgramsSearchGridWidget({
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
    final isFocused = useState(false);

    // Scroll controller for multi programs grid
    final multiProgramsScrollController = useScrollController();

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
              // Navigate up in multi programs grid
              isFocused.value = true;
              final newIndex = currentFocusedIndex.value - crossAxisCount;
              if (newIndex >= 0 && totalItems > 0) {
                currentFocusedIndex.value = newIndex;
                _scrollToMultiProgramItem(
                  currentFocusedIndex.value,
                  totalItems,
                  multiProgramsScrollController,
                  crossAxisCount,
                );
                return true;
              }
              isFocused.value = false;
              return false;

            case LogicalKeyboardKey.arrowDown:
              // Navigate down in multi programs grid
              isFocused.value = true;
              final newIndex = currentFocusedIndex.value + crossAxisCount;
              if (newIndex < totalItems) {
                currentFocusedIndex.value = newIndex;
                _scrollToMultiProgramItem(
                  currentFocusedIndex.value,
                  totalItems,
                  multiProgramsScrollController,
                  crossAxisCount,
                );
              }
              return true;

            case LogicalKeyboardKey.arrowLeft:
              // Navigate left in multi programs grid
              isFocused.value = true;
              if (currentFocusedIndex.value % crossAxisCount > 0) {
                currentFocusedIndex.value--;
                return true;
              }
              isFocused.value = false;
              return false;

            case LogicalKeyboardKey.arrowRight:
              // Navigate right in multi programs grid
              isFocused.value = true;
              if ((currentFocusedIndex.value + 1) % crossAxisCount != 0 &&
                  currentFocusedIndex.value + 1 < totalItems) {
                currentFocusedIndex.value++;
              }
              return true;

            case LogicalKeyboardKey.select:
            case LogicalKeyboardKey.enter:
              // Navigate to multi program detail (handled by MultiProgramTile)
              return false;
          }
        }
        return false;
      },
      [totalItems, currentFocusedIndex.value],
    );

    // Watch for keyword changes and reset scroll/focus
    final keyword = ref.watch(searchKeywordProvider);
    useEffect(() {
      // Reset scroll position and focused index when keyword changes
      currentFocusedIndex.value = 0;
      isFocused.value = false;

      // Reset scroll position immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (multiProgramsScrollController.hasClients) {
          multiProgramsScrollController.jumpTo(0.0);
        }
      });

      return null;
    }, [keyword]);

    // Set up initial focus
    useEffect(() {
      if (totalItems > 0) {
        currentFocusedIndex.value = 0;
        // Only request focus if the grid is actually focused
        if (isFocused.value) {
          Future.microtask(() {
            if (focusNodes.isNotEmpty) {
              focusNodes[0].requestFocus();
            }
          });
        }
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
        controller: multiProgramsScrollController,
        itemCount: totalItems,
        crossAxisCount: ResponsiveWidget.isMediumScreen(context)
            ? 3
            : ResponsiveWidget.isSmallScreen(context)
                ? 2
                : 6,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        itemBuilder: (BuildContext context, int index) {
          final AsyncValue<dynamic> currentShow = ref
              .watch(paginatedMultiProgramsProvider(PaginatedSearchProviderArgs(
                  page: index ~/ 20, query: ref.watch(searchKeywordProvider))))
              .whenData((pageData) => pageData.results[index % 20]);

          return ProviderScope(
            overrides: [
              currentMultiProgramProvider.overrideWithValue(currentShow)
            ],
            child: MultiProgramTile(
              autofocus: false,
              focusNode: focusNodes[index],
              isFocused: isFocused.value && currentFocusedIndex.value == index,
            ),
          );
        },
      ),
    );
  }

  void _scrollToMultiProgramItem(
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

class SearchErrorWidget extends StatelessWidget {
  const SearchErrorWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.search,
          size: 100,
          color: kPrimaryColor,
        ),
        verticalSpaceRegular,
        Text(message),
      ],
    );
  }
}
