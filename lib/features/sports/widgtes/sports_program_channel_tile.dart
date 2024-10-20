import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

class SportsProgramChannelTile extends StatelessWidget {
  const SportsProgramChannelTile({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      focusColor: Colors.transparent ,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasPrimaryFocus;
          return Container(
            decoration: BoxDecoration(
              color: isFocused ? Colors.white : isSelected ? kPrimaryColor : Colors.transparent,
              border: const Border(
                left: BorderSide(
                  color: kBackgroundColor,
                  width: 1.5,
                ),
                right: BorderSide(
                  color: kBackgroundColor,
                  width: 1.5,
                ),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Center(
              child: Text(
                title,
                style: TextStyle(color: isFocused ? Colors.black : null),
              ),
            ),
          );
        },
      ),
    );
  }
}
