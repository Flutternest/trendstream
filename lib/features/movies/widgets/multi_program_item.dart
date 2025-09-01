import "package:flutter/material.dart";
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/features/movies/controllers/current_multi_program_provider.dart';
import 'package:latest_movies/features/movies/models/movie/movie.dart';
import 'package:latest_movies/features/movies/models/tv_show/tv_show.dart';
import 'package:latest_movies/features/movies/widgets/movie_item.dart';
import 'package:latest_movies/features/movies/widgets/tv_show_item.dart';

import '../../../core/utilities/design_utility.dart';

class RawPlaceholderItem extends StatelessWidget {
  const RawPlaceholderItem({
    super.key,
    required this.autofocus,
    required this.focusNode,
    required this.isFocused,
    this.onFocusChanged,
    this.placeholderType = PlaceholderType.loading,
  });

  final bool autofocus;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;
  final PlaceholderType placeholderType;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: autofocus,
      focusNode: focusNode,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        // No action for placeholder items
      },
      onFocusChange: onFocusChanged,
      child: Builder(builder: (context) {
        final bool hasFocus = Focus.of(context).hasPrimaryFocus || isFocused;
        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(.4),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, 1)),
                    ],
                    border: hasFocus
                        ? Border.all(
                            width: 4,
                            color: kPrimaryAccentColor,
                          )
                        : null,
                  ),
                  child: Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: placeholderType == PlaceholderType.loading
                          ? const CircularProgressIndicator()
                          : Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                    ),
                  ),
                ),
              ),
              verticalSpaceRegular,
              Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 14,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

enum PlaceholderType { loading, error }

class MultiProgramTile extends HookConsumerWidget {
  const MultiProgramTile({
    this.autofocus = false,
    required this.focusNode,
    required this.isFocused,
    Key? key,
  }) : super(key: key);

  final bool autofocus;
  final FocusNode focusNode;
  final bool isFocused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<dynamic> programAsync =
        ref.watch(currentMultiProgramProvider);

    return programAsync.map(
      data: (asyncData) {
        var show = asyncData.value;
        if (show is Movie) {
          return RawMovieTile(
            autofocus: autofocus,
            movie: show,
            focusNode: focusNode,
            isFocused: isFocused,
          );
        } else if (show is TvShow) {
          return RawTvShowItem(
            autofocus: autofocus,
            show: show,
            focusNode: focusNode,
            isFocused: isFocused,
          );
        }
        return const SizedBox.shrink();
      },
      error: (e) => RawPlaceholderItem(
        autofocus: autofocus,
        focusNode: focusNode,
        isFocused: isFocused,
        placeholderType: PlaceholderType.error,
      ),
      loading: (_) => RawPlaceholderItem(
        autofocus: autofocus,
        focusNode: focusNode,
        isFocused: isFocused,
        placeholderType: PlaceholderType.loading,
      ),
    );
  }
}
