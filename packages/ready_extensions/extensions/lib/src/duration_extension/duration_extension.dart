library duration_extension;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ready_extensions_dart/ready_extensions_dart.dart';

import '../messages/ready_extension_localizations.dart';

part 'translated_formatter.dart';

extension FlutterDurationExtensions on Duration {
  ///Localize duration using TranslatedDurationFormatter formatter
  ///You have to add `TranslatedDurationFormatter.delegate` in your `localizationsDelegates`
  /// ```
  /// return MaterialApp(
  ///   localizationsDelegates: [
  ///     TranslatedDurationFormatter.delegate,
  ///     ...other delegates
  ///   ],
  ///   home: MyApplicationHome(),
  /// );
  /// ```
  String formatWith(
    BuildContext context, {
    int maxParts = 2,
    int secondsToShowNow = 0,
  }) {
    var simpleLocalization = ReadyExtensionLocalizations.of(context);
    if (simpleLocalization == null) {
      throw FlutterError(
          'You have to add `SimpleLocalizations.delegate` in your `localizationsDelegates`');
    }
    return format(
      maxParts: maxParts,
      secondsToShowNow: 0,
      formatter: TranslatedDurationFormatter.of(context),
    );
  }

  /// convert the duration to  [TimeOfDay]
  /// if duration is greater than 24 hours it will throw an exception
  TimeOfDay toTimeOfDay() {
    var delta = inMinutes;
    var hours = (delta / 60).floor();
    var minutes = delta % 60;
    if (hours > 23) {
      throw FlutterError('Hours cannot be greater than 23');
    }
    return TimeOfDay(hour: hours, minute: minutes);
  }
}
