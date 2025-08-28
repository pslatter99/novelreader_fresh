import 'package:flutter/material.dart';

class Stars extends StatelessWidget {
  const Stars({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Icon(Icons.star, size: size, color: Colors.amber),
      ),
    );
  }
}
