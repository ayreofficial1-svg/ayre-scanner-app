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

  static const profileIdentity = ValueKey<String>('tour-profile-identity');
  static const profileVerify = ValueKey<String>('tour-profile-verify');
  static const profileAlerts = ValueKey<String>('tour-profile-alerts');
  static const profileSettings = ValueKey<String>('tour-profile-settings');
  static const profileSupport = ValueKey<String>('tour-profile-support');
  static const profileFaq = ValueKey<String>('tour-profile-faq');
  static const profileGrievance = ValueKey<String>('tour-profile-grievance');
  static const profileLegal = ValueKey<String>('tour-profile-legal');
  static const profileSignOut = ValueKey<String>('tour-profile-sign-out');
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

/// One step of the Profile tutorial.
class ProfileTourStep {
  const ProfileTourStep({
    required this.target,
    required this.title,
    required this.body,
    this.onlyWhenUnverified = false,
  });

  final Key target;
  final String title;
  final String body;

  /// The email-verification rows exist only while the address is unconfirmed,
  /// so this step is skipped otherwise.
  final bool onlyWhenUnverified;
}

/// The main tutorial, in the order a person meets the app. Each line describes
/// what the screen actually contains (Home: the three index cards, the sentiment
/// card, Recommendations with Entry/Exit/Stop levels and desk notes; Reports:
/// the Weekly Report; Insights: the six movers and metric sections with their
/// "i" buttons; Learn: the subject filter and lessons; Profile: account,
/// alerts, Settings, help).
///
/// Built lazily because the nav keys come from a function, not a constant.
List<AppTourStep> buildAppTourSteps() => [
  AppTourStep(
    tab: 0,
    target: navDestinationKey('Home'),
    title: 'Home',
    body:
        'Your market overview: NIFTY 50, BANK NIFTY and SENSEX, market '
        'sentiment, Recommendations with Entry, Exit and Stop levels, and '
        'desk notes.',
  ),
  const AppTourStep(
    tab: 0,
    target: TourKeys.homeTheme,
    title: 'Theme switch',
    body: 'Switch between light and dark any time, for example at night.',
  ),
  const AppTourStep(
    tab: 0,
    target: TourKeys.homeAlerts,
    title: 'Alerts',
    body:
        'Opens your alerts: new recommendations, updates and exit calls. A '
        'red dot means something is unread.',
  ),
  AppTourStep(
    tab: 1,
    target: navDestinationKey('Reports'),
    title: 'Reports',
    body:
        'The Weekly Report lists picks from past weeks and their reported '
        'results. Use the arrows to change week.',
  ),
  AppTourStep(
    tab: 2,
    target: navDestinationKey('Insights'),
    title: 'Insights',
    body:
        'Top gainers and losers, most active stocks and short market notes. '
        'Tap the “i” on a section to see what it means.',
  ),
  AppTourStep(
    tab: 3,
    target: navDestinationKey('Learn'),
    title: 'Learn',
    body:
        'Short courses and lessons on how the stock market works. Filter '
        'them by subject to find what you need.',
  ),
  AppTourStep(
    tab: 4,
    target: navDestinationKey('Profile'),
    title: 'Profile',
    body:
        'Your account, alerts, settings, help and legal pages. The Profile '
        'tutorial explains each option.',
  ),
];

/// The Settings tutorial: one step per group, top to bottom.
const List<SettingsTourStep> kSettingsTourSteps = [
  SettingsTourStep(
    target: TourKeys.settingsAppearance,
    title: 'Appearance',
    body:
        'Choose a light, dark or system theme and set the text size. '
        'Changes apply across the app straight away.',
  ),
  SettingsTourStep(
    target: TourKeys.settingsNotifications,
    title: 'Notifications',
    body:
        'Turn push and in-app alerts on or off, choose whether to get '
        'signal alerts, and clear the alerts saved on this device.',
  ),
  SettingsTourStep(
    target: TourKeys.settingsAccount,
    title: 'Account',
    body:
        'Get an email link to change your password, or delete your '
        'account. These options show only when you are signed in.',
    needsAccount: true,
  ),
];

/// The Profile tutorial: every option on the Profile tab, top to bottom.
const List<ProfileTourStep> kProfileTourSteps = [
  ProfileTourStep(
    target: TourKeys.profileIdentity,
    title: 'Your profile',
    body:
        'Shows your name, email and whether your email is verified. Tap it '
        'to change your display name.',
  ),
  ProfileTourStep(
    target: TourKeys.profileVerify,
    title: 'Verify your email',
    body:
        'Shown until your email is confirmed. Resend the link, open it, then '
        'tap “I’ve verified my email”. Nothing is blocked meanwhile.',
    onlyWhenUnverified: true,
  ),
  ProfileTourStep(
    target: TourKeys.profileAlerts,
    title: 'Alerts',
    body:
        'Your saved list of new recommendations, updates and exit calls. A '
        '“New” tag means something is unread.',
  ),
  ProfileTourStep(
    target: TourKeys.profileSettings,
    title: 'Settings',
    body:
        'Change the theme and text size, manage alert switches, and '
        'handle your password or account.',
  ),
  ProfileTourStep(
    target: TourKeys.profileSupport,
    title: 'Help and support',
    body:
        'Email the team, copy the app version to include in your message, '
        'and replay any tutorial.',
  ),
  ProfileTourStep(
    target: TourKeys.profileFaq,
    title: 'FAQ',
    body:
        'Answers to common questions. Check here first if something is '
        'unclear; it may save you writing in.',
  ),
  ProfileTourStep(
    target: TourKeys.profileGrievance,
    title: 'Grievance redressal',
    body:
        'Contact details for raising a complaint, with the analyst first and '
        'then SEBI’s complaint channels. Use it if a concern is not resolved.',
  ),
  ProfileTourStep(
    target: TourKeys.profileLegal,
    title: 'Legal and disclosures',
    body:
        'Terms, privacy policy, risk disclosure, registration details and '
        'the investor charter. Read them to understand the service and its '
        'risks.',
  ),
  ProfileTourStep(
    target: TourKeys.profileSignOut,
    title: 'Sign out',
    body:
        'Ends your session on this device. You will need your email and '
        'password to sign in again.',
  ),
];
