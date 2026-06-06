import 'package:flutter/widgets.dart';

import '../../app/app_controller.dart';
import 'settings_screen.dart';

Widget buildAccountSecuritySpaceStatusRoute(
  AppController controller,
  String? partnerName,
) {
  return SpaceStatusScreen(controller: controller, partnerName: partnerName);
}
