import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/app_loader.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/core/shared_widgets/genre_selector.dart';
import 'package:latest_movies/features/movies/controllers/current_adult_show_controller.dart';
import 'package:latest_movies/features/movies/controllers/genre_list_provider.dart';
import 'package:latest_movies/features/movies/widgets/adult_show_item.dart';

import '../../../core/utilities/responsive.dart';

class AdultGrid extends HookConsumerWidget {
  const AdultGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncGenres = ref.watch(genreListProvider);
    final selectedGenre = ref.watch(selectedAdultGenreProvider);
    final isGenreSelectorCollapsed = useState(false);
    return asyncGenres.when(
      data: (genres) {
        final genreGlobalKeys = genres.map((genre) => GlobalKey()).toList();
        final genreSidebarScrollController = useScrollController();
        return Row(
          children: [
            GenreSelector(
              genres: genres,
              selectedGenre: selectedGenre,
              onGenreSelected: (genre) {
                ref.read(selectedAdultGenreProvider.notifier).state = genre;
                Future.microtask(() {
                  ref.invalidate(currentAdultShowProvider);
                });
              },
              isCollapsed: isGenreSelectorCollapsed,
              scrollController: genreSidebarScrollController,
              genreGlobalKeys: genreGlobalKeys,
            ),
            Expanded(
              child: AlignedGridView.count(
                key: const PageStorageKey<String>(
                    'preserve_adultcontent_grid_scroll_and_focus'),
                itemCount: 40,
                crossAxisCount: ResponsiveWidget.isMediumScreen(context)
                    ? 3
                    : ResponsiveWidget.isSmallScreen(context)
                        ? 2
                        : 4,
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                itemBuilder: (BuildContext context, int index) {
                  return ProviderScope(
                    overrides: [
                      currentAdultShowProvider
                          .overrideWithValue(AsyncValue.data(index))
                    ],
                    child: AdultShowItem(autofocus: index == 0),
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) => const ErrorView(),
      loading: () => const AppLoader(),
    );
  }
}
