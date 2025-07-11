import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/constants/colors.dart';
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
    final listViewKey =
        useMemoized(() => GlobalKey(debugLabel: "categoryListViewKey"));
    final topMostItemNode = useFocusNode();
    final bottomMostItemNode = useFocusNode();
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (isChildrenFocused) {
          log("Focus changed: $isChildrenFocused");
          if (isChildrenFocused) {
            // If the sidebar is focused, request focus on the first item
            topMostItemNode.requestFocus();
          } else {
            // If the sidebar is not focused, unfocus all items
            topMostItemNode.unfocus();
            bottomMostItemNode.unfocus();
          }
        },
        onKey: (node, RawKeyEvent event) {
          if (event.runtimeType == RawKeyDownEvent &&
              (event.isKeyPressed(LogicalKeyboardKey.arrowUp) ||
                  event.isKeyPressed(LogicalKeyboardKey.arrowDown))) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown) &&
                bottomMostItemNode.hasPrimaryFocus) {
              return KeyEventResult.handled;
            }
            if (event.isKeyPressed(LogicalKeyboardKey.arrowUp) &&
                topMostItemNode.hasPrimaryFocus) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: ListView.builder(
          itemCount: genres.length,
          key: listViewKey,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final genre = genres[index];
            return ListTile(
              horizontalTitleGap: 0,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              style: ListTileStyle.drawer,
              title: Text(genre.name ?? ''),
              onTap: () {
                onGenreSelected(genre);
              },
              focusNode: index == 0
                  ? topMostItemNode
                  : index == genres.length - 1
                      ? bottomMostItemNode
                      : null,
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
    );
  }
}
