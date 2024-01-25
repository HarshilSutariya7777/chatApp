import 'dart:developer';
import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/helper/AppText.dart';
import 'package:chetapp2/helper/dialog.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/model/chet_user.dart';
import 'package:chetapp2/screen/profile_screen.dart';
import 'package:chetapp2/widgets/chet_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChetUser> list = [];
  final List<ChetUser> serchList = [];
  bool isSerching = false;

  @override
  void initState() {
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      log("Message: $message");
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }

      return Future.value(message);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () {
          if (isSerching) {
            setState(() {
              isSerching = !isSerching;
            });
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            // leading: GestureDetector(
            //     onTap: () {
            //       print("tapped");
            //       ThemeService().switchTheme();
            //     },
            //     child: Icon(Icons.nightlight_round)),
            title: isSerching
                ? TextField(
                    decoration: InputDecoration(
                        border: InputBorder.none, hintText: AppText().search),
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
                    onChanged: (val) {
                      serchList.clear();
                      for (var i in list) {
                        if (i.name.toLowerCase().contains(val.toLowerCase()) &&
                            i.email.toLowerCase().contains(val.toLowerCase())) {
                          serchList.add(i);
                        }
                        setState(() {
                          serchList;
                        });
                      }
                    },
                  )
                : Text(AppText().appname),
            actions: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      isSerching = !isSerching;
                    });
                  },
                  icon: Icon(isSerching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search)),
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProfileScreen(
                                  user: APIs.me,
                                )));
                  },
                  icon: const Icon(Icons.more_vert)),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUser();
              },
              child: const Icon(Icons.person_add),
            ),
          ),
          body: StreamBuilder(
            stream: APIs.getMyUserId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());

                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                        snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          log("data: $data");
                          list = data
                                  ?.map((e) => ChetUser.fromJson(e.data()))
                                  .toList() ??
                              [];
                          if (list.isNotEmpty) {
                            return ListView.builder(
                                itemCount:
                                    isSerching ? serchList.length : list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return ChetUserCard(
                                    user: isSerching
                                        ? serchList[index]
                                        : list[index],
                                  );
                                });
                          } else {
                            return Center(
                              child: Text(
                                AppText().internetConn,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  void _addChatUser() {
    String email = '';
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(children: [
                const Icon(Icons.person_add, color: Colors.blue, size: 28),
                Text(AppText().alertAdd)
              ]),
              content: TextFormField(
                maxLines: null,
                onChanged: (value) => email = value,
                decoration: InputDecoration(
                    hintText: AppText().alertEmail,
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(AppText().alertCancel,
                      style: const TextStyle(color: Colors.blue, fontSize: 16)),
                ),
                MaterialButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    if (email.isNotEmpty) {
                      await APIs.addChetUser(email).then((value) {
                        if (!value) {
                          Dialoges.showSnackbar(context, AppText().snack);
                        }
                      });
                    }
                  },
                  child: Text(AppText().alertAdd,
                      style: const TextStyle(color: Colors.blue, fontSize: 16)),
                )
              ],
            ));
  }
}
