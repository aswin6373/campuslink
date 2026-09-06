// Comprehensive smoke tests for CampusLink.
//
// These tests pump the real widgets (HomeScreen, LoginScreen, SignupScreen,
// Splash, MainPage, Chatbot, CommunityPost, Chatroom, Dashboard, Events,
// Attendance, Profile) with SharedPreferences mocked so every screen can
// build without a live backend or Firebase.

import 'package:campuslink/app_theme.dart';
import 'package:campuslink/data/data_provider.dart';
import 'package:campuslink/screens/authentication/signup_screen.dart';
import 'package:campuslink/screens/authentication/user_login.dart';
import 'package:campuslink/screens/chatbot/chatbot.dart';
import 'package:campuslink/screens/chatroom/chatroom.dart';
import 'package:campuslink/screens/community_post/community_post.dart';
import 'package:campuslink/screens/dashboard/attendance_report.dart';
import 'package:campuslink/screens/dashboard/event/event_list_screen.dart';
import 'package:campuslink/screens/dashboard/student_management_screen.dart';
import 'package:campuslink/screens/dashboard/teacher_management_screen.dart';
import 'package:campuslink/widgets/home_screen.dart';
import 'package:campuslink/widgets/main_page.dart';
import 'package:campuslink/widgets/profile.dart';
import 'package:campuslink/widgets/splash_screen.dart';
import 'package:campuslink/services/media_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('EMPTY')));
}

Widget wrap(Widget child, {DataProvider? dataProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DataProvider>.value(
          value: dataProvider ?? DataProvider()),
      ChangeNotifierProvider<MediaProvider>(create: (_) => MediaProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
      routes: {
        '/homeScreen': (context) => const _EmptyRoute(),
        '/main': (context) => const _EmptyRoute(),
        '/adminLogin': (context) => const LoginScreen(userType: 'Admin'),
        '/adminSignup': (context) => const SignupScreen(userType: 'Admin'),
      },
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => const _EmptyRoute(),
        settings: settings,
      ),
    ),
  );
}

