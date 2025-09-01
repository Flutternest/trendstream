import 'dart:developer';

import "package:flutter/material.dart";
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/router/router.dart';
import 'package:latest_movies/features/movies/controllers/current_popular_movies_provider.dart';

import '../../../../core/utilities/design_utility.dart';
import '../../../core/config/config.dart';
import '../../../core/shared_widgets/image.dart';
import '../models/movie/movie.dart';

class MovieTile extends HookConsumerWidget {
  const MovieTile({
    this.autofocus = false,
    Key? key,
    required this.index,
    required this.focusNode,
    this.isFocused = false,
    this.onFocusChanged,
    this.onMovieSelected,
  }) : super(key: key);

  final bool autofocus;
  final int index;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;
  final Function(Movie movie)? onMovieSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RawAsyncMovieTile(
      autofocus: autofocus,
      focusNode: focusNode,
      isFocused: isFocused,
      onFocusChanged: onFocusChanged,
      onMovieSelected: onMovieSelected,
    );

    //   final AsyncValue<Movie> movieAsync = ref.watch(currentPopularMovieProvider);

    //   return movieAsync.map(
    //     data: (asyncData) {
    //       final movie = asyncData.value;
    //       return RawMovieTile(
    //         autofocus: autofocus,
    //         movie: movie,
    //       );
    //     },
    //     error: (e) => const ErrorView(),
    //     loading: (_) => const AppLoader(),
    //   );
  }
}

class RawMovieTile extends StatelessWidget {
  const RawMovieTile({
    super.key,
    required this.autofocus,
    required this.focusNode,
    required this.isFocused,
    required this.movie,
    this.onFocusChanged,
    this.onMovieSelected,
  });

  final bool autofocus;
  final FocusNode focusNode;
  final bool isFocused;
  final Movie movie;
  final ValueChanged<bool>? onFocusChanged;
  final Function(Movie movie)? onMovieSelected;

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
        log('MovieTile: onTap called');

        log('MovieTile: movie: $movie');
        log('MovieTile: movie.id: ${movie.id}');
        log('MovieTile: movie.title: ${movie.title}');

        final movieId = movie.id;
        log('MovieTile: onTap called with movieId: $movieId');
        if (movieId != null) {
          if (onMovieSelected != null) {
            log('MovieTile: calling onMovieSelected callback with movieId: $movieId');
            onMovieSelected!(movie);
          } else {
            log('MovieTile: calling AppRouter.navigateToPage with movieId: $movieId');
            AppRouter.navigateToPage(Routes.detailsView,
                arguments: {'id': movieId, 'movie': movie});
          }
        } else {
          log('MovieTile: movieId is null');
        }
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
                  // height: 250,
                  // width: double.infinity,
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
                  child: AppImage(
                    imageUrl:
                        "${Configs.largeBaseImagePath}${movie.posterPath}",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              verticalSpaceRegular,
              Text(
                validString(movie.title.toString()),
                style: TextStyle(
                    fontSize: 14,
                    color: hasFocus ? Colors.white : Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                validString(
                    movie.releaseDate != null && movie.releaseDate!.isNotEmpty
                        ? DateFormat("dd MMM yyyy").format(
                            DateFormat("yyyy-MM-dd").parse(movie.releaseDate!))
                        : null),
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                "⭐️ ${validString(movie.voteAverage.toString())}",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class RawAsyncMovieTile extends ConsumerWidget {
  const RawAsyncMovieTile({
    super.key,
    required this.autofocus,
    required this.focusNode,
    required this.isFocused,
    this.onFocusChanged,
    this.onMovieSelected,
  });

  final bool autofocus;
  final FocusNode focusNode;
  final bool isFocused;
  final ValueChanged<bool>? onFocusChanged;
  final Function(Movie movie)? onMovieSelected;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Movie> movieAsync = ref.watch(currentPopularMovieProvider);

    return movieAsync.when(
        data: (movie) {
          return InkWell(
            autofocus: autofocus,
            focusNode: focusNode,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            focusColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              log('MovieTile: movie: $movie');
              log('MovieTile: movie.id: ${movie.id}');
              log('MovieTile: movie.title: ${movie.title}');

              final movieId = movie.id;
              log('MovieTile: onTap called with movieId: $movieId');
              if (movieId != null) {
                if (onMovieSelected != null) {
                  log('MovieTile: calling onMovieSelected callback with movieId: $movieId');
                  onMovieSelected!(movie);
                } else {
                  log('MovieTile: calling AppRouter.navigateToPage with movieId: $movieId');
                  AppRouter.navigateToPage(Routes.detailsView,
                      arguments: {'id': movieId, 'movie': movie});
                }
              } else {
                log('MovieTile: movieId is null');
              }
            },
            onFocusChange: onFocusChanged,
            child: Builder(builder: (context) {
              final bool hasFocus =
                  Focus.of(context).hasPrimaryFocus || isFocused;
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
                        // height: 250,
                        // width: double.infinity,
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
                        child: AppImage(
                          imageUrl:
                              "${Configs.largeBaseImagePath}${movie.posterPath}",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    verticalSpaceRegular,
                    Text(
                      validString(movie.title?.toString()),
                      style: TextStyle(
                          fontSize: 14,
                          color: hasFocus ? Colors.white : Colors.grey[700],
                          fontWeight:
                              hasFocus ? FontWeight.w700 : FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      validString(movie.releaseDate != null &&
                              movie.releaseDate!.isNotEmpty
                          ? DateFormat("dd MMM yyyy").format(
                              DateFormat("yyyy-MM-dd")
                                  .parse(movie.releaseDate!))
                          : null),
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight:
                              hasFocus ? FontWeight.w700 : FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "⭐️ ${validString(movie.voteAverage.toString())}",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight:
                              hasFocus ? FontWeight.w700 : FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          );
        },
        error: (_, __) => const SizedBox.shrink(),
        loading: () => const SizedBox.shrink());
  }
}
