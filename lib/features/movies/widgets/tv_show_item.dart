import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/features/movies/controllers/tv_shows_provider.dart';
import 'package:latest_movies/features/movies/models/tv_show/tv_show.dart';

import '../../../../core/utilities/design_utility.dart';
import "package:flutter/material.dart";

import '../../../core/config/config.dart';
import 'package:latest_movies/core/router/router.dart';
import '../../../core/shared_widgets/image.dart';

class TvShowTile extends HookConsumerWidget {
  const TvShowTile({
    this.autofocus = false,
    Key? key,
  }) : super(key: key);

  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RawAsyncTvShowTile(autofocus: autofocus);

    // final AsyncValue<TvShow> tvShowAsync =
    //     ref.watch(currentPopularTvShowProvider);

    // return tvShowAsync.map(
    //   data: (asyncData) {
    //     final show = asyncData.value;
    //     return RawTvShowItem(autofocus: autofocus, show: show);
    //   },
    //   error: (e) => const ErrorView(),
    //   loading: (_) => const AppLoader(),
    // );
  }
}

class RawTvShowItem extends StatelessWidget {
  const RawTvShowItem({
    super.key,
    required this.autofocus,
    required this.show,
  });

  final bool autofocus;
  final TvShow show;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      autofocus: autofocus,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        AppRouter.navigateToPage(Routes.tvShowDetailsView, arguments: show.id);
      },
      child: Builder(builder: (context) {
        final bool hasFocus = Focus.of(context).hasPrimaryFocus;
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
                  child: AppImage(
                    imageUrl: "${Configs.largeBaseImagePath}${show.posterPath}",
                  ),
                ),
              ),
              verticalSpaceRegular,
              Text(
                validString(
                    show.firstAirDate != null && show.firstAirDate!.isNotEmpty
                        ? DateFormat("dd MMM yyyy").format(
                            DateFormat("yyyy-MM-dd").parse(show.firstAirDate!))
                        : null),
                style: TextStyle(
                    fontSize: 14,
                    color: hasFocus ? Colors.white : Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                "⭐️ ${validString(show.voteAverage.toString())}",
                style: TextStyle(
                    fontSize: 14,
                    color: hasFocus ? Colors.white : Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class RawAsyncTvShowTile extends ConsumerWidget {
  const RawAsyncTvShowTile({
    super.key,
    required this.autofocus,
  });

  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TvShow> tvShowAsync =
        ref.watch(currentPopularTvShowProvider);

    return InkWell(
      autofocus: autofocus,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        if (tvShowAsync is! AsyncData) return;
        AppRouter.navigateToPage(Routes.tvShowDetailsView,
            arguments: tvShowAsync.asData!.value.id);
      },
      child: Builder(builder: (context) {
        final bool hasFocus = Focus.of(context).hasPrimaryFocus;
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
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: hasFocus
                        ? Border.all(
                            width: 4,
                            color: kPrimaryAccentColor,
                          )
                        : null,
                  ),
                  child: tvShowAsync.maybeWhen(
                    data: (show) {
                      return AppImage(
                        imageUrl:
                            "${Configs.largeBaseImagePath}${show.posterPath}",
                      );
                    },
                    orElse: () => null,
                  ),
                ),
              ),
              verticalSpaceRegular,
              Text(
                tvShowAsync.maybeWhen(
                    data: (show) => validString(show.firstAirDate != null &&
                            show.firstAirDate!.isNotEmpty
                        ? DateFormat("dd MMM yyyy").format(
                            DateFormat("yyyy-MM-dd").parse(show.firstAirDate!))
                        : null),
                    orElse: () => context.localisations.loading),
                style: TextStyle(
                    fontSize: 14,
                    color: hasFocus ? Colors.white : Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                "⭐️ ${tvShowAsync.maybeWhen(data: (show) => validString(show.voteAverage.toString()), orElse: () => context.localisations.loading)}",
                style: TextStyle(
                    fontSize: 14,
                    color: hasFocus ? Colors.white : Colors.grey[700],
                    fontWeight: hasFocus ? FontWeight.w700 : FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}
