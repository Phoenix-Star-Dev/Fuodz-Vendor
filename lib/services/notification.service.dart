import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart'
    hide NotificationModel;
import 'package:bg_launcher/bg_launcher.dart';
import 'package:flutter/services.dart';
import 'package:fuodz/constants/app_strings.dart';
import 'package:fuodz/models/notification.dart';
import 'package:fuodz/services/app.service.dart';
import 'package:fuodz/services/firebase.service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'in_app_order_notification.service.dart';
import 'local_storage.service.dart';

class NotificationService {
  //
  static const platform = MethodChannel('notifications.manage');

  //
  static initializeAwesomeNotification() async {
    await AwesomeNotifications().initialize(
      // set the icon to null if you want to use the default app icon
      'resource://drawable/notification_icon',
      [
        appNotificationChannel(),
        appNotificationChannel(
          mChannelKey: AppStrings.newOrderNotificationChannelKey,
          mSoundSource: AppStrings.newOrderNotificationSoundSource,
        ),
      ],
    );
    //requet notifcation permission if not allowed
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  static Future<void> clearIrrelevantNotificationChannels() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      // get channels
      final List<dynamic> notificationChannels = await platform.invokeMethod(
        'getChannels',
      );

      //confirm is more than the required channels is found
      final notificationChannelNames =
          notificationChannels
              .map((e) => e.toString().split(" -- ")[1])
              .toList();

      //
      final totalFound =
          notificationChannelNames
              .where(
                (e) =>
                    e.toLowerCase() ==
                    appNotificationChannel().channelName?.toLowerCase(),
              )
              .toList();

      if (totalFound.length > 1) {
        //delete all app created notifications
        for (final notificationChannel in notificationChannels) {
          //
          final notificationChannelData = "$notificationChannel".split(" -- ");
          final notificationChannelId = notificationChannelData[0];
          final notificationChannelName = notificationChannelData[1];
          final isSystemOwned =
              notificationChannelName.toLowerCase() == "miscellaneous";
          //
          if (!isSystemOwned) {
            //
            await platform.invokeMethod('deleteChannel', {
              "id": notificationChannelId,
            });
          }
        }

        //
        await initializeAwesomeNotification();
      }
    } on PlatformException catch (e) {
      print("Failed to get notificaiton channels: '${e.message}'.");
    }
  }

  static NotificationChannel appNotificationChannel({
    String mChannelKey = "basic_channel",
    String mSoundSource = "resource://raw/alert",
  }) {
    //firebase fall back channel key
    //fcm_fallback_notification_channel
    return NotificationChannel(
      channelKey: mChannelKey,
      channelName: '$mChannelKey notifications',
      channelDescription: 'Notification channel for app',
      importance: NotificationImportance.High,
      soundSource: mSoundSource,
      playSound: true,
    );
  }

  //
  static Future<List<NotificationModel>> getNotifications() async {
    //
    final notificationsStringList = (await LocalStorageService.getPrefs())
        .getString(AppStrings.notificationsKey);

    if (notificationsStringList == null) {
      return [];
    }

    return (jsonDecode(notificationsStringList) as List).asMap().entries.map((
      notificationObject,
    ) {
      //
      return NotificationModel(
        index: notificationObject.key,
        title: notificationObject.value["title"],
        body: notificationObject.value["body"],
        image: notificationObject.value["image"],
        read:
            notificationObject.value["read"] is bool
                ? notificationObject.value["read"]
                : false,
        timeStamp: notificationObject.value["timeStamp"],
      );
    }).toList();
  }

  static void addNotification(NotificationModel notification) async {
    //
    final notifications = await getNotifications();
    notifications.insert(0, notification);

    //
    await LocalStorageService.prefs!.setString(
      AppStrings.notificationsKey,
      jsonEncode(notifications),
    );
  }

  static void updateNotification(NotificationModel notificationModel) async {
    //
    final notifications = await getNotifications();
    notifications.removeAt(notificationModel.index!);
    notifications.insert(notificationModel.index!, notificationModel);
    await LocalStorageService.prefs!.setString(
      AppStrings.notificationsKey,
      jsonEncode(notifications),
    );
  }

  static listenToActions() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
      onNotificationCreatedMethod: onNotificationCreatedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedNotification,
  ) async {
    //try opening page associated with the notification data
    FirebaseService().saveNewNotification(
      null,
      title: receivedNotification.title,
      body: receivedNotification.body,
    );
    FirebaseService().notificationPayloadData = receivedNotification.payload;
    FirebaseService().selectNotification("");
  }

  @pragma('vm:entry-point')
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    //
    final notificationId = receivedNotification.id;
    final payload = receivedNotification.payload;
    // log("notificationId: $notificationId");
    // log("payload: $payload");
    //
    if (notificationId != AppService().neworderNotificationId ||
        payload == null) {
      return;
    }
    //new status
    final statues = ["pending", "new", "review"];
    bool isPending = statues.contains(payload["status"]);
    if (isPending) {
      //
      //
      try {
        if (Platform.isAndroid) {
          PermissionStatus status = await Permission.systemAlertWindow.status;
          if (status.isGranted) {
            //bring app to foreground
            BgLauncher.bringAppToForeground();
          }
        }
      } catch (error) {
        print("Error ==> $error");
      }

      //
      InAppOrderNotificationService().handleNewOrderAlert(payload);
    }
  }
}
