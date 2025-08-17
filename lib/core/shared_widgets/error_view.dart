import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';

class ErrorView extends HookWidget {
  const ErrorView({
    Key? key,
    this.error,
    this.onRetry,
  }) : super(key: key);

  final String? error;

  final Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final retryButtonFocusNode = useFocusNode();

    // Ensure the retry button gets focus when the error view is displayed
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        retryButtonFocusNode.requestFocus();
      });
      return null;
    }, []);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, size: 40),
          verticalSpaceSmall,
          Text(error ?? context.localisations.somethingWentWrong),
          if (onRetry != null) ...[
            verticalSpaceSmall,
            ElevatedButton(
              focusNode: retryButtonFocusNode,
              onPressed: onRetry,
              child: Text(context.localisations.retry),
            ),
          ],
        ],
      ),
    );
  }
}
