import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chetapp2/api/api.dart';
import 'package:chetapp2/helper/dialog.dart';
import 'package:chetapp2/helper/my_date.dart';
import 'package:chetapp2/main.dart';
import 'package:chetapp2/model/Message.dart';
import 'package:chetapp2/screen/Full_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  String replyText = '';
  String message = '';

  @override
  Widget build(BuildContext context) {
    bool isme = APIs.user.uid == widget.message.fromid;
    return InkWell(
        onLongPress: () {
          showBottomSheet(isme);
        },
        child: isme ? greenMessage() : blueMessage());
  }

//sender
  Widget blueMessage() {
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
      log("Message Read Updated");
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: InkWell(
            onTap: () {
              if (widget.message.type == Type.image) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FullScreen(image: widget.message.msg)));
              }
            },
            child: Container(
              padding: EdgeInsets.all(widget.message.type == Type.image
                  ? mq.width * .03
                  : mq.width * .04),
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color:
                      const Color.fromRGBO(234, 255, 123, 1).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30)),
              child: widget.message.type == Type.text
                  ? Text(
                      widget.message.msg,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    )
                  // : widget.message.type == Type.video
                  //: Home1(videourl: widget.message.msg)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: widget.message.msg,
                        placeholder: (context, url) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 70),
                      ),
                    ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDate.getFromattedTime(
                context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      ],
    );
  }

//recevier
  Widget greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(width: mq.width * .04),
            if (widget.message.read.isNotEmpty)
              const Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),
            const SizedBox(width: 2),
            Text(
              MyDate.getFromattedTime(
                  context: context, time: widget.message.sent),
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ),
        Flexible(
          child: InkWell(
            onTap: () {
              if (widget.message.type == Type.image) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FullScreen(image: widget.message.msg)));
              }
            },
            child: Container(
              padding: EdgeInsets.all(widget.message.type == Type.image
                  ? mq.width * .02
                  : mq.width * .03),
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(144, 238, 144, 1).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30)),
              child: widget.message.type == Type.text
                  ? Text(
                      widget.message.msg,
                      style:
                          const TextStyle(fontSize: 17, color: Colors.black87),
                    )
                  // // : widget.message.type == Type.video
                  // : Home1(videourl: widget.message.msg)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.message.msg,
                        placeholder: (context, url) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image, size: 70),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void showBottomSheet(bool isme) {
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
              widget.message.type == Type.text
                  ? OptionItem(
                      icon: const Icon(Icons.copy_all_rounded,
                          color: Colors.blue, size: 26),
                      name: "Copy Text",
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          Navigator.pop(context);
                          Dialoges.showSnackbar(context, "Text Copied!");
                        });
                      })
                  : OptionItem(
                      icon: const Icon(Icons.download,
                          color: Colors.blue, size: 26),
                      name: "Save Image",
                      onTap: () async {
                        try {
                          log("Image Url: ${widget.message.msg}");
                          GallerySaver.saveImage(widget.message.msg,
                                  albumName: "Apna Chet")
                              .then((success) {
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialoges.showSnackbar(
                                  context, "Image Successfully Saved!");
                            }
                          });
                        } catch (e) {
                          log("ErrorSavedImage:$e");
                        }
                      }),
              if (widget.message.type == Type.text && isme)
                OptionItem(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 26),
                    name: "Edit Message",
                    onTap: () {
                      Navigator.pop(context);
                      _showMessagingUpdateDialog();
                    }),
              if (isme)
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),
              if (isme)
                OptionItem(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 26),
                    name: "Delete Message",
                    onTap: () async {
                      log("Message deleted");
                      await APIs.deleteMessage(widget.message).then((value) {
                        Navigator.pop(context);
                      });
                    }),
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),
              OptionItem(
                  icon: const Icon(Icons.remove_red_eye,
                      color: Colors.blue, size: 26),
                  name:
                      "Sent At: ${MyDate.getMessageTime(context: context, time: widget.message.sent)}",
                  onTap: () {}),
              OptionItem(
                  icon: const Icon(Icons.remove_red_eye,
                      color: Colors.green, size: 26),
                  name: widget.message.read.isEmpty
                      ? 'Read At: Not Seen Yet'
                      : "Read At: ${MyDate.getMessageTime(context: context, time: widget.message.read)}",
                  onTap: () {}),
            ],
          );
        });
  }

  void _showMessagingUpdateDialog() {
    String updatemsg = widget.message.msg;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [
                Icon(Icons.message, color: Colors.blue, size: 28),
                Text("Update Message")
              ]),
              content: TextFormField(
                initialValue: updatemsg,
                maxLines: null,
                onChanged: (value) => updatemsg = value,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              actions: [
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel",
                      style: TextStyle(color: Colors.blue, fontSize: 16)),
                ),
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    APIs.updateMessage(widget.message, updatemsg);
                  },
                  child: const Text("Update",
                      style: TextStyle(color: Colors.blue, fontSize: 16)),
                )
              ],
            ));
  }
}

class OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const OptionItem(
      {super.key, required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .015,
            bottom: mq.height * .015),
        child: Row(children: [
          icon,
          Flexible(
            child: Text(
              '  $name',
              style: const TextStyle(
                  fontSize: 15, color: Colors.black54, letterSpacing: 0.5),
            ),
          ),
        ]),
      ),
    );
  }
}
