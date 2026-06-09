import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdentityService {
  static const _deviceIdKey = 'eventos_app_device_id';

  Future<String> getOrCreateDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final storedId = preferences.getString(_deviceIdKey);
    if (storedId != null && storedId.trim().isNotEmpty) {
      return storedId;
    }

    final generatedId = _generateDeviceId();
    await preferences.setString(_deviceIdKey, generatedId);
    return generatedId;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final randomPart = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    return '$timestamp-$randomPart';
  }
}
