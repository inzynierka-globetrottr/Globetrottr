import 'package:flutter/material.dart';
import 'package:globetrottr_front/core/widgets/neu_back_button.dart';

/// The layout of the secondary auth screens: a back button in the corner and
/// the content centred on the whole screen, scrolling when it does not fit.
class AuthCenteredLayout extends StatelessWidget {
  const AuthCenteredLayout({super.key, required this.children});

  final List<Widget> children;

  /// Keeps the content clear of the back button, equally at both ends so the
  /// centre stays in the middle of the screen.
  static const _verticalMargin = 64.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: top + _verticalMargin,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 22,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: top + 5, left: 20, child: const NeuBackButton()),
        ],
      ),
    );
  }
}
