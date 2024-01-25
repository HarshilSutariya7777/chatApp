import 'package:chetapp2/main.dart';
import 'package:flutter/material.dart';

class FullScreen extends StatelessWidget {
  final String image;
  const FullScreen({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: mq.height * .5,
          width: mq.width,
          child: Image.network(
            image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
