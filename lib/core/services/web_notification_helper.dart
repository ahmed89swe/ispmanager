import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper_web.dart';

class WebNotificationHelper {
  static Future<String> getPermission() => getWebNotificationPermissionImpl();

  static Future<String> requestPermission() =>
      requestWebNotificationPermissionImpl();

  static void showNotification({
    required String title,
    required String body,
  }) =>
      showWebBrowserNotificationImpl(title: title, body: body);
}

