import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class BoardImage {
  final Uint8List bytes;
  Offset position;
  double width;
  double height;
  bool isSelected;

  BoardImage({
    required this.bytes,
    required this.position,
    required this.width,
    required this.height,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() => {
        'b64': base64Encode(bytes),
        'x': position.dx,
        'y': position.dy,
        'w': width,
        'h': height,
      };

  factory BoardImage.fromMap(Map<String, dynamic> map) => BoardImage(
        bytes: base64Decode(map['b64'] as String),
        position: Offset((map['x'] as num).toDouble(), (map['y'] as num).toDouble()),
        width: (map['w'] as num).toDouble(),
        height: (map['h'] as num).toDouble(),
        isSelected: false,
      );
}