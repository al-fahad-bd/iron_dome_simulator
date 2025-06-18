import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class Missile {
  Offset position;
  Offset velocity;
  bool isInterceptor;
  ui.Image? image;

  Missile({
    required this.position,
    required this.velocity,
    this.isInterceptor = false,
    this.image,
  });
}

class Explosion {
  Offset position;
  double radius;
  double maxRadius;
  double opacity;
  int lifetime;

  Explosion({
    required this.position,
    this.radius = 0,
    this.maxRadius = 30,
    this.opacity = 1.0,
    this.lifetime = 10, // 10 frames (0.5s)
  });
}
