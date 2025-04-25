import 'package:flutter/material.dart';

import '../utils/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  
  const LoadingIndicator({
    Key? key,
    this.size = 40,
    this.color,
    this.strokeWidth = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.primaryColor,
        ),
        strokeWidth: strokeWidth,
      ),
    );
  }
}
