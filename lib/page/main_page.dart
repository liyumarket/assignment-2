// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'package:assignment2/component/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sendbird_chat_sdk/sendbird_chat_sdk.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Widgets.pageTitle('Main'),
        
      ),
      body: _mainBox(),
    );
  }

  Widget _mainBox() {
    final isNotificationEnabled =
        SendbirdChat.getAppInfo()?.notificationInfo?.isEnabled ?? false;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
           
            ElevatedButton(
              onPressed: () async {
                Get.toNamed('/open_channel/sendbird_open_channel_9925_8689167bb1420bf3df73bd2ede74d4de333cfa21');
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('OpenChannel'),
              ),
            ),
            const SizedBox(height: 16.0),
       ],
        ),
      ),
    );
  }
}
