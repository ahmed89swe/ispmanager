// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;

Future<String> getWebNotificationPermissionImpl() async {
  try {
    if (!html.Notification.supported) return 'unsupported';
    return html.Notification.permission ?? 'default';
  } catch (_) {
    return 'unsupported';
  }
}

Future<String> requestWebNotificationPermissionImpl() async {
  try {
    if (!html.Notification.supported) return 'unsupported';
    final status = await html.Notification.requestPermission();
    return status;
  } catch (_) {
    return 'unsupported';
  }
}

void showWebBrowserNotificationImpl({
  required String title,
  required String body,
}) {
  _playNotificationChime();
  try {
    if (html.Notification.supported &&
        html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
      );
    }
  } catch (_) {}
}

void _playNotificationChime() {
  try {
    js.context.callMethod('eval', [
      '''
      (function() {
        try {
          var AudioCtx = window.AudioContext || window.webkitAudioContext;
          if (!AudioCtx) return;
          var ctx = new AudioCtx();
          var osc = ctx.createOscillator();
          var gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(880, ctx.currentTime);
          osc.frequency.exponentialRampToValueAtTime(1174.66, ctx.currentTime + 0.14);
          gain.gain.setValueAtTime(0.12, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 0.36);
        } catch (e) {}
      })();
      '''
    ]);
  } catch (_) {}
}