/// Pumps the widget tree, tolerating infinite animations (splash repeat,
/// shimmer) that would make pumpAndSettle time out.
Future<void> pumpFor(WidgetTester tester, [Duration duration =
    const Duration(seconds: 1)]) async {
  await tester.pump();
  await tester.pump(duration);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen (role selection)', () {
    testWidgets('shows all four role cards and navigates to login',
        (tester) async {
      await tester.pumpWidget(wrap(const HomeScreen()));
      await pumpFor(tester);

      expect(find.text('CampusLink'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Teacher'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);

      await tester.tap(find.text('Admin'));
      await pumpFor(tester);

      expect(find.text('Admin Login'), findsOneWidget);
      expect(find.text('Welcome back to CampusLink'), findsOneWidget);
    });
  });

  group('SplashScreen', () {
    testWidgets('renders brand UI', (tester) async {
      await tester.pumpWidget(wrap(const SplashScreen()));
      await tester.pump();
      expect(find.text('CampusLink'), findsOneWidget);
      expect(find.text('Connecting Campus Communities'), findsOneWidget);
    });

    testWidgets('redirects to login when not logged in', (tester) async {
      await tester.pumpWidget(wrap(const SplashScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('EMPTY'), findsOneWidget);
    });

    testWidgets('redirects to main page when logged in', (tester) async {
      SharedPreferences.setMockInitialValues({
        'isLoggedIn': true,
        'userId': 'admin1',
        'userType': 'Admin',
        'institution': 'ebenezer',
      });
      await tester.pumpWidget(wrap(const SplashScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('EMPTY'), findsOneWidget);
    });
  });

  group('LoginScreen', () {
    testWidgets('validates empty username and password', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(userType: 'Admin')));
      await pumpFor(tester);

      await tester.tap(find.text('Login'));
      await pumpFor(tester);

      expect(find.text('Please enter a username'), findsOneWidget);
    });

    testWidgets('guest mode shows institution dropdown instead of password',
        (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(userType: 'Guest')));
      await pumpFor(tester);

      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Select Institution'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsNothing);

      // Guest requires institution selection
      await tester.enterText(
          find.widgetWithText(TextField, 'Username'), 'guestuser');
      await tester.tap(find.text('Continue as Guest'));
      await pumpFor(tester);
      expect(find.text('Please select an institution'), findsOneWidget);
    });

    testWidgets('admin login shows signup link', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen(userType: 'Admin')));
      await pumpFor(tester);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);
    });
  });

  group('SignupScreen', () {
    testWidgets('form validation blocks empty submission', (tester) async {
      await tester.pumpWidget(wrap(const SignupScreen(userType: 'Admin')));
      await pumpFor(tester);

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await pumpFor(tester);

      expect(find.text('Please enter your name'), findsOneWidget);
      expect(find.text('Please enter your institution'), findsOneWidget);
      expect(find.text('Please enter an email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('email format validation works', (tester) async {
      await tester.pumpWidget(wrap(const SignupScreen(userType: 'Admin')));
      await pumpFor(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'john');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Institution'), 'ebenezer');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'secret123');

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await pumpFor(tester);

      expect(find.text('Invalid email format'), findsOneWidget);
    });

    testWidgets('password mismatch is caught', (tester) async {
      await tester.pumpWidget(wrap(const SignupScreen(userType: 'Admin')));
      await pumpFor(tester);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'john');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Institution'), 'ebenezer');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'john@x.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'other123');

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await pumpFor(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('MainPage (navigation shell)', () {
    testWidgets('guest layout has 3 tabs and renders dashboard',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Guest', userId: 'guest1'),
      ));
      await pumpFor(tester);

      expect(find.text('Guest Dashboard'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Chatbot'), findsOneWidget);
    });

    testWidgets('admin layout has 4 tabs and switching tabs works',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Admin', userId: 'admin1'),
      ));
      await pumpFor(tester);

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Chatroom'), findsOneWidget);

      await tester.tap(find.text('Community'));
      await pumpFor(tester);
      expect(find.text('Community Post'), findsOneWidget);

      await tester.tap(find.text('Chatbot'));
      await pumpFor(tester);
      expect(find.text('Campus Assistant'), findsOneWidget);
    });

    testWidgets('unknown user type falls back to guest layout',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Hacker', userId: 'x'),
      ));
      await pumpFor(tester);

      // Must not crash and must render a working shell
      expect(find.text('Guest Dashboard'), findsOneWidget);
    });
  });

  group('Chatbot', () {
    testWidgets('renders input bar and assistant header', (tester) async {
      await tester.pumpWidget(wrap(const Chatbot()));
      await pumpFor(tester);

      expect(find.text('Campus Assistant'), findsOneWidget);
      expect(find.text('Ask me anything...'), findsOneWidget);
    });

    testWidgets('empty message does nothing', (tester) async {
      await tester.pumpWidget(wrap(const Chatbot()));
      await pumpFor(tester);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await pumpFor(tester);

      expect(find.byIcon(Icons.send_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Chatroom', () {
    testWidgets('renders header and input', (tester) async {
      await tester.pumpWidget(wrap(const Chatroom()));
      await pumpFor(tester);

      expect(find.text('Campus Chat'), findsOneWidget);
      expect(find.text('Type a message...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('emoji picker toggles', (tester) async {
      await tester.pumpWidget(wrap(const Chatroom()));
      await pumpFor(tester);

      // Picker hidden initially
      expect(find.text('😀'), findsNothing);

      await tester.tap(find.byIcon(Icons.emoji_emotions));
      await pumpFor(tester);
      expect(find.text('😀'), findsOneWidget);

      await tester.tap(find.text('😀'));
      await pumpFor(tester);
      // Picker closes; emoji was appended into the message input
      expect(find.byType(GridView), findsNothing);
      expect(find.widgetWithText(TextField, '😀'), findsOneWidget);
    });
  });

  group('CommunityPost', () {
    testWidgets('renders composer', (tester) async {
      await tester.pumpWidget(wrap(const CommunityPost(username: 'admin1')));
      await pumpFor(tester);

      expect(find.text('Community Post'), findsOneWidget);
      expect(find.text('Write something...'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Dashboard', () {
    testWidgets('student dashboard shows welcome and quick actions',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Student', userId: 'stud1'),
      ));
      await pumpFor(tester);

      expect(find.text('Student Dashboard'), findsOneWidget);
      expect(find.text('Welcome Back,'), findsOneWidget);
      expect(find.text('stud1'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('teacher dashboard shows manage students/events',
        (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Teacher', userId: 'teach1'),
      ));
      await pumpFor(tester);

      expect(find.text('Teacher Dashboard'), findsOneWidget);
      expect(find.text('Manage Students'), findsOneWidget);
      expect(find.text('Manage Events'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
    });

    testWidgets('admin dashboard shows stat cards', (tester) async {
      await tester.pumpWidget(wrap(
        const MainPage(userType: 'Admin', userId: 'admin1'),
      ));
      await pumpFor(tester);

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Total Teachers'), findsOneWidget);
    });
  });

  group('Profile', () {
    testWidgets('renders fields and logout dialog works', (tester) async {
      await tester.pumpWidget(wrap(const ProfilePage()));
      await pumpFor(tester);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.logout));
      await pumpFor(tester);

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    });
  });

  group('Student & Teacher management', () {
    testWidgets('manage students screen renders list shell', (tester) async {
      await tester.pumpWidget(wrap(
        const ManageStudentsScreen(userType: 'Admin', userId: 'admin1'),
      ));
      await pumpFor(tester);

      expect(find.text('Manage Students'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('manage teachers screen renders list shell', (tester) async {
      await tester.pumpWidget(wrap(
        const ManageTeachersScreen(userType: 'Admin', userId: 'admin1'),
      ));
      await pumpFor(tester);

      expect(find.text('Manage Teachers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Events', () {
    testWidgets('event list screen renders', (tester) async {
      await tester.pumpWidget(wrap(const EventListScreen()));
      await pumpFor(tester);

      expect(find.text('Events'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Attendance', () {
    testWidgets('attendance report renders date scroller and summary',
        (tester) async {
      await tester.pumpWidget(wrap(const AttendanceReport()));
      await pumpFor(tester);

      expect(find.text('Student Attendance'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DataProvider', () {
    test('error state propagates when no institution', () async {
      final provider = DataProvider();
      await provider.fetchStudents();
      expect(provider.error, isNotNull);
      expect(provider.students, isEmpty);
    });
  });
}
