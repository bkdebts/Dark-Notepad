import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onMenuPressed;
  final double height;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  
  const CustomAppBar({
    Key? key,
    this.title,
    this.actions,
    this.onMenuPressed,
    this.height = kToolbarHeight,
    this.leading,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);
  
  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.backgroundColor,
      elevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ?? (onMenuPressed != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
            )
          : null),
      title: title != null
          ? Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall,
            )
          : null,
      actions: actions,
    );
  }
}
