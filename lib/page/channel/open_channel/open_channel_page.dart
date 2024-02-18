// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:assignment2/component/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

const String url =
    "sendbird_open_channel_9925_8689167bb1420bf3df73bd2ede74d4de333cfa21";

class OpenChannelPage extends StatefulWidget {
  const OpenChannelPage({Key? key}) : super(key: key);

  @override
  State<OpenChannelPage> createState() => OpenChannelPageState();
}

class OpenChannelPageState extends State<OpenChannelPage> {
  final channelUrl = Get.parameters['channel_url']!;
  final itemScrollController = ItemScrollController();
  final textEditingController = TextEditingController();
  late PreviousMessageListQuery query;

  String title = '';
  bool hasPrevious = false;
  List<BaseMessage> messageList = [];
  int? participantCount;

  OpenChannel? openChannel;

  @override
  void initState() {
    super.initState();

    SendbirdChat.addChannelHandler('OpenChannel', MyOpenChannelHandler(this));
    SendbirdChat.addConnectionHandler('OpenChannel', MyConnectionHandler(this));

    OpenChannel.getChannel(channelUrl).then((openChannel) {
      this.openChannel = openChannel;
      openChannel.enter().then((_) => _initialize());
    });
  }

  void _initialize() {
    OpenChannel.getChannel(channelUrl).then((openChannel) {
      query = PreviousMessageListQuery(
        channelType: ChannelType.open,
        channelUrl: channelUrl,
      )..next().then((messages) {
          setState(() {
            messageList
              ..clear()
              ..addAll(messages);
            title = '${openChannel.name} (${messageList.length})';
            hasPrevious = query.hasNext;
            participantCount = openChannel.participantCount;
          });
        });
    });
  }

  @override
  void dispose() {
    SendbirdChat.removeChannelHandler('OpenChannel');
    SendbirdChat.removeConnectionHandler('OpenChannel');
    textEditingController.dispose();

    OpenChannel.getChannel(channelUrl).then((channel) => channel.exit());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: Widgets.pageTitle(title, maxLines: 2),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.menu))],
      ),
      body: Column(
        children: [
      
          Expanded(child: messageList.isNotEmpty ? _list() : Container()),
          _messageSender(),
        ],
      ),
    );
  }


  Widget _list() {
    return ScrollablePositionedList.builder(
      physics: const ClampingScrollPhysics(),
      initialScrollIndex: messageList.length - 1,
      itemScrollController: itemScrollController,
      itemCount: messageList.length,
      itemBuilder: (BuildContext context, int index) {
        if (index >= messageList.length) return Container();

        BaseMessage message = messageList[index];

        return GestureDetector(
          onDoubleTap: () async {
            final openChannel = await OpenChannel.getChannel(channelUrl);
            Get.toNamed(
                    '/message/update/${openChannel.channelType.toString()}/${openChannel.channelUrl}/${message.messageId}')
                ?.then((message) async {
              if (message != null) {
                for (int index = 0; index < messageList.length; index++) {
                  if (messageList[index].messageId == message.messageId) {
                    setState(() => messageList[index] = message);
                    break;
                  }
                }
              }
            });
          },
          onLongPress: () async {
            final openChannel = await OpenChannel.getChannel(channelUrl);
            await openChannel.deleteMessage(message.messageId);
            setState(() {
              messageList.remove(message);
              title = '${openChannel.name} (${messageList.length})';
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: IosMessengerRecipientBubbles(
                    message: message,
                  ))
            ],
          ),
        );
      },
    );
  }

  Widget _messageSender() {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          IconButton(onPressed: (() {}), icon: const Icon(Icons.add_circle)),
          Expanded(
            child: Widgets.textField(
              textEditingController,
              'Message',
              prefixIcon: IconButton(
                onPressed: () async {
                  if (textEditingController.value.text.isEmpty) {
                    return;
                  }

                  openChannel?.sendUserMessage(
                    UserMessageCreateParams(
                      message: textEditingController.value.text,
                    ),
                    handler: (UserMessage message, SendbirdException? e) async {
                      if (e != null) {
                        await _showDialogToResendUserMessage(message);
                      } else {
                        _addMessage(message);
                      }
                    },
                  );

                  textEditingController.clear();
                },
                icon:const CircleAvatar(backgroundColor: Colors.pink, child:  Icon(Icons.arrow_upward_rounded)),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
    );
  }

  Future<void> _showDialogToResendUserMessage(UserMessage message) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            content: Text('Resend: ${message.message}'),
            actions: [
              TextButton(
                onPressed: () {
                  openChannel?.resendUserMessage(
                    message,
                    handler: (message, e) async {
                      if (e != null) {
                        await _showDialogToResendUserMessage(message);
                      } else {
                        _addMessage(message);
                      }
                    },
                  );

                  Get.back();
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('No'),
              ),
            ],
          );
        });
  }

  void _addMessage(BaseMessage message) {
    OpenChannel.getChannel(channelUrl).then((openChannel) {
      setState(() {
        messageList.add(message);
        title = '${openChannel.name} (${messageList.length})';
        participantCount = openChannel.participantCount;
      });

      Future.delayed(
        const Duration(milliseconds: 100),
        () => _scroll(messageList.length - 1),
      );
    });
  }

  void _updateMessage(BaseMessage message) {
    OpenChannel.getChannel(channelUrl).then((openChannel) {
      setState(() {
        for (int index = 0; index < messageList.length; index++) {
          if (messageList[index].messageId == message.messageId) {
            messageList[index] = message;
            break;
          }
        }

        title = '${openChannel.name} (${messageList.length})';
        participantCount = openChannel.participantCount;
      });
    });
  }

  void _deleteMessage(int messageId) {
    OpenChannel.getChannel(channelUrl).then((openChannel) {
      setState(() {
        for (int index = 0; index < messageList.length; index++) {
          if (messageList[index].messageId == messageId) {
            messageList.removeAt(index);
            break;
          }
        }

        title = '${openChannel.name} (${messageList.length})';
        participantCount = openChannel.participantCount;
      });
    });
  }

  void _updateParticipantCount() {
    OpenChannel.getChannel(channelUrl).then((openChannel) {
      setState(() {
        participantCount = openChannel.participantCount;
      });
    });
  }

  void _scroll(int index) async {
    if (messageList.length <= 1) return;

    while (!itemScrollController.isAttached) {
      await Future.delayed(const Duration(milliseconds: 1));
    }

    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
    );
  }
}

