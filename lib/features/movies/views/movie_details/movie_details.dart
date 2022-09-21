import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/shared_widgets/app_loader.dart';
import 'package:latest_movies/core/shared_widgets/error_view.dart';
import 'package:latest_movies/core/shared_widgets/image.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import '../../../../../core/router/_app_router.dart';
import '../../../../core/config/config.dart';
import '../../../../core/router/_routes.dart';
import '../../../../core/shared_widgets/button.dart';
import '../../../../core/utilities/debouncer.dart';
import '../../controllers/movie_details_provider.dart';

class MovieDetailsView extends HookConsumerWidget {
  const MovieDetailsView({super.key});

  final posterContainerHeight = 450.0;
  final trailerContainerHeight = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieId =
        useMemoized(() => ModalRoute.of(context)!.settings.arguments as int);
    final movieDetailsAsync = ref.watch(movieDetailsProvider(movieId));

    return Scaffold(
      body: movieDetailsAsync.when(
        data: (movie) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "${Configs.baseImagePath}${movie.posterPath}",
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: ColoredBox(
              color: Colors.black.withOpacity(.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_left),
                    onPressed: () {
                      Debouncer(delay: const Duration(milliseconds: 500))
                          .call(() {
                        AppRouter.pop();
                      });
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(40.0),
                    height: posterContainerHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: posterContainerHeight - 40,
                          width: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.7),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: AppImage(
                                imageUrl:
                                    "${Configs.baseImagePath}${movie.posterPath}",
                                //todo: add a not available image in case there's no image
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                validString(movie.originalTitle),
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                validString(movie.tagline),
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.yellow,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        (movie.voteAverage ?? 0.0)
                                            .toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "(${movie.voteCount})",
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Text(
                                  //   " | ",
                                  //   style: TextStyle(
                                  //     fontSize: 14.0,
                                  //     color: Colors.grey[500],
                                  //     fontWeight: FontWeight.w500,
                                  //   ),
                                  // ),
                                  // Row(
                                  //   crossAxisAlignment: CrossAxisAlignment.start,
                                  //   children: [
                                  //     Text(
                                  //       "IMDb: ",
                                  //       style: TextStyle(
                                  //         fontSize: 14.0,
                                  //         color: Colors.grey[500],
                                  //         fontWeight: FontWeight.w500,
                                  //       ),
                                  //     ),
                                  //     const SizedBox(width: 5),
                                  //     const Text(
                                  //       "8.8/10",
                                  //       style: TextStyle(
                                  //         fontSize: 14.0,
                                  //         color: Colors.white,
                                  //         fontWeight: FontWeight.w500,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${(movie.adult ?? false) ? "18+ | " : ""}${movie.genres?.map((e) => e.name).join(" / ")} | ${movie.spokenLanguages?.map((e) => e.name).join(", ")} | ${movie.releaseDate?.split("-").first}",
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                validString(movie.overview),
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              const Expanded(child: SizedBox()),
                              Row(
                                children: [
                                  AppButton(
                                    text: "Watch Now",
                                    onTap: () {
                                      AppRouter.navigateToPage(
                                          Routes.playerView);
                                    },
                                    prefix: const Icon(
                                      Icons.play_circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  horizontalSpaceRegular,
                                  AppButton(
                                    text: "Watch Trailer",
                                    onTap: () {
                                      AppRouter.navigateToPage(
                                          Routes.playerView);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const AppLoader(),
        error: (error, stack) => const ErrorView(),
      ),
    );
  }
}
