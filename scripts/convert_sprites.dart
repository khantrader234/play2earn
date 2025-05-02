import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  final sourceDir = Directory('assets/sprites');
  final files = sourceDir.listSync().where((f) => f.path.endsWith('.svg'));

  for (final file in files) {
    final svgString = await File(file.path).readAsString();
    final svgPicture = SvgPicture.string(svgString);

    // Convert SVG to PNG
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    svgPicture.paint(canvas, Rect.fromLTWH(0, 0, 100, 100));
    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    // Save PNG file
    final pngPath = file.path.replaceAll('.svg', '.png');
    await File(pngPath).writeAsBytes(pngBytes);
    print('Converted ${file.path} to $pngPath');
  }
}
