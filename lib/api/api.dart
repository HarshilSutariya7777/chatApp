import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:chetapp2/model/Message.dart';
import 'package:chetapp2/model/chet_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:http/http.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;

  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static FirebaseStorage storage = FirebaseStorage.instance;

  static User get user => auth.currentUser!;

  static late ChetUser me;

//firebase puse notification
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  static Future<void> getFirebaseMessaginToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log("Push Token:$t");
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log("Got a Message In background");
      log("Message Data: ${message.data}");

      if (message.notification != null) {
        log("Message also contained a Notificatiions: ${message.notification}");
      }
    });
  }

  //api called push notification automatically
  // for sending push notification
  static Future<void> sendPushNotification(
      ChetUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name, //our name should be send
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {"some_data": "User ID: ${me.id}"}
      };

      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAA3s6AixM:APA91bG1ZJSiSVeKvd5oj7s38w68MzUq3y7RepSjHVHickO-c-y79bW2A8hRsafiYxURhG42YW4ZhYNhHVVbFSslvKoI8UialGMUujDPwrzmXeKN1mNSdx0fhbaL2NZoWOaiI2XPNJvO'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  //user exits or not?
  static Future<bool> userExits() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChetUser.fromJson(user.data()!);
        await getFirebaseMessaginToken();
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  //a new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chetUser = ChetUser(
        image: user.photoURL.toString(),
        about: "Hey, I'm using Apna chet",
        name: user.displayName.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        id: user.uid,
        pushToken: '',
        email: user.email.toString());
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chetUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log("userIds:$userIds");
    return firestore
        .collection('users')
        .where('id', whereIn: userIds.isEmpty ? [''] : userIds)
        .snapshots();
  }

  //

  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

//online status show app
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChetUser chetUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chetUser.id)
        .snapshots();
  }

  //update online last active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  static Future<void> updateProfilePicture(File file) async {
    final ext = file.path.split('.').last;
    log("Extension: $ext");
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log("Data Transfered: ${p0.bytesTransferred / 1000} kb");
    });
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  /* *******************chet releted apis */

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChetUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage(
      ChetUser chetuser, String msg, Type type) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Message message = Message(
        msg: msg,
        read: "",
        told: chetuser.id,
        type: type,
        fromid: user.uid,
        sent: time);
    final ref = firestore
        .collection('chats/${getConversationID(chetuser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chetuser, type == Type.text ? msg : 'image'));
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromid)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessages(
      ChetUser user) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  //image send and recevied in chet app screen.
  static Future<void> sendChetImage(ChetUser chetUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'images/${getConversationID(chetUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log("Data Transfered: ${p0.bytesTransferred / 1000} kb");
    });
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chetUser, imageUrl, Type.image);
  }

//video send
  static Future<void> sendChetVideo(ChetUser chetUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'videoMessage/${getConversationID(chetUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref
        .putFile(file, SettableMetadata(contentType: 'video/$ext'))
        .then((p0) {
      log("Data Transfered: ${p0.bytesTransferred / 1000} kb");
    });
    final videoUrl = await ref.getDownloadURL();
    await sendMessage(chetUser, videoUrl, Type.video);
  }

  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  static Future<void> updateMessage(
      Message message, String updateMessage) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages/')
        .doc(message.sent)
        .update({'msg': updateMessage});
  }

  //cheching if user exits or not?
  static Future<bool> addChetUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log("data:${data.docs}");

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      log("user Exits: ${data.docs.first.data()}");
      firestore
          .collection('users')
          .doc(user.uid)
          .collection("All_Users")
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      return false;
    }
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUserId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection("All_Users")
        .snapshots();
  }

  //chet with user
  static Future<void> sendFirstMessage(
      ChetUser chetuser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chetuser.id)
        .collection("All_Users")
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chetuser, msg, type));
  }

  //all user api...........................//

  //Dont take a screenshot in my app
  static dontTakeScreenShot() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

//clear all chat both sender and recevier.
  static Future<void> deletechat(ChetUser chetuser) async {
    final chetcollection = firestore.collection(
      'chats/${getConversationID(chetuser.id)}/messages/',
    );
    await chetcollection.get().then((snapshot) {
      for (DocumentSnapshot doc in snapshot.docs) {
        doc.reference.delete();
      }
      log("Collection deleted Successfully");
    }).catchError(
      (error) {
        debugPrint("Failed to delete collection");
      },
    );
  }

  // static Future<void> deleteuser() async {
  //   firestore
  //       .collection('users')
  //       .doc('88V1WWtSehYXX6W42HA3WrnQkGB3')
  //       .collection('All_Users')
  //       .doc('rSbRSes1EzNPX1kIkylyVO00fQo1')
  //       .delete()
  //       .then((value) {
  //     print("collection delete successfully");
  //   });
  // }

  // delete user in home screen
  static Future<bool> deleteChetUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    log("data:${data.docs}");

    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      log("user Exits: ${data.docs.first.data()}");
      firestore
          .collection('users')
          .doc(user.uid)
          .collection("All_Users")
          .doc(data.docs.first.id)
          .delete();

      return true;
    } else {
      return false;
    }
  }
}
