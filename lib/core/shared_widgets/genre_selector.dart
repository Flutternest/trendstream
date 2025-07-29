import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';

class GenreSelector extends HookWidget {
  const GenreSelector({
    super.key,
    this.selectedGenre,
    required this.genres,
    required this.onGenreSelected,
    required this.isCollapsed,
    this.currentFocusedIndex = 0,
    this.isFocused = false,
  });

  final Genre? selectedGenre;
  final List<Genre> genres;
  final Function(Genre) onGenreSelected;
  final ValueNotifier<bool> isCollapsed;
  final int currentFocusedIndex;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final listViewKey =
        useMemoized(() => GlobalKey(debugLabel: "categoryListViewKey"));
    final focusNodes = useMemoized(
      () => List.generate(genres.length, (index) => FocusNode()),
    );

    // Set focus to current focused index when section becomes focused
    useEffect(() {
      if (isFocused && currentFocusedIndex < genres.length) {
        Future.microtask(() {
          focusNodes[currentFocusedIndex].requestFocus();
        });
      }
      return null;
    }, [isFocused, currentFocusedIndex, genres.length]);

    return SizedBox(
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: AnimatedContainer(
          width: isCollapsed.value ? 10 : 150,
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: isCollapsed.value
                    ? Colors.transparent
                    : Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: ListView(
              key: listViewKey,
              shrinkWrap: true,
              clipBehavior: Clip.hardEdge,
              children: [
                if (!isCollapsed.value) ...[
                  Text(
                    "Categories",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  verticalSpaceMedium,
                ],
                ...genres.indexed.map((value) {
                  final genre = value.$2;
                  final index = value.$1;
                  final isCurrentlyFocused =
                      isFocused && currentFocusedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isCurrentlyFocused
                          ? Colors.white.withOpacity(0.1)
                          : selectedGenre?.id == genre.id
                              ? kPrimaryColor.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentlyFocused
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: ListTile(
                      horizontalTitleGap: 0,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 0.0,
                      ),
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                      style: ListTileStyle.list,
                      title: Text(
                        genre.name ?? '',
                        style: TextStyle(
                          color: isCurrentlyFocused
                              ? Colors.white
                              : selectedGenre?.id == genre.id
                                  ? Colors.white
                                  : Colors.white70,
                          fontWeight: isCurrentlyFocused ||
                                  selectedGenre?.id == genre.id
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        onGenreSelected(genre);
                      },
                      focusNode: focusNodes[index],
                      selectedTileColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      selected: selectedGenre?.id == genre.id,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
