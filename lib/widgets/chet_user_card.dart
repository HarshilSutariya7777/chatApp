import 'package:cached_network_image/cached_network_image.dart';
import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/dialoges/profile_dialoge.dart';
import 'package:chetapp2/helper/dialog.dart';
import 'package:chetapp2/helper/my_date.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/model/Message.dart';
import 'package:chetapp2/model/chet_user.dart';
import 'package:chetapp2/screen/chet_Screen.dart';
import 'package:chetapp2/widgets/message_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChetUserCard extends StatefulWidget {
  final ChetUser user;
  const ChetUserCard({super.key, required this.user});

  @override
  State<ChetUserCard> createState() => _ChetUserCardState();
}

class _ChetUserCardState extends State<ChetUserCard> {
  Message? message;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        showbottomSheet();
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0.5,
        child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChetScreen(
                            user: widget.user,
                          )));
            },
            child: StreamBuilder(
                stream: APIs.getLastMessages(widget.user),
                builder: (context, snapshot) {
                  final data = snapshot.data?.docs;
                  final list =
                      data?.map((e) => Message.fromJson(e.data())).toList() ??
                          [];
                  if (list.isNotEmpty) {
                    message = list[0];
                  }

                  return ListTile(
                    leading: InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => ProfileDialoge(user: widget.user));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .3),
                        child: CachedNetworkImage(
                          height: mq.height * .06,
                          width: mq.height * .06,
                          fit: BoxFit.cover,
                          imageUrl: widget.user.image,
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(
                                  child: Icon(CupertinoIcons.person)),
                        ),
                      ),
                    ),
                    title: Text(widget.user.name),
                    subtitle: Text(
                        message != null
                            ? message!.type == Type.image
                                ? 'image'
                                : message!.msg
                            : widget.user.about,
                        maxLines: 1),
                    trailing: message == null
                        ? null
                        : message!.read.isEmpty &&
                                message!.fromid != APIs.user.uid
                            ? Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade400,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              )
                            : Text(
                                MyDate.getLastMessageTime(
                                    context: context, time: message!.sent),
                                style: const TextStyle(color: Colors.black54),
                              ),
                  );
                })),
      ),
    );
  }

  // showdialog() {
  //   showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //             title: const Text("Clear Chet"),
  //             content: const Text("You are sure you delete chat?"),
  //             actions: <Widget>[
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.all(8),
  //                   child: const Text("Cancel"),
  //                 ),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   APIs.deletechat(widget.user);
  //                   Navigator.pop(context);
  //                   Dialoges.showSnackbar(context, "Deleted chat Successfully");
  //                 },
  //                 child: Container(
  //                   padding: const EdgeInsets.all(8),
  //                   child: const Text("Yes"),
  //                 ),
  //               ),
  //             ],
  //           ));
  // }

  showbottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),
              OptionItem(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  name: "Delete User",
                  onTap: () async {
                    await APIs.deleteChetUser(widget.user.email).then((value) {
                      Navigator.pop(context);
                      Dialoges.showSnackbar(
                          context, "Delete User Successfully");
                    });
                  }),
              OptionItem(
                  icon: const Icon(Icons.cancel),
                  name: "Clear chat",
                  onTap: () async {
                    await APIs.deletechat(widget.user).then((value) {
                      Navigator.pop(context);
                      Dialoges.showSnackbar(
                          context, "Chat Delete successfully");
                    });
                  }),
            ],
          );
        });
  }
}
