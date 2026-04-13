import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NetworkCover extends StatelessWidget {
  const NetworkCover({
    super.key,
    required this.imageUrl,
    required this.fit,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget? errorWidget;

  bool get _isSvg => imageUrl.toLowerCase().split('?').first.endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    if (_isSvg) {
      return SvgPicture.network(
        imageUrl,
        fit: fit,
        placeholderBuilder: (_) => _loading(),
      );
    }

    return Image.network(
      imageUrl,
      fit: fit,
      filterQuality: FilterQuality.medium,
      webHtmlElementStrategy:
          kIsWeb ? WebHtmlElementStrategy.prefer : WebHtmlElementStrategy.never,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const SizedBox.shrink();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return _loading();
      },
    );
  }

  Widget _loading() {
    return Container(
      color: const Color(0xFF1A1F2E),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
