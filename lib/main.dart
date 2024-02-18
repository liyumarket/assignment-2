// Copyright (c) 2023 Sendbird, Inc. All rights reserved.

import 'dart:async';

import 'package:assignment2/notifications/local_notifications_manager.dart';
import 'package:assignment2/notifications/push_manager.dart';
import 'package:assignment2/page/channel/open_channel/open_channel_page.dart';
import 'package:assignment2/page/channel/open_channel/open_channel_update_page.dart';
import 'package:assignment2/page/login_page.dart';
import 'package:assignment2/page/main_page.dart';
import 'package:assignment2/utils/app_prefs.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';


const sampleVersion = '4.2.0';
const yourAppId = '728E8736-5D0C-47CE-B934-E39B656900F3';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (errorDetails) {
        debugPrint('[FlutterError] ${errorDetails.stack}');
        Fluttertoast.showToast(
          msg: '[FlutterError] ${errorDetails.stack}',
          gravity: ToastGravity.CENTER,
          toastLength: Toast.LENGTH_SHORT,
        );
      };

      await PushManager.initialize();
      await LocalNotificationsManager.initialize();
      await AppPrefs().initialize();

      runApp(const MyApp());
    },
    (error, stackTrace) async {
      debugPrint('[Error] $error\n$stackTrace');
      Fluttertoast.showToast(
        msg: '[Error] $error',
        gravity: ToastGravity.CENTER,
        toastLength: Toast.LENGTH_SHORT,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sendbird Chat',
      
      builder: (context, child) {
        return ScrollConfiguration(behavior: _AppBehavior(), child: child!);
      },
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const LoginPage(),
        ),
        GetPage(
          name: '/main',
          page: () => const MainPage(),
        ),
  
      
        GetPage(
          name: '/open_channel/update/:channel_url',
          page: () => const OpenChannelUpdatePage(),
        ),
        GetPage(
          name: '/open_channel/:channel_url',
          page: () => const OpenChannelPage(),
        ),
        
      ],
    );
  }

  }

class _AppBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
