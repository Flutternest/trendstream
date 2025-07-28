import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/features/movies/models/movie/genre.dart';
import 'package:latest_movies/features/movies/widgets/movies_grid.dart';

class GenreSelector extends HookWidget {
  const GenreSelector({
    super.key,
    this.selectedGenre,
    required this.genres,
    required this.onGenreSelected,
    required this.isCollapsed,
  });

  final Genre? selectedGenre;
  final List<Genre> genres;
  final Function(Genre) onGenreSelected;
  final ValueNotifier<bool> isCollapsed;

  @override
  Widget build(BuildContext context) {
    final listViewKey =
        useMemoized(() => GlobalKey(debugLabel: "categoryListViewKey"));
    final focusNodes = useMemoized(
      () => List.generate(genres.length, (index) => FocusNode()),
    );
    final topMostItemNode = focusNodes[0];
    final bottomMostItemNode = focusNodes[1];
    return SizedBox(
      height: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Focus(
          canRequestFocus: true,
          skipTraversal: false,
          onFocusChange: (value) {
            if (value) {
              isCollapsed.value = false;
            }
          },
          onKeyEvent: (node, KeyEvent event) {
            log("onKeyEvent(GenreSelector): $event - ${event.runtimeType} topMostItemNode: ${topMostItemNode.hasFocus} bottomMostItemNode: ${bottomMostItemNode.hasFocus}");
            printWidgetTreeAroundFocus();
            if (event.runtimeType == KeyDownEvent) {
              if (HardwareKeyboard.instance
                  .isLogicalKeyPressed(LogicalKeyboardKey.arrowRight)) {
                isCollapsed.value = true;
                return KeyEventResult.handled;
              }
              if (HardwareKeyboard.instance
                      .isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) &&
                  bottomMostItemNode.hasFocus) {
                return KeyEventResult.handled;
              }
              if (HardwareKeyboard.instance
                      .isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) &&
                  topMostItemNode.hasFocus) {
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            }
            return KeyEventResult.ignored;
          },
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
                    return ListTile(
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
                      title: Text(genre.name ?? ''),
                      onTap: () {
                        onGenreSelected(genre);
                      },
                      focusNode: focusNodes[index],
                      selectedTileColor: kPrimaryColor.withOpacity(.6),
                      focusColor: kPrimaryColor.withOpacity(.3),
                      selected: selectedGenre?.id == genre.id,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
