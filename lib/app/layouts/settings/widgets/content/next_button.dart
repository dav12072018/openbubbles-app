import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:bluebubbles/helpers/ui/theme_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => settingsSkin(context) != Skins.Material ? Icon(
        settingsSkin(context) != Skins.Material
            ? CupertinoIcons.chevron_right
            : Icons.arrow_forward,
        color: context.theme.colorScheme.outline.withOpacity(0.5),
        size: 18,
      ) : const SizedBox.shrink());
  }
}