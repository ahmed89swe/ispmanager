import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Interactive dialog for cropping, rotating, and compressing receipt photos.
class ReceiptEditorDialog extends StatefulWidget {
  const ReceiptEditorDialog({
    super.key,
    required this.imageBytes,
    this.title = 'تعديل وقص صورة الوصل',
  });

  final Uint8List imageBytes;
  final String title;

  static Future<Uint8List?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    String? title,
  }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceiptEditorDialog(
        imageBytes: imageBytes,
        title: title ?? 'تعديل وقص صورة الوصل',
      ),
    );
  }

  @override
  State<ReceiptEditorDialog> createState() => _ReceiptEditorDialogState();
}

class _ReceiptEditorDialogState extends State<ReceiptEditorDialog> {
  int _rotation = 0; // 0, 90, 180, 270
  int _quality = 75; // 50, 75, 90
  bool _processing = false;

  // Normalized crop rectangle: 0.0 to 1.0 relative to the rotated image
  Rect _cropRect = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96);

  // Active handle being dragged
  _CropHandle? _activeHandle;

  // Working image decoded once
  img.Image? _originalDecoded;
  int _originalSizeKb = 0;

  @override
  void initState() {
    super.initState();
    _originalSizeKb = (widget.imageBytes.lengthInBytes / 1024).round();
    _decodeOriginal();
  }

  Future<void> _decodeOriginal() async {
    setState(() => _processing = true);
    try {
      // Decode in background/async
      final decoded = await compute(_decodeImageCompute, widget.imageBytes);
      if (mounted) {
        setState(() {
          _originalDecoded = decoded;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  static img.Image? _decodeImageCompute(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    return img.bakeOrientation(image);
  }

  void _rotateClockwise() {
    setState(() {
      _rotation = (_rotation + 90) % 360;
      // Reset crop to default on rotation
      _cropRect = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96);
    });
  }

  void _rotateCounterClockwise() {
    setState(() {
      _rotation = (_rotation - 90 + 360) % 360;
      _cropRect = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96);
    });
  }

  void _setAspectRatio(double? ratio) {
    if (ratio == null) {
      // Free / Full
      setState(() => _cropRect = const Rect.fromLTWH(0.02, 0.02, 0.96, 0.96));
      return;
    }
    setState(() {
      // Fit a centered rect with given aspect ratio within [0.05, 0.95]
      double w = 0.9;
      double h = w / ratio;
      if (h > 0.9) {
        h = 0.9;
        w = h * ratio;
      }
      final l = (1.0 - w) / 2;
      final t = (1.0 - h) / 2;
      _cropRect = Rect.fromLTWH(l, t, w, h);
    });
  }

  Future<void> _applyAndSave() async {
    setState(() => _processing = true);
    try {
      final processed = await compute(
        _processImageCompute,
        _ProcessParams(
          rawBytes: widget.imageBytes,
          rotation: _rotation,
          cropRect: _cropRect,
          quality: _quality,
          maxDimension: 1600,
        ),
      );
      if (mounted) {
        Navigator.pop(context, processed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء معالجة الصورة: $e')),
        );
        setState(() => _processing = false);
      }
    }
  }

  static Uint8List _processImageCompute(_ProcessParams params) {
    img.Image? image = img.decodeImage(params.rawBytes);
    if (image == null) return params.rawBytes;

    image = img.bakeOrientation(image);

    if (params.rotation % 360 != 0) {
      image = img.copyRotate(image, angle: params.rotation % 360);
    }

    // Crop
    final crop = params.cropRect;
    final cx = (crop.left * image.width).round().clamp(0, image.width - 1);
    final cy = (crop.top * image.height).round().clamp(0, image.height - 1);
    final cw = (crop.width * image.width).round().clamp(1, image.width - cx);
    final ch = (crop.height * image.height).round().clamp(1, image.height - cy);

    image = img.copyCrop(image, x: cx, y: cy, width: cw, height: ch);

    // Downscale if too large to save bandwidth & storage
    if (image.width > params.maxDimension || image.height > params.maxDimension) {
      if (image.width >= image.height) {
        image = img.copyResize(image, width: params.maxDimension);
      } else {
        image = img.copyResize(image, height: params.maxDimension);
      }
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: params.quality));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E242B) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 850),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.crop_rotate_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _processing ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Editor Canvas
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: Colors.black.withValues(alpha: 0.95),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildCropCanvas(constraints);
                      },
                    ),
                  ),
                  if (_processing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'جاري معالجة وضغط الصورة...',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Controls Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181C22) : const Color(0xFFF7F9FC),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rotation & Aspect Ratio Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rotation Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'تدوير لليسار 90°',
                            icon: const Icon(Icons.rotate_left_rounded, size: 20),
                            onPressed: _processing ? null : _rotateCounterClockwise,
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            tooltip: 'تدوير لليمين 90°',
                            icon: const Icon(Icons.rotate_right_rounded, size: 20),
                            onPressed: _processing ? null : _rotateClockwise,
                          ),
                        ],
                      ),

                      // Presets
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _presetPill('كامل', null),
                            const SizedBox(width: 4),
                            _presetPill('طولي', 3 / 4),
                            const SizedBox(width: 4),
                            _presetPill('1:1', 1.0),
                            const SizedBox(width: 4),
                            _presetPill('4:3', 4 / 3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Compression Quality Selector & Info
                  Row(
                    children: [
                      const Icon(Icons.compress_rounded, size: 18, color: Colors.teal),
                      const SizedBox(width: 6),
                      Text(
                        'دقة وضغط الصورة:',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SegmentedButton<int>(
                          style: ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            textStyle: WidgetStatePropertyAll(
                              theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(value: 85, label: Text('عالية')),
                            ButtonSegment(value: 70, label: Text('متوسطة')),
                            ButtonSegment(value: 50, label: Text('مضغوطة')),
                          ],
                          selected: {_quality},
                          onSelectionChanged: (set) {
                            if (set.isNotEmpty) setState(() => _quality = set.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Size savings indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.teal),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الحجم الأصلي: $_originalSizeKb ك.ب • الجودة المختارة ستقلل الحجم لتسريع الرفع والتصفح بنسبة تصل إلى 80%',
                            style: const TextStyle(fontSize: 11, color: Colors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _processing ? null : () => Navigator.pop(context),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _processing ? null : _applyAndSave,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('حفظ واقتصاص الوصل'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetPill(String label, double? ratio) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5)),
      selected: false,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => _setAspectRatio(ratio),
    );
  }

  Widget _buildCropCanvas(BoxConstraints constraints) {
    final imageWidth = _originalDecoded != null
        ? (_rotation % 180 == 0 ? _originalDecoded!.width : _originalDecoded!.height).toDouble()
        : 1000.0;
    final imageHeight = _originalDecoded != null
        ? (_rotation % 180 == 0 ? _originalDecoded!.height : _originalDecoded!.width).toDouble()
        : 1000.0;

    // Calculate fitted display size maintaining aspect ratio
    final canvasAspect = constraints.maxWidth / constraints.maxHeight;
    final imageAspect = imageWidth / imageHeight;

    double dispW;
    double dispH;
    if (imageAspect > canvasAspect) {
      dispW = constraints.maxWidth * 0.92;
      dispH = dispW / imageAspect;
    } else {
      dispH = constraints.maxHeight * 0.92;
      dispW = dispH * imageAspect;
    }

    return Center(
      child: SizedBox(
        width: dispW,
        height: dispH,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The image rotated
            RotatedBox(
              quarterTurns: (_rotation ~/ 90),
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.contain,
              ),
            ),

            // Crop Overlay & Gesture Handler
            GestureDetector(
              onPanStart: (details) => _onPanStart(details.localPosition, dispW, dispH),
              onPanUpdate: (details) => _onPanUpdate(details.delta, dispW, dispH),
              onPanEnd: (_) => setState(() => _activeHandle = null),
              child: CustomPaint(
                painter: _CropOverlayPainter(
                  cropRect: _cropRect,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(Offset localPos, double dispW, double dispH) {
    final normX = (localPos.dx / dispW).clamp(0.0, 1.0);
    final normY = (localPos.dy / dispH).clamp(0.0, 1.0);

    // Hit-test handles with a generous radius (28 pixels)
    final handleRadiusX = 28.0 / dispW;
    final handleRadiusY = 28.0 / dispH;

    final r = _cropRect;

    if ((normX - r.left).abs() < handleRadiusX && (normY - r.top).abs() < handleRadiusY) {
      _activeHandle = _CropHandle.topLeft;
    } else if ((normX - r.right).abs() < handleRadiusX && (normY - r.top).abs() < handleRadiusY) {
      _activeHandle = _CropHandle.topRight;
    } else if ((normX - r.left).abs() < handleRadiusX && (normY - r.bottom).abs() < handleRadiusY) {
      _activeHandle = _CropHandle.bottomLeft;
    } else if ((normX - r.right).abs() < handleRadiusX && (normY - r.bottom).abs() < handleRadiusY) {
      _activeHandle = _CropHandle.bottomRight;
    } else if ((normX - r.left).abs() < handleRadiusX && normY >= r.top && normY <= r.bottom) {
      _activeHandle = _CropHandle.left;
    } else if ((normX - r.right).abs() < handleRadiusX && normY >= r.top && normY <= r.bottom) {
      _activeHandle = _CropHandle.right;
    } else if ((normY - r.top).abs() < handleRadiusY && normX >= r.left && normX <= r.right) {
      _activeHandle = _CropHandle.top;
    } else if ((normY - r.bottom).abs() < handleRadiusY && normX >= r.left && normX <= r.right) {
      _activeHandle = _CropHandle.bottom;
    } else if (r.contains(Offset(normX, normY))) {
      _activeHandle = _CropHandle.center;
    } else {
      _activeHandle = null;
    }
  }

  void _onPanUpdate(Offset delta, double dispW, double dispH) {
    if (_activeHandle == null) return;

    final dx = delta.dx / dispW;
    final dy = delta.dy / dispH;

    setState(() {
      var l = _cropRect.left;
      var t = _cropRect.top;
      var r = _cropRect.right;
      var b = _cropRect.bottom;

      const minSize = 0.1;

      switch (_activeHandle!) {
        case _CropHandle.center:
          final w = r - l;
          final h = b - t;
          l = (l + dx).clamp(0.0, 1.0 - w);
          t = (t + dy).clamp(0.0, 1.0 - h);
          r = l + w;
          b = t + h;
          break;
        case _CropHandle.topLeft:
          l = (l + dx).clamp(0.0, r - minSize);
          t = (t + dy).clamp(0.0, b - minSize);
          break;
        case _CropHandle.topRight:
          r = (r + dx).clamp(l + minSize, 1.0);
          t = (t + dy).clamp(0.0, b - minSize);
          break;
        case _CropHandle.bottomLeft:
          l = (l + dx).clamp(0.0, r - minSize);
          b = (b + dy).clamp(t + minSize, 1.0);
          break;
        case _CropHandle.bottomRight:
          r = (r + dx).clamp(l + minSize, 1.0);
          b = (b + dy).clamp(t + minSize, 1.0);
          break;
        case _CropHandle.left:
          l = (l + dx).clamp(0.0, r - minSize);
          break;
        case _CropHandle.right:
          r = (r + dx).clamp(l + minSize, 1.0);
          break;
        case _CropHandle.top:
          t = (t + dy).clamp(0.0, b - minSize);
          break;
        case _CropHandle.bottom:
          b = (b + dy).clamp(t + minSize, 1.0);
          break;
      }

      _cropRect = Rect.fromLTRB(l, t, r, b);
    });
  }
}

enum _CropHandle {
  center,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  left,
  right,
  top,
  bottom,
}

class _ProcessParams {
  final Uint8List rawBytes;
  final int rotation;
  final Rect cropRect;
  final int quality;
  final int maxDimension;

  _ProcessParams({
    required this.rawBytes,
    required this.rotation,
    required this.cropRect,
    required this.quality,
    required this.maxDimension,
  });
}

class _CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  _CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(
      cropRect.left * size.width,
      cropRect.top * size.height,
      cropRect.right * size.width,
      cropRect.bottom * size.height,
    );

    // Dimmed background outside crop
    final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.58);
    final fullRect = Offset.zero & size;
    final path = Path()
      ..addRect(fullRect)
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, dimPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(rect, borderPaint);

    // 3x3 Grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cellW = rect.width / 3;
    final cellH = rect.height / 3;
    canvas.drawLine(Offset(rect.left + cellW, rect.top), Offset(rect.left + cellW, rect.bottom), gridPaint);
    canvas.drawLine(Offset(rect.left + cellW * 2, rect.top), Offset(rect.left + cellW * 2, rect.bottom), gridPaint);
    canvas.drawLine(Offset(rect.left, rect.top + cellH), Offset(rect.right, rect.top + cellH), gridPaint);
    canvas.drawLine(Offset(rect.left, rect.top + cellH * 2), Offset(rect.right, rect.top + cellH * 2), gridPaint);

    // Corner Handles
    final handlePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill;

    const hSize = 8.0;
    // Corners
    canvas.drawCircle(rect.topLeft, hSize, handlePaint);
    canvas.drawCircle(rect.topRight, hSize, handlePaint);
    canvas.drawCircle(rect.bottomLeft, hSize, handlePaint);
    canvas.drawCircle(rect.bottomRight, hSize, handlePaint);

    // Edge centers
    final edgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(rect.center.dx, rect.top), 5, edgePaint);
    canvas.drawCircle(Offset(rect.center.dx, rect.bottom), 5, edgePaint);
    canvas.drawCircle(Offset(rect.left, rect.center.dy), 5, edgePaint);
    canvas.drawCircle(Offset(rect.right, rect.center.dy), 5, edgePaint);
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

