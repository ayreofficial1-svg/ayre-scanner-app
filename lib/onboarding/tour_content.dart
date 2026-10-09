import 'package:flutter/foundation.dart';

import '../widgets/ayre_bottom_nav.dart' show navDestinationKey;

/// Keys that mark the real widgets the spotlight tutorials point at. Each is
/// attached with a `KeyedSubtree` at the widget's own call site, so the
/// highlight always lands on the live element rather than a hand-measured box.
abstract final class TourKeys {
  static const homeTheme = ValueKey<String>('tour-home-theme');
  static const homeAlerts = ValueKey<String>('tour-home-alerts');

  static const settingsAppearance = ValueKey<String>(
    'tour-settings-appearance',
  );
  static const settingsNotifications = ValueKey<String>(
    'tour-settings-notifications',
  );
  static const settingsAccount = ValueKey<String>('tour-settings-account');
  static const settingsHelp = ValueKey<String>('tour-settings-help');
  static const settingsAbout = ValueKey<String>('tour-settings-about');
}

/// One step of the main app tutorial.
class AppTourStep {
  const AppTourStep({
    required this.tab,
    required this.target,
    required this.title,
    required this.body,
  });

  /// Index of the tab that must be showing for [target] to exist.
  final int tab;
  final Key target;
  final String title;
  final String body;
}

/// One step of the Settings tutorial.
class SettingsTourStep {
  const SettingsTourStep({
    required this.target,
    required this.title,
    required this.body,
    this.needsAccount = false,
  });

  final Key target;
  final String title;
  final String body;

  /// Account rows only exist while signed in, so the step is skipped otherwise.
  final bool needsAccount;
}

/// The main tutorial, in the order a person meets the app. Each line describes
/// what the screen actually contains (Home: the three index cards, the sentiment
/// card, the Weekly Report and desk notes; Signals: Entry/Exit/Stop cards;
/// Insights: the six movers and metric sections with their "i" buttons; Learn:
/// the subject filter and lessons; Profile: account, alerts, Settings, help).
///
/// Built lazily because the nav keys come from a function, not a constant.
List<AppTourStep> buildAppTourSteps() => [
  AppTourStep(
    tab: 0,
    target: navDestinationKey('Home'),
    title: 'Home',
    body:
        'NIFTY 50, SENSEX and BANK NIFTY, market sentiment, the Weekly '
        'Report and desk notes.',
  ),
  const AppTourStep(
    tab: 0,
    target: TourKeys.homeTheme,
    title: 'Theme switch',
    body: 'Switch between light and dark.',
  ),
  const AppTourStep(
    tab: 0,
    target: TourKeys.homeAlerts,
    title: 'Alerts',
    body:
        'New signals, updates and exits appear here. A red dot means '
        'something is unread.',
  ),
  AppTourStep(
    tab: 1,
    target: navDestinationKey('Signals'),
    title: 'Signals',
    body:
        'Picks worth watching, each with Entry, Exit and Stop levels. Tap one '
        'for details.',
  ),
  AppTourStep(
    tab: 2,
    target: navDestinationKey('Insights'),
    title: 'Insights',
    body:
        'Top gainers and losers, most active, volatility, momentum and volume '
        'surge. Tap the “i” on a section to see what it means.',
  ),
  AppTourStep(
    tab: 3,
    target: navDestinationKey('Learn'),
    title: 'Learn',
    body: 'Courses and lessons on the stock market. Filter them by subject.',
  ),
  AppTourStep(
    tab: 4,
    target: navDestinationKey('Profile'),
    title: 'Profile',
    body:
        'Your account, alerts, help and legal. Settings has its own '
        'tutorial.',
  ),
];

/// The Settings tutorial: one step per group, top to bottom.
const List<SettingsTourStep> kSettingsTourSteps = [
  SettingsTourStep(
    target: TourKeys.settingsAppearance,
    title: 'Appearance',
    body:
        'Settings are grouped by what you want to change. Start here for '
        'theme and text size.',
  ),
  SettingsTourStep(
    target: TourKeys.settingsNotifications,
    title: 'Notifications',
    body:
        'Choose where alerts reach you and which ones. You can also clear '
        'saved alerts.',
  ),
  SettingsTourStep(
    target: TourKeys.settingsAccount,
    title: 'Account',
    body: 'Change your password or delete your account.',
    needsAccount: true,
  ),
  SettingsTourStep(
    target: TourKeys.settingsHelp,
    title: 'Help and tutorials',
    body: 'Replay the app tutorial or this one any time.',
  ),
  SettingsTourStep(
    target: TourKeys.settingsAbout,
    title: 'About',
    body: 'The app version, to quote when you contact support, and credits.',
  ),
];
