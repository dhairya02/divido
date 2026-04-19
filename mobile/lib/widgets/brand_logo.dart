import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/brand.dart';

/// The Divido mark — the website's logo image, optionally followed by the
/// lime "Divido" wordmark (mirrors the header on the web app).
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.height = 32,
    this.showWordmark = true,
    this.wordmarkColor = BrandColors.accent,
  });

  final double height;
  final bool showWordmark;
  final Color wordmarkColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/divido-logo.png',
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        if (showWordmark) ...[
          const SizedBox(width: 8),
          Text(
            'Divido',
            style: GoogleFonts.ebGaramond(
              color: wordmarkColor,
              fontWeight: FontWeight.w700,
              fontSize: height * 0.7,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Sticky brand header — indigo bar with the logo + wordmark on the left and
/// optional trailing actions on the right. Used in lieu of a stock AppBar so
/// the look matches the web's `<header>`.
class BrandHeader extends StatelessWidget implements PreferredSizeWidget {
  const BrandHeader({
    super.key,
    this.actions = const [],
    this.leading,
    this.title,
  });

  /// Optional override leading widget. When `null` we show the brand mark.
  final Widget? leading;

  /// Optional title shown after the brand mark (e.g. screen name).
  final Widget? title;

  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BrandColors.primary,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                leading ?? const BrandMark(height: 32),
                if (title != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.white24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: GoogleFonts.ebGaramond(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      child: title!,
                    ),
                  ),
                ] else
                  const Spacer(),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
