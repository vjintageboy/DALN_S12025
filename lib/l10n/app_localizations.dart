import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Moodiki'**
  String get appTitle;

  /// Main tagline on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Track your emotions, elevate your mindset'**
  String get appTagline;

  /// Sub tagline on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Your journey to mental wellness starts here'**
  String get appSubTagline;

  /// Journey subtitle in splash screen
  ///
  /// In en, this message translates to:
  /// **'Emotional care journey'**
  String get emotionalJourney;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @meditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get meditation;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @experts.
  ///
  /// In en, this message translates to:
  /// **'experts'**
  String get experts;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@company.com'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join us and start your journey today'**
  String get signUpSubtitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please sign in to continue'**
  String get signInSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @quote1.
  ///
  /// In en, this message translates to:
  /// **'\"In the middle of a cold winter, I finally realized that within me lay an invincible summer.\"'**
  String get quote1;

  /// No description provided for @quote1Author.
  ///
  /// In en, this message translates to:
  /// **'ALBERT CAMUS'**
  String get quote1Author;

  /// No description provided for @quote2.
  ///
  /// In en, this message translates to:
  /// **'\"Feelings are just visitors. Let them come and go.\"'**
  String get quote2;

  /// No description provided for @quote2Author.
  ///
  /// In en, this message translates to:
  /// **'MOOJI'**
  String get quote2Author;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest Streak'**
  String get longestStreak;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get editProfileSubtitle;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statisticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your mood analytics'**
  String get statisticsSubtitle;

  /// No description provided for @myAppointments.
  ///
  /// In en, this message translates to:
  /// **'My Appointments'**
  String get myAppointments;

  /// No description provided for @myAppointmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage your bookings'**
  String get myAppointmentsSubtitle;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @privacySecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control your privacy settings'**
  String get privacySecuritySubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact us'**
  String get helpSupportSubtitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeeling;

  /// No description provided for @selectYourMood.
  ///
  /// In en, this message translates to:
  /// **'Select your mood'**
  String get selectYourMood;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get addNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get noteHint;

  /// No description provided for @saveMood.
  ///
  /// In en, this message translates to:
  /// **'Save Mood'**
  String get saveMood;

  /// No description provided for @moodSaved.
  ///
  /// In en, this message translates to:
  /// **'Mood saved successfully'**
  String get moodSaved;

  /// No description provided for @moodAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Mood Analytics'**
  String get moodAnalytics;

  /// No description provided for @veryPoor.
  ///
  /// In en, this message translates to:
  /// **'Very Poor'**
  String get veryPoor;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get excellent;

  /// No description provided for @meditationLibrary.
  ///
  /// In en, this message translates to:
  /// **'Meditation Library'**
  String get meditationLibrary;

  /// No description provided for @findYourPeace.
  ///
  /// In en, this message translates to:
  /// **'Find your peace'**
  String get findYourPeace;

  /// No description provided for @searchMeditations.
  ///
  /// In en, this message translates to:
  /// **'Search meditations...'**
  String get searchMeditations;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @stress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get stress;

  /// No description provided for @stressRelief.
  ///
  /// In en, this message translates to:
  /// **'Stress Relief'**
  String get stressRelief;

  /// No description provided for @anxiety.
  ///
  /// In en, this message translates to:
  /// **'Anxiety'**
  String get anxiety;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @noMeditationsFound.
  ///
  /// In en, this message translates to:
  /// **'No meditations found'**
  String get noMeditationsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters'**
  String get tryAdjustingFilters;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @findExpert.
  ///
  /// In en, this message translates to:
  /// **'Find Expert'**
  String get findExpert;

  /// No description provided for @searchExperts.
  ///
  /// In en, this message translates to:
  /// **'Search experts by name or specialization...'**
  String get searchExperts;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'yrs exp'**
  String get yearsExperience;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @specializations.
  ///
  /// In en, this message translates to:
  /// **'Specializations'**
  String get specializations;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @selectCallType.
  ///
  /// In en, this message translates to:
  /// **'Select Call Type'**
  String get selectCallType;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @inPerson.
  ///
  /// In en, this message translates to:
  /// **'In Person'**
  String get inPerson;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @manageMeditations.
  ///
  /// In en, this message translates to:
  /// **'Manage Meditations'**
  String get manageMeditations;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @addMeditation.
  ///
  /// In en, this message translates to:
  /// **'Add Meditation'**
  String get addMeditation;

  /// No description provided for @editMeditation.
  ///
  /// In en, this message translates to:
  /// **'Edit Meditation'**
  String get editMeditation;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio File'**
  String get audioFile;

  /// No description provided for @imageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrl;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @createMeditation.
  ///
  /// In en, this message translates to:
  /// **'Create Meditation'**
  String get createMeditation;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// Display days in streak
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysStreak(int count);

  /// Error message when loading experts fails
  ///
  /// In en, this message translates to:
  /// **'Error loading experts'**
  String errorLoadingExperts(String error);

  /// Error message when logout fails
  ///
  /// In en, this message translates to:
  /// **'Logout error: {error}'**
  String errorLogout(String error);

  /// No description provided for @chatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get chatbot;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @appointmentBooked.
  ///
  /// In en, this message translates to:
  /// **'Appointment booked successfully'**
  String get appointmentBooked;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @callType.
  ///
  /// In en, this message translates to:
  /// **'Call Type'**
  String get callType;

  /// No description provided for @yourAccountBanned.
  ///
  /// In en, this message translates to:
  /// **'Your account has been banned.'**
  String get yourAccountBanned;

  /// No description provided for @banReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String banReason(String reason);

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Please contact support.'**
  String get contactSupport;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @featuredMeditations.
  ///
  /// In en, this message translates to:
  /// **'Featured Meditations'**
  String get featuredMeditations;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @errorLoadingMeditations.
  ///
  /// In en, this message translates to:
  /// **'Error loading meditations'**
  String get errorLoadingMeditations;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @calm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get calm;

  /// No description provided for @trackMood.
  ///
  /// In en, this message translates to:
  /// **'Track Mood'**
  String get trackMood;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @moodLog.
  ///
  /// In en, this message translates to:
  /// **'Mood Log'**
  String get moodLog;

  /// No description provided for @howAreYouFeelingToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling\ntoday?'**
  String get howAreYouFeelingToday;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind? (Optional)'**
  String get notesHint;

  /// No description provided for @emotionFactors.
  ///
  /// In en, this message translates to:
  /// **'What\'s affecting your mood?'**
  String get emotionFactors;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @relationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get relationships;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @money.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get money;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @moodLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mood logged successfully! 🎉'**
  String get moodLoggedSuccess;

  /// No description provided for @errorSavingMood.
  ///
  /// In en, this message translates to:
  /// **'Error saving mood: {error}'**
  String errorSavingMood(String error);

  /// No description provided for @moodHistory.
  ///
  /// In en, this message translates to:
  /// **'Mood History'**
  String get moodHistory;

  /// No description provided for @allMoods.
  ///
  /// In en, this message translates to:
  /// **'All Moods'**
  String get allMoods;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @noMoodEntries.
  ///
  /// In en, this message translates to:
  /// **'No mood entries yet'**
  String get noMoodEntries;

  /// No description provided for @startTrackingMood.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your mood to see your history'**
  String get startTrackingMood;

  /// No description provided for @errorLoadingMoods.
  ///
  /// In en, this message translates to:
  /// **'Error loading moods'**
  String get errorLoadingMoods;

  /// No description provided for @moodDetails.
  ///
  /// In en, this message translates to:
  /// **'Mood Details'**
  String get moodDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @factors.
  ///
  /// In en, this message translates to:
  /// **'Factors'**
  String get factors;

  /// No description provided for @noFactors.
  ///
  /// In en, this message translates to:
  /// **'No factors recorded'**
  String get noFactors;

  /// No description provided for @deleteMoodConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this mood entry?'**
  String get deleteMoodConfirm;

  /// No description provided for @deleteMoodMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteMoodMessage;

  /// No description provided for @moodDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mood entry deleted'**
  String get moodDeletedSuccess;

  /// No description provided for @errorDeletingMood.
  ///
  /// In en, this message translates to:
  /// **'Error deleting mood'**
  String get errorDeletingMood;

  /// No description provided for @grouped.
  ///
  /// In en, this message translates to:
  /// **'Grouped'**
  String get grouped;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @avg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avg;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'entry'**
  String get entry;

  /// No description provided for @entries.
  ///
  /// In en, this message translates to:
  /// **'entries'**
  String get entries;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @legend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get legend;

  /// No description provided for @moodEntry.
  ///
  /// In en, this message translates to:
  /// **'Mood Entry'**
  String get moodEntry;

  /// No description provided for @howWereYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How were you feeling?'**
  String get howWereYouFeeling;

  /// No description provided for @whatInfluencedMood.
  ///
  /// In en, this message translates to:
  /// **'What influenced your mood?'**
  String get whatInfluencedMood;

  /// No description provided for @moodUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mood entry updated successfully! 🎉'**
  String get moodUpdatedSuccess;

  /// No description provided for @errorUpdatingMood.
  ///
  /// In en, this message translates to:
  /// **'Error updating mood'**
  String get errorUpdatingMood;

  /// No description provided for @findAnExpert.
  ///
  /// In en, this message translates to:
  /// **'Find an Expert'**
  String get findAnExpert;

  /// No description provided for @expert.
  ///
  /// In en, this message translates to:
  /// **'expert'**
  String get expert;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get available;

  /// No description provided for @noExpertsFound.
  ///
  /// In en, this message translates to:
  /// **'No experts found'**
  String get noExpertsFound;

  /// No description provided for @tryAnotherFilter.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different specialization'**
  String get tryAnotherFilter;

  /// No description provided for @depression.
  ///
  /// In en, this message translates to:
  /// **'Depression'**
  String get depression;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @yrs.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get yrs;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @availableDays.
  ///
  /// In en, this message translates to:
  /// **'Available Days'**
  String get availableDays;

  /// No description provided for @availableTimeSlots.
  ///
  /// In en, this message translates to:
  /// **'Available Time Slots'**
  String get availableTimeSlots;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectDateToView.
  ///
  /// In en, this message translates to:
  /// **'Select a date to view available time slots'**
  String get selectDateToView;

  /// No description provided for @chooseDateFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'Choose a date from the calendar above'**
  String get chooseDateFromCalendar;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @audioOnlyConsultation.
  ///
  /// In en, this message translates to:
  /// **'Audio only consultation'**
  String get audioOnlyConsultation;

  /// No description provided for @faceToFaceConsultation.
  ///
  /// In en, this message translates to:
  /// **'Face-to-face video consultation'**
  String get faceToFaceConsultation;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No Upcoming Appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @bookAppointmentToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Book an appointment with an expert to get started'**
  String get bookAppointmentToGetStarted;

  /// No description provided for @noAppointmentHistory.
  ///
  /// In en, this message translates to:
  /// **'No Appointment History'**
  String get noAppointmentHistory;

  /// No description provided for @pastAppointmentsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your past appointments will appear here'**
  String get pastAppointmentsWillAppear;

  /// No description provided for @cancelAppointment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment'**
  String get cancelAppointment;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelAppointmentQuestion.
  ///
  /// In en, this message translates to:
  /// **'Cancel Appointment?'**
  String get cancelAppointmentQuestion;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortBy;

  /// No description provided for @ratingSort.
  ///
  /// In en, this message translates to:
  /// **'⭐ Rating'**
  String get ratingSort;

  /// No description provided for @durationSort.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Duration'**
  String get durationSort;

  /// No description provided for @nameSort.
  ///
  /// In en, this message translates to:
  /// **'🔤 Name'**
  String get nameSort;

  /// No description provided for @meditationsFound.
  ///
  /// In en, this message translates to:
  /// **'meditations found'**
  String get meditationsFound;

  /// No description provided for @meditationFound.
  ///
  /// In en, this message translates to:
  /// **'meditation found'**
  String get meditationFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or filter'**
  String get tryDifferentSearch;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @alwaysReadyToHelp.
  ///
  /// In en, this message translates to:
  /// **'Always ready to help you'**
  String get alwaysReadyToHelp;

  /// No description provided for @clearChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear chat history?'**
  String get clearChatHistory;

  /// No description provided for @clearChatConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all chat history?'**
  String get clearChatConfirmation;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Professional wellbeing platform'**
  String get welcomeTagline;

  /// No description provided for @aiPoweredInsights.
  ///
  /// In en, this message translates to:
  /// **'AI-powered insights'**
  String get aiPoweredInsights;

  /// No description provided for @trackProgress.
  ///
  /// In en, this message translates to:
  /// **'Track progress over time'**
  String get trackProgress;

  /// No description provided for @privateSecure.
  ///
  /// In en, this message translates to:
  /// **'Private and secure'**
  String get privateSecure;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @termsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get termsAgreement;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @signInToModiki.
  ///
  /// In en, this message translates to:
  /// **'Sign in to MODIKI'**
  String get signInToModiki;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your journey'**
  String get signInToContinue;

  /// No description provided for @joinUsToday.
  ///
  /// In en, this message translates to:
  /// **'Join us and start your journey today'**
  String get joinUsToday;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @adminSetup.
  ///
  /// In en, this message translates to:
  /// **'Admin Setup'**
  String get adminSetup;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
