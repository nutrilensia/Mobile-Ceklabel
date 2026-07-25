import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable drag handle bar for bottom sheets.
/// Prevents duplicated Container(width:40,height:4,…) across screens.
class HandleBar extends StatelessWidget {
  const HandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textQuaternary(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
