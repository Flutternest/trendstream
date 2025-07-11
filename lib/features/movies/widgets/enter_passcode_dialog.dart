import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/core/services/shared_preferences_service.dart';
import 'package:latest_movies/core/shared_widgets/shake_animation_builder.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';

import '../../../core/shared_widgets/app_keyboard/numeric_keyboard.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

/// FOR [ADULT CONTENT] ONLY
///
/// This dialog is used to enter the passcode to access adult content
///
/// Returns [true] if the passcode is correct in the navigator response
class EnterPasscodeDialog extends StatefulHookConsumerWidget {
  const EnterPasscodeDialog({super.key});

  @override
  ConsumerState<EnterPasscodeDialog> createState() =>
      _EnterPasscodeDialogState();
}

class _EnterPasscodeDialogState extends ConsumerState<EnterPasscodeDialog> {
  late final passcodeCtrl = TextEditingController();
  bool isPasscodeCorrect = false;
  String passcode = "";

  final shakeErrorAnimationCtrl = ShakeErrorController();

  @override
  void dispose() {
    super.dispose();
    passcodeCtrl.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kBackgroundColor,
      child: FocusScope(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(context.localisations.adultContentPassDesc),
              verticalSpaceRegular,
              Center(
                child: ShakeErrorAnimation(
                  controller: shakeErrorAnimationCtrl,
                  child: Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          height: 60,
                          width: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            passcode.length > index ? passcode[index] : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              verticalSpaceSmall,
              if (mounted &&
                  passcodeCtrl.text.length == 4 &&
                  !isPasscodeCorrect) ...[
                Text(
                  context.localisations.incorrectPassword,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                verticalSpaceSmall,
              ],
              Expanded(
                child: FittedBox(
                  child: NumericKeyboard(
                    autofocus: true,
                    mainAxisAlignment: MainAxisAlignment.center,
                    maxLength: 4,
                    onValueChanged: (newVal) {
                      log("New passcode value: $newVal");
                      passcodeCtrl.text = newVal;
                      isPasscodeCorrect = false;
                      passcode = newVal;
                      if (passcodeCtrl.text.length == 4) {
                        String passcode = ref
                                .read(sharedPreferencesServiceProvider)
                                .sharedPreferences
                                .getString(SharedPreferencesService
                                    .adultContentPasscode) ??
                            "";
                        if (passcodeCtrl.text == passcode) {
                          isPasscodeCorrect = true;
                        } else {
                          shakeErrorAnimationCtrl.trigger();
                        }
                      }
                      setState(() {});
                      if (isPasscodeCorrect) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
