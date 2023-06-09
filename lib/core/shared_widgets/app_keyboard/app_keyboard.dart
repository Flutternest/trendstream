import 'package:flutter/material.dart';
import 'package:latest_movies/core/constants/colors.dart';
import 'package:latest_movies/core/shared_widgets/app_keyboard/lowercase_keys.dart';
import 'package:latest_movies/core/shared_widgets/app_keyboard/symbol_keys.dart';
import 'package:latest_movies/core/shared_widgets/app_keyboard/uppercase_keys.dart';

import 'key_button.dart';
import 'only_number_keys.dart';

enum AppKeyboardType {
  uppercase,
  oneTimeUppercase,
  lowercase,
  symbols,
  onlyNumbers,
}

class AppKeyboardState {
  final AppKeyboardType keyboardType;
  final List<String> keys;

  AppKeyboardState(this.keyboardType, this.keys);
}

class AppOnScreenKeyboard extends StatefulWidget {
  const AppOnScreenKeyboard(
      {Key? key,
      required this.onValueChanged,
      this.focusColor,
      this.onlyNumbers = false})
      : super(key: key);

  final ValueChanged<String> onValueChanged;
  final Color? focusColor;
  final bool onlyNumbers;

  @override
  State<AppOnScreenKeyboard> createState() => _AppOnScreenKeyboardState();
}

class _AppOnScreenKeyboardState extends State<AppOnScreenKeyboard> {
  late final TextEditingController txtController = TextEditingController()
    ..addListener(textListener);

  late final ValueNotifier<AppKeyboardState> valueListenable = ValueNotifier(
      !widget.onlyNumbers
          ? keyboardStates[AppKeyboardType.lowercase]!
          : keyboardStates[AppKeyboardType.onlyNumbers]!);

  final shiftIndexNotifier = ValueNotifier<int>(0);

  final keyboardStates = {
    AppKeyboardType.uppercase:
        AppKeyboardState(AppKeyboardType.uppercase, upperCase),
    AppKeyboardType.oneTimeUppercase:
        AppKeyboardState(AppKeyboardType.oneTimeUppercase, upperCase),
    AppKeyboardType.lowercase:
        AppKeyboardState(AppKeyboardType.lowercase, lowerCase),
    AppKeyboardType.symbols: AppKeyboardState(AppKeyboardType.symbols, symbols),
    AppKeyboardType.onlyNumbers:
        AppKeyboardState(AppKeyboardType.onlyNumbers, numbers),
  };

  void textListener() {
    widget.onValueChanged(txtController.text);
    if (valueListenable.value.keyboardType ==
        AppKeyboardType.oneTimeUppercase) {
      valueListenable.value = keyboardStates[AppKeyboardType.lowercase]!;
      shiftIndexNotifier.value = 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
    txtController.removeListener(textListener);
    txtController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: ValueListenableBuilder(
              valueListenable: valueListenable,
              builder: (context, AppKeyboardState state, child) {
                return GridView.builder(
                  shrinkWrap: true,
                  itemCount: state.keys.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.onlyNumbers ? 3 : 5,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    return KeyboardKeyButton(
                      autofocus: index == 0,
                      focusColor: widget.focusColor,
                      buttonColor: kPrimaryColor.withOpacity(.2),
                      label: Text(
                        state.keys[index],
                        style: const TextStyle(fontSize: 25),
                      ),
                      onPressed: () {
                        txtController.text += state.keys[index];
                      },
                    );
                  },
                );
              }),
        ),
        const SizedBox(height: 5),
        if (!widget.onlyNumbers) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildBackspace(),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: buildKeyboardSwitch(),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Flexible(
                child: buildCaseToggle(),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: buildClear(),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: buildSpaceBar(),
              ),
            ],
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildBackspace(),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: buildClear(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  KeyboardKeyButton buildBackspace() {
    return KeyboardKeyButton(
      autofocus: false,
      focusColor: widget.focusColor,
      buttonColor: kPrimaryColor.withOpacity(.2),
      onPressed: () {
        if (txtController.text.isNotEmpty) {
          txtController.text =
              txtController.text.substring(0, txtController.text.length - 1);
        }
      },
      label: const Icon(
        Icons.backspace,
        size: 20,
      ),
    );
  }

  ValueListenableBuilder<AppKeyboardState> buildKeyboardSwitch() {
    return ValueListenableBuilder(
      valueListenable: valueListenable,
      builder: (context, AppKeyboardState state, child) {
        return KeyboardKeyButton(
          autofocus: false,
          focusColor: widget.focusColor,
          buttonColor: kPrimaryColor.withOpacity(.2),
          onPressed: () {
            if (state.keyboardType == AppKeyboardType.symbols) {
              valueListenable.value =
                  keyboardStates[AppKeyboardType.lowercase]!;
            } else {
              valueListenable.value = keyboardStates[AppKeyboardType.symbols]!;
            }
          },
          label: Text(
            state.keyboardType == AppKeyboardType.symbols ? 'ABC' : '123',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  ValueListenableBuilder<int> buildCaseToggle() {
    return ValueListenableBuilder(
      valueListenable: shiftIndexNotifier,
      builder: (context, value, child) {
        return KeyboardKeyButton(
          autofocus: false,
          focusColor: widget.focusColor,
          buttonColor: shiftIndexNotifier.value != 0
              ? Colors.white
              : kPrimaryColor.withOpacity(.2),
          onPressed: () {
            if (shiftIndexNotifier.value == 2) {
              shiftIndexNotifier.value = 0;
            } else {
              shiftIndexNotifier.value++;
            }

            if (shiftIndexNotifier.value == 0) {
              valueListenable.value =
                  keyboardStates[AppKeyboardType.lowercase]!;
            } else if (shiftIndexNotifier.value == 1) {
              valueListenable.value =
                  keyboardStates[AppKeyboardType.oneTimeUppercase]!;
            } else {
              valueListenable.value =
                  keyboardStates[AppKeyboardType.uppercase]!;
            }
          },
          label: Icon(
            shiftIndexNotifier.value == 2
                ? Icons.keyboard_double_arrow_up
                : Icons.arrow_upward,
            color: shiftIndexNotifier.value != 0 ? Colors.black : Colors.white,
          ),
        );
      },
    );
  }

  KeyboardKeyButton buildClear() {
    return KeyboardKeyButton(
      autofocus: false,
      focusColor: widget.focusColor,
      buttonColor: kPrimaryColor.withOpacity(.2),
      onPressed: () {
        txtController.clear();
      },
      label: const Text(
        'CLEAR',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  KeyboardKeyButton buildSpaceBar() {
    return KeyboardKeyButton(
      autofocus: false,
      focusColor: widget.focusColor,
      buttonColor: kPrimaryColor.withOpacity(.2),
      onPressed: () {
        txtController.text += ' ';
      },
      label: const Icon(
        Icons.space_bar,
        size: 35,
      ),
    );
  }
}
