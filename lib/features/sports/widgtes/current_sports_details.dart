import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/shared_widgets/mini_player_widget.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';
import 'package:latest_movies/features/sports/controllers/current_focused_program_controller.dart';

class CurrentSportsDetails extends ConsumerWidget {
  const CurrentSportsDetails({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedEvent = ref.watch(currentFocusedEventController);

    if (focusedEvent == null) {
      return const Center(
        child: Text("Focus on an event to see details"),
      );
    }

    return Row(
      children: [
        Container(
          height: 150,
          padding: const EdgeInsets.all(2),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              focusedEvent.poster!,
              fit: BoxFit.contain,
            ),
          ),
        ),
        horizontalSpaceRegular,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                focusedEvent.name ?? "N/A",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: kPrimaryAccentColor),
              ),
              verticalSpaceSmall,
              Text(
                focusedEvent.category?.name ?? "N/A",
                style: textTheme(context)
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              verticalSpaceTiny,
              Text(
                  "${DateFormat("dd MMM, yyyy").format(focusedEvent.eventDate!)} at ${DateFormat("HH:mm a").format(focusedEvent.eventDate!)}"),
            ],
          ),
        ),
        const SizedBox(
          height: 150,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: MiniPlayerWidget(
              videoUrl:
                  'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
            ),
          ),
        ),
      ],
    );
  }
}
