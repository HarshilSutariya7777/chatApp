import 'dart:developer';

import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/helper/AppText.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/screen/Home_Screen.dart';
import 'package:chetapp2/screen/auth/Login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SpleshScreen extends StatefulWidget {
  const SpleshScreen({super.key});

  @override
  State<SpleshScreen> createState() => _SpleshScreenState();
}

class _SpleshScreenState extends State<SpleshScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          statusBarColor: Colors.white));
      if (APIs.auth.currentUser != null) {
        log('\nUser: ${APIs.auth.currentUser}');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppText().welcome),
      ),
      body: Stack(children: [
        Positioned(
            top: mq.height * .15,
            right: mq.width * .25,
            width: mq.width * .5,
            child: Image.asset("assets/images/comments.png")),
        Positioned(
          bottom: mq.height * .15,
          width: mq.width,
          child: Text(
            AppText().love,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87, letterSpacing: .5),
          ),
        )
      ]),
    );
  }
}
