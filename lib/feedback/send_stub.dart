// send_stub.dart — the phone app sends nothing over the internet: no form here, no check (see feedback_screen.dart).
import 'package:flutter/widgets.dart';

const canSendOnline = false;

/// A short description of this device for the message
String deviceInfo(Size screen) => 'Android app, ${screen.width.round()}×${screen.height.round()}';

Future<bool> sendFeedback(Map<String, String> fields) async => false;

Map<String, String>? takeFeedbackLink() => null;

void setPageLang(String lang) {}

class CaptchaBox extends StatelessWidget {
  final ValueChanged<String?> onToken;
  final VoidCallback onFailed;
  const CaptchaBox({super.key, required this.onToken, required this.onFailed});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
