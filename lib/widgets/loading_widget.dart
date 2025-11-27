import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? spinnerColor;
  final bool fullScreen;

  const LoadingWidget({
    super.key,
    this.message = 'Loading...',
    this.backgroundColor,
    this.spinnerColor,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final loadingContent = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                spinnerColor ?? Theme.of(context).primaryColor,
              ),
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: backgroundColor ?? Colors.white,
        body: loadingContent,
      );
    }

    return Container(
      color: backgroundColor ?? Colors.transparent,
      child: loadingContent,
    );
  }
}

// Full screen loading overlay
class FullScreenLoader extends StatelessWidget {
  final String message;

  const FullScreenLoader({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(color: Colors.black.withOpacity(0.5), dismissible: false),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
