import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Image content kept inside the sample-data demo, never uploaded.
class DemoImage {
  const DemoImage.memory(
      {required this.name,
      required Uint8List data,
      required this.width,
      required this.height})
      : bytes = data,
        asset = null;
  const DemoImage.asset(
      {required this.name,
      required String path,
      required this.width,
      required this.height})
      : asset = path,
        bytes = null;

  final String name;
  final Uint8List? bytes;
  final String? asset;
  final int width;
  final int height;

  ImageProvider get provider =>
      bytes == null ? AssetImage(asset!) : MemoryImage(bytes!);

  Widget picture({BoxFit fit = BoxFit.contain}) => Image(
        image: provider,
        fit: fit,
        semanticLabel: name,
        errorBuilder: (_, __, ___) => const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Image unavailable'),
        ),
      );
}

class DemoImageViewer extends StatefulWidget {
  const DemoImageViewer({super.key, required this.image});
  final DemoImage image;

  @override
  State<DemoImageViewer> createState() => _DemoImageViewerState();
}

class _DemoImageViewerState extends State<DemoImageViewer> {
  final transform = TransformationController();

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    final scale =
        (transform.value.getMaxScaleOnAxis() * factor).clamp(1.0, 5.0);
    transform.value = Matrix4.diagonal3Values(scale, scale, 1);
  }

  Widget zoomButton(String label, String tooltip, VoidCallback onPressed) =>
      Tooltip(
        message: tooltip,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(label,
              style: TextStyle(fontSize: label == 'RESET' ? 14 : 26)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            tooltip: 'Close image',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        body: InteractiveViewer(
          transformationController: transform,
          minScale: 1,
          maxScale: 5,
          alignment: Alignment.center,
          child: SizedBox.expand(child: widget.image.picture()),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            zoomButton('−', 'Zoom out', () => zoom(1 / 1.5)),
            zoomButton('RESET', 'Reset zoom',
                () => transform.value = Matrix4.identity()),
            zoomButton('+', 'Zoom in', () => zoom(1.5)),
          ]),
        ),
      );
}
