import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  });

  final Genre? selectedGenre;
  final List<Genre> genres;
  final Function(Genre) onGenreSelected;

  @override
  Widget build(BuildContext context) {
    final isCollapsed = useState(false);
    final listViewKey =
        useMemoized(() => GlobalKey(debugLabel: "categoryListViewKey"));

    final widgetItemNode = useFocusNode();
    final itemFocusNodes = useMemoized(
      () => List.generate(genres.length, (_) => FocusNode()),
      [genres.length],
    );
    final topMostItemNode = itemFocusNodes.first;
    final bottomMostItemNode = itemFocusNodes.last;
    return Column(
      children: [
        if (!isCollapsed.value) ...[
          Text(
            "Categories",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          verticalSpaceMedium,
        ],
        Expanded(
          child: Focus(
            canRequestFocus: true,
            skipTraversal: false,
            focusNode: widgetItemNode,
            onFocusChange: (isChildrenFocused) {
              log("Focus changed 12: $isChildrenFocused");
              if (isChildrenFocused) {
                isCollapsed.value = false;
                widgetItemNode.requestFocus();
                topMostItemNode.requestFocus();
              } else {
                topMostItemNode.unfocus();
                bottomMostItemNode.unfocus();
              }
            },
            onKeyEvent: (node, KeyEvent event) {
              if (event.runtimeType == KeyDownEvent) {
                if (HardwareKeyboard.instance
                    .isLogicalKeyPressed(LogicalKeyboardKey.arrowRight)) {
                  isCollapsed.value = true;
                }

                if (HardwareKeyboard.instance
                        .isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) &&
                    bottomMostItemNode.hasPrimaryFocus) {
                  return KeyEventResult.handled;
                }
                if (HardwareKeyboard.instance
                        .isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) &&
                    topMostItemNode.hasPrimaryFocus) {
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
              child: ListView.builder(
                itemCount: genres.length,
                key: listViewKey,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return ListTile(
                    horizontalTitleGap: 0,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 0.0),
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    style: ListTileStyle.drawer,
                    title: Text(genre.name ?? ''),
                    onTap: () {
                      onGenreSelected(genre);
                    },
                    focusNode: itemFocusNodes[index],
                    selectedTileColor: kPrimaryColor.withOpacity(.6),
                    focusColor: kPrimaryColor.withOpacity(.3),
                    selected: selectedGenre?.id == genre.id,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
