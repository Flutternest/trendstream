import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/models/category_model.dart';

class CategorySidebar extends HookWidget {
  const CategorySidebar({
    super.key,
    this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  final CategoryModel? selectedCategory;
  final List<CategoryModel> categories;
  final Function(CategoryModel) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final listViewKey =
        useMemoized(() => GlobalKey(debugLabel: "categoryListViewKey"));
    final topMostItemNode = useFocusNode();
    final bottomMostItemNode = useFocusNode();
    return Container(
      width: 150,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (isChildrenFocused) {
          // if (isChildrenFocused) {
          //   ref.read(dashboardSidebarStatusProvider.notifier).state =
          //       DashboardSidebarStatus.expanded;
          // } else {
          //   ref.read(dashboardSidebarStatusProvider.notifier).state =
          //       DashboardSidebarStatus.collapsed;
          // }
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
          itemCount: categories.length,
          key: listViewKey,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(category.name),
                onTap: () {
                  onCategorySelected(category);
                },
                focusNode: index == 0
                    ? topMostItemNode
                    : index == categories.length - 1
                        ? bottomMostItemNode
                        : null,
                selectedTileColor: kPrimaryColor.withOpacity(.6),
                focusColor: kPrimaryColor.withOpacity(.3),
                selected: selectedCategory?.id == category.id,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
