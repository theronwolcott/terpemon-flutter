import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class TransparentWhiteImageProvider
    extends ImageProvider<TransparentWhiteImageProvider> {
  final String path;

  TransparentWhiteImageProvider(this.path);

  @override
  ImageStreamCompleter loadImage(
      TransparentWhiteImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: key.path,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription('Path: ${key.path}'),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
      TransparentWhiteImageProvider key, ImageDecoderCallback decode) async {
    final File file = File(key.path);
    final Uint8List bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    final Uint8List transformedBytes =
        await _transformWhiteToTransparent(image);

    // Convert Uint8List to ImmutableBuffer before decoding
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(transformedBytes);
    return decode(buffer);
  }

  Future<Uint8List> _transformWhiteToTransparent(img.Image? image) async {
    final pixels = image!.getBytes(order: img.ChannelOrder.rgba);
    final height = image.height;
    final width = image.width;
    //final int length = pixels.length;
    _pixelHelper(pixels, height, width);
    // for (int i = 0; i < length; i += 4) {
    //   // Access each byte: R, G, B, and A
    //   final int r = pixels[i];
    //   final int g = pixels[i + 1];
    //   final int b = pixels[i + 2];
    //   // Check if the color is white
    //   if (r >= 254 && g >= 254 && b >= 254) {
    //     // Set alpha to 0 to make it transparent
    //     pixels[i + 3] = 0;
    //   }
    // }
    return img.encodePng(img.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixels.buffer,
        order: img.ChannelOrder.rgba));
  }

  void _pixelHelper(Uint8List pixels, int height, int width) {
    //create stack
    _Stack<_Pixel> stack = _Stack<_Pixel>();
    stack.push(_Pixel(0, 0));

    while (!stack.isEmpty()) {
      var pixel = stack.pop();
      //print("pixel: ${pixel.row}, ${pixel.col} (${stack.count()})");
      if (pixel.row < 0 ||
          pixel.col < 0 ||
          pixel.row >= height ||
          pixel.col >= width) {
        continue;
      }
      int i = 4 * ((pixel.row * width) + pixel.col);
      if (pixels[i + 3] != 0 &&
          pixels[i] == 255 &&
          pixels[i + 1] == 255 &&
          pixels[i + 2] == 255) {
        //print("pixels[i + 3] == 0;");
        pixels[i + 3] = 0;
        stack.push(_Pixel(pixel.row + 1, pixel.col));
        stack.push(_Pixel(pixel.row - 1, pixel.col));
        stack.push(_Pixel(pixel.row, pixel.col + 1));
        stack.push(_Pixel(pixel.row, pixel.col - 1));
      }
    }
  }

  @override
  Future<TransparentWhiteImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<TransparentWhiteImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TransparentWhiteImageProvider && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, 'TransparentWhiteImageProvider')}("$path")';
}

class _Pixel {
  int row;
  int col;
  _Pixel(this.row, this.col);
}

class _Stack<E> {
  _Stack() : _storage = <E>[];
  final List<E> _storage;

  void push(E element) => _storage.add(element);

  E pop() => _storage.removeLast();

  bool isEmpty() => _storage.isEmpty;

  int count() => _storage.length;
}
