import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/features/movies/constants.dart';
import 'package:latest_movies/features/movies/views/movies_dashboard/search/live_channels_search_grid.dart';
import 'package:latest_movies/features/movies/views/movies_dashboard/search/tv_show_search_grid.dart';
import 'package:latest_movies/features/movies/widgets/multi_programs_search_grid.dart';
import 'package:latest_movies/features/movies/widgets/search_grid.dart';

import '../../../../../core/shared_widgets/app_keyboard/app_keyboard.dart';
import '../../../../tv_guide/views/tv_guide/tv_guide.dart';
import '../../../controllers/movie_search_controller.dart';
import '../../../controllers/search_type_provider.dart';
import '../../../enums/search_type.dart';

class SearchPage extends HookConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyword = ref.watch(searchKeywordProvider);
    final searchType = ref.watch(searchTypeProvider);
    final previewController = useRef<VlcPlayerController?>(null);

    return FocusTraversalGroup(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AppOnScreenKeyboard(
                    onValueChanged: (value) {
                      ref
                          .read(searchKeywordProvider.notifier)
                          .setKeyword(value);
                    },
                    focusColor: kPrimaryColor,
                  ),
                ),
                Visibility(
                  visible: searchType == SearchType.liveChannels,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    // child: SizedBox.expand(
                    //   child: ColoredBox(color: Colors.black, child: Center(child: Text("Live Preview"),)),
                    // ),
                    child: PreviewPlayer(
                      onControllerInitialized: (controller) {
                        previewController.value = controller;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          horizontalSpaceRegular,
          Expanded(
            flex: 6,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 8,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: kPrimaryColor.withOpacity(.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search),
                            horizontalSpaceSmall,
                            Text(
                              keyword.isEmpty
                                  ? "Search for movies or tv shows..."
                                  : keyword,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: keyword.isEmpty
                                      ? Colors.grey[600]
                                      : Colors.white),
                            )
                          ],
                        ),
                      ),
                    ),
                    horizontalSpaceSmall,
                    Flexible(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: kPrimaryColor.withOpacity(.2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: kBackgroundColor,
                              icon: const Icon(Icons.filter_list),
                              iconEnabledColor: kPrimaryAccentColor,
                              style: const TextStyle(color: Colors.white),
                              value: getSearchTypeString(searchType),
                              items: [
                                DropdownMenuItem(
                                  value: SearchTypeConstants.all,
                                  child: Text(
                                    "All",
                                    style: TextStyle(
                                      color: searchType == SearchType.all
                                          ? kPrimaryAccentColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SearchTypeConstants.movie,
                                  child: Text(
                                    "Movies",
                                    style: TextStyle(
                                      color: searchType == SearchType.movies
                                          ? kPrimaryAccentColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SearchTypeConstants.tvShows,
                                  child: Text(
                                    "TV Shows",
                                    style: TextStyle(
                                        color: searchType == SearchType.tvShows
                                            ? kPrimaryAccentColor
                                            : Colors.white),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: SearchTypeConstants.liveChannels,
                                  child: Text(
                                    "Live Channels",
                                    style: TextStyle(
                                        color: searchType ==
                                                SearchType.liveChannels
                                            ? kPrimaryAccentColor
                                            : Colors.white),
                                  ),
                                ),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue == null) return;

                                ref.watch(searchTypeProvider.state).state =
                                    getSearchTypeFromString(newValue);

                                if (previewController
                                        .value?.value.isInitialized ??
                                    false) {
                                  if (newValue ==
                                      SearchTypeConstants.liveChannels) {
                                    previewController.value?.play();
                                  } else {
                                    previewController.value?.stop();
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                verticalSpaceRegular,
                Expanded(
                  child: FocusTraversalGroup(
                    child: Builder(builder: (context) {
                      Widget child;
                      switch (searchType) {
                        case SearchType.all:
                          child = const MultiProgramsSearchGrid();
                          break;
                        case SearchType.movies:
                          child = const MovieSearchGrid();
                          break;
                        case SearchType.tvShows:
                          child = const TvShowSearchGrid();
                          break;
                        case SearchType.liveChannels:
                          child = const LiveChannelsSearchGrid();
                          break;
                      }
                      return child;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