class IosMessengerRecipientBubbles extends StatelessWidget {
  final BaseMessage message;

  const IosMessengerRecipientBubbles({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment:   message.sender!.isCurrentUser
                  ? CrossAxisAlignment.end: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            message.sender!.isCurrentUser
                  ? const SizedBox()
                  :    CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(message.sender?.profileUrl ?? ''),
              ),
            message.sender!.isCurrentUser
                  ? const SizedBox()
                  :   const SizedBox(
                width: 10,
              ),
              message.sender!.isCurrentUser
                  ? Container(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 12,
                        right: 10,
                        bottom: 10,
                      ),
                      decoration: const ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.75, -0.67),
                          end: Alignment(-0.75, 0.67),
                          colors: [Color(0xFFFF006B), Color(0xFFFF4593)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
                      child: Text(
                        message.message,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          height: 0.07,
                          letterSpacing: -0.60,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 12),
                      decoration: const ShapeDecoration(
                        color: Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(18),
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              message.sender!.userId.length > 20
                                  ? message.sender!.nickname
                                  : message.sender?.userId ?? '',
                              style: const TextStyle(
                                color: Color(0xFFADADAD),
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 0.09,
                                letterSpacing: -0.60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Flexible(
                            child: Text(
                              message.message ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 0.07,
                                letterSpacing: -0.60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              message.sender!.isCurrentUser
                  ? const SizedBox()
                  : const SizedBox(width: 8),
              message.sender!.isCurrentUser
                  ? const SizedBox()
                  : Text(
                      DateTime.fromMillisecondsSinceEpoch(message.createdAt)
                          .toString()
                          .substring(0, 10),
                      style: const TextStyle(
                        color: Color(0xFF9C9CA3),
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        height: 0.11,
                        letterSpacing: -0.60,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class MyOpenChannelHandler extends OpenChannelHandler {
  final OpenChannelPageState _state;

  MyOpenChannelHandler(this._state);

  @override
  void onMessageReceived(BaseChannel channel, BaseMessage message) {
    _state._addMessage(message);
  }

  @override
  void onMessageUpdated(BaseChannel channel, BaseMessage message) {
    _state._updateMessage(message);
  }

  @override
  void onMessageDeleted(BaseChannel channel, int messageId) {
    _state._deleteMessage(messageId);
  }

  @override
  void onUserEntered(OpenChannel channel, User user) {
    _state._updateParticipantCount();
  }

  @override
  void onUserExited(OpenChannel channel, User user) {
    _state._updateParticipantCount();
  }
}

class MyConnectionHandler extends ConnectionHandler {
  final OpenChannelPageState _state;

  MyConnectionHandler(this._state);

  @override
  void onConnected(String userId) {}

  @override
  void onDisconnected(String userId) {}

  @override
  void onReconnectStarted() {}

  @override
  void onReconnectSucceeded() {
    _state._initialize();
  }

  @override
  void onReconnectFailed() {}
}
