import 'dart:developer';
import 'dart:io';
import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/helper/AppText.dart';
import 'package:chetapp2/helper/dialog.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/screen/Home_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAnimate = false;
  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isAnimate = true;
      });
    });
    super.initState();
  }

  handleGoogleSignIn() async {
    Dialoges.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      Navigator.pop(context);
      if (user != null) {
        log('\nUser: ${user.user}');
        log("\nUserCreditional:${user.additionalUserInfo}");
        if (await APIs.userExits()) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final Credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      return await APIs.auth.signInWithCredential(Credential);
    } catch (e) {
      log("\n signWithGoogle: $e");
      Dialoges.showSnackbar(context, AppText().internetConnErrorsnak);
      return null;
    }
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
        AnimatedPositioned(
          duration: const Duration(seconds: 1),
          top: mq.height * .15,
          right: isAnimate ? mq.width * .25 : -mq.width * .5,
          width: mq.width * .5,
          child: Image.asset("assets/images/comments.png"),
        ),
        Positioned(
          bottom: mq.height * .15,
          left: mq.width * .05,
          width: mq.width * .9,
          height: mq.height * .06,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 223, 255, 187),
                shape: const StadiumBorder(),
                elevation: 1),
            onPressed: () {
              handleGoogleSignIn();
            },
            icon: Image.asset(
              "assets/images/google.png",
              height: mq.height * .03,
            ),
            label: RichText(
              text: TextSpan(
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(text: AppText().login),
                    TextSpan(
                      text: AppText().Google,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    )
                  ]),
            ),
          ),
        )
      ]),
    );
  }
}
