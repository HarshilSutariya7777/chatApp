import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/helper/my_date.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/model/Message.dart';
import 'package:chetapp2/model/chet_user.dart';
import 'package:chetapp2/screen/view_profile_screen.dart';
import 'package:chetapp2/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChetScreen extends StatefulWidget {
  final ChetUser user;
  const ChetScreen({super.key, required this.user});

  @override
  State<ChetScreen> createState() => _ChetScreenState();
}

class _ChetScreenState extends State<ChetScreen> {
  List<Message> list = [];
  final textcontroller = TextEditingController();
  bool showemoji = false, isuploading = false;
  FocusNode inputNode = FocusNode();
  void openKeyboard() {
    FocusScope.of(context).requestFocus(inputNode);
  }

  @override
  void initState() {
    APIs.dontTakeScreenShot();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (showemoji) {
              setState(() {
                showemoji = !showemoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            // backgroundColor: const Color.fromARGB(255, 234, 248, 255),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: appBar(),
            ),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          list = data
                                  ?.map((e) => Message.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (list.isNotEmpty) {
                            return ListView.builder(
                                reverse: true,
                                itemCount: list.length,
                                padding: EdgeInsets.only(top: mq.height * .01),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(message: list[index]);
                                });
                          } else {
                            return const Center(
                              child: Text(
                                "Say, Hiii✋",
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),
                if (isuploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )),
                chetInput(),
                if (showemoji)
                  SizedBox(
                    height: mq.height * .35,
                    child: EmojiPicker(
                      textEditingController: textcontroller,
                      config: Config(
                        columns: 8,
                        bgColor: const Color.fromARGB(255, 234, 248, 255),
                        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget appBar() {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(user: widget.user)));
        },
        child: StreamBuilder(
            stream: APIs.getUserInfo(widget.user),
            builder: (context, snapShot) {
              final data = snapShot.data?.docs;
              final list =
                  data?.map((e) => ChetUser.fromJson(e.data())).toList() ?? [];
              return Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.black54)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .3),
                    child: CachedNetworkImage(
                      height: mq.height * .05,
                      width: mq.height * .05,
                      fit: BoxFit.cover,
                      imageUrl:
                          list.isNotEmpty ? list[0].image : widget.user.image,
                      errorWidget: (context, url, error) => const CircleAvatar(
                          child: Icon(CupertinoIcons.person)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Online'
                                : MyDate.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDate.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }));
  }

  Widget chetInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: mq.width * .025, vertical: mq.height * .01),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          FocusScope.of(context).unfocus();
                          showemoji = !showemoji;
                        });
                      },
                      icon: const Icon(Icons.emoji_emotions,
                          color: Color.fromRGBO(33, 150, 243, 1))),
                  Expanded(
                    child: TextField(
                      focusNode: inputNode,
                      onTap: () {
                        if (showemoji) {
                          setState(() {
                            showemoji = !showemoji;
                          });
                        }
                      },
                      controller: textcontroller,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: const InputDecoration(
                          hintText: "Type Somthings....",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Colors.blue,
                          )),
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);
                        for (var i in images) {
                          log("Image Path: ${i.path}");
                          setState(() {
                            isuploading = true;
                          });
                          await APIs.sendChetImage(widget.user, File(i.path));
                          setState(() {
                            isuploading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.image, color: Colors.blue)),
                  //video picker code
                  // IconButton(
                  //     onPressed: () async {
                  //       final ImagePicker picker = ImagePicker();
                  //       final XFile? video = await picker.pickVideo(
                  //         source: ImageSource.gallery,
                  //       );
                  //       print("video has ben selected:$video");
                  //       if (video != null) {
                  //         log("video path: ${video.path}");
                  //         setState(() {
                  //           isuploading = true;
                  //         });
                  //         await APIs.sendChetVideo(
                  //             widget.user, File(video.path));
                  //         setState(() {
                  //           isuploading = false;
                  //         });
                  //       }
                  //     },
                  //     icon: const Icon(Icons.video_camera_back_sharp,
                  //         color: Colors.blue)),
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          log("Image Path: ${image.path}");
                          setState(() {
                            isuploading = true;
                          });

                          await APIs.sendChetImage(
                              widget.user, File(image.path));
                          setState(() {
                            isuploading = false;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded,
                          color: Colors.blue)),
                  SizedBox(width: mq.width * .02)
                ],
              ),
            ),
          ),
          MaterialButton(
            minWidth: 0,
            color: Colors.green,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 5, left: 10),
            shape: const CircleBorder(),
            onPressed: () {
              if (textcontroller.text.isNotEmpty) {
                if (list.isEmpty) {
                  APIs.sendFirstMessage(
                      widget.user, textcontroller.text, Type.text);
                } else {
                  APIs.sendMessage(widget.user, textcontroller.text, Type.text);
                }

                textcontroller.text = "";
              }
            },
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
