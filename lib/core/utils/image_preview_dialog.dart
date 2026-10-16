import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

void showFullScreenImage(
  BuildContext context, {
  required String imageUrl,
  String? title,
  String? heroTag,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            title ?? 'معاينة الصورة',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: heroTag != null
                ? Hero(
                    tag: heroTag,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

