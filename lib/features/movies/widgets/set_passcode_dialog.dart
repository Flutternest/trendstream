import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/extensions/context_extension.dart';
import 'package:latest_movies/core/utilities/design_utility.dart';

import '../../../core/services/shared_preferences_service.dart';
import '../../../core/shared_widgets/app_keyboard/numeric_keyboard.dart';

class SetPasscodeDialog extends HookConsumerWidget {
  const SetPasscodeDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passcodeCtrl = useTextEditingController();
    final passcode = useState('');
    return Dialog(
      backgroundColor: kBackgroundColor,
      child: FocusScope(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.localisations.setAdultContentPassDesc),
              verticalSpaceRegular,
              Center(
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
                          passcode.value.length > index
                              ? passcode.value[index]
                              : '',
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
              Expanded(
                child: FittedBox(
                  child: NumericKeyboard(
                    autofocus: true,
                    mainAxisAlignment: MainAxisAlignment.center,
                    maxLength: 4,
                    onValueChanged: (newVal) {
                      passcodeCtrl.text = newVal;
                      passcode.value = newVal;
                    },
                    onDoneTap: () async {
                      if (passcodeCtrl.text.isEmpty) {
                        return;
                      }

                      final navigator = Navigator.of(context);

                      await ref
                          .read(sharedPreferencesServiceProvider)
                          .sharedPreferences
                          .setString(
                              SharedPreferencesService.adultContentPasscode,
                              passcodeCtrl.text);
                      await ref
                          .read(sharedPreferencesServiceProvider)
                          .sharedPreferences
                          .setBool(
                              SharedPreferencesService.isPasscodeSet, true);

                      navigator.pop(true);
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
