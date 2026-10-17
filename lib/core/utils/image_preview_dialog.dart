import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

void showFullScreenImage(
  BuildContext context, {
  required String imageUrl,
  String? title,
  String? heroTag,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _FullScreenImageViewer(
        imageUrl: imageUrl,
        title: title ?? 'معاينة الصورة',
        heroTag: heroTag,
      ),
    ),
  );
}

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.title,
    this.heroTag,
  });

  final String imageUrl;
  final String title;
  final String? heroTag;

  Future<void> _openExternal(BuildContext context) async {
    try {
      final launched = await launchUrlString(
        imageUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        await launchUrlString(imageUrl);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الرابط: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            tooltip: 'فتح الصورة في نافذة جديدة',
            onPressed: () => _openExternal(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'تحميل / فتح الرابط',
            onPressed: () => _openExternal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4.0,
          child: heroTag != null
              ? Hero(tag: heroTag!, child: _buildImage(context))
              : _buildImage(context),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (kIsWeb) {
      // On web, Image.network uses browser native image loading without CanvasKit CORS blocking
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          final loaded = progress.cumulativeBytesLoaded;
          final value = total != null && total > 0 ? loaded / total : null;
          return Center(
            child: CircularProgressIndicator(
              value: value,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorCard(context),
      );
    }

    // On mobile platforms, CachedNetworkImage with memory & disk cache
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => _buildErrorCard(context),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E242B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_rounded,
            color: Colors.amberAccent,
            size: 52,
          ),
          const SizedBox(height: 14),
          const Text(
            'تعذر عرض الصورة مباشرة داخل المتصفح',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'بسبب قيود أمان المتصفح (CORS)، يمكنك فتح الصورة مباشرة وعرضها بجودة كاملة بالضغط على الزر أدناه:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => _openExternal(context),
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
            label: const Text(
              'فتح الصورة في نافذة جديدة',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
