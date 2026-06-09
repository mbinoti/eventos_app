import 'package:flutter/foundation.dart';

bool get isCupertinoPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
