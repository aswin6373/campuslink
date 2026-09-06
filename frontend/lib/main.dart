import 'package:campuslink/app_theme.dart';
import 'package:campuslink/services/api_client.dart';
import 'package:campuslink/screens/authentication/user_login.dart';
import 'package:campuslink/screens/authentication/signup_screen.dart';
import 'package:campuslink/screens/chatbot/chatbot.dart';
import 'package:campuslink/screens/chatroom/chatroom.dart';
import 'package:campuslink/screens/community_post/community_post.dart';
import 'package:campuslink/widgets/home_screen.dart';
import 'package:campuslink/widgets/main_page.dart';
import 'package:campuslink/widgets/profile.dart';
import 'package:campuslink/data/data_provider.dart';
import 'package:campuslink/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:campuslink/services/media_provider.dart';
import 'package:campuslink/services/my_http_overrides.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:campuslink/services/firebase_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Only allow self-signed certificates in debug builds; production uses
  // Render's valid HTTPS certificate.
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ApiClient.warmTokenCache();
  await _initFirebase();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: CampusLinkApp(),
    ),
  );
}

/// Initializes Firebase and push notifications.
///
/// Failures (e.g. missing platform config on web) are non-fatal: the app
/// runs without push notifications instead of crashing.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    await FirebaseAPI.initFCM();
  } catch (e) {
    debugPrint('Firebase/FCM unavailable: $e');
  }
}

class CampusLinkApp extends StatefulWidget {
  const CampusLinkApp({super.key});

  @override
  _CampusLinkAppState createState() => _CampusLinkAppState();
}

class _CampusLinkAppState extends State<CampusLinkApp> {
  @override
  void initState() {
    super.initState();
    _showForegroundNotifications();
  }

  void _showForegroundNotifications() {
    // Local notifications already handle foreground FCM messages (see
    // FirebaseAPI). No in-app snackbar wiring is needed here.
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CAMPUSLINK',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: SplashScreen(),
      routes: {
        '/homeScreen': (context) => HomeScreen(),
        '/adminLogin': (context) => LoginScreen(userType: "Admin"),
        '/adminSignup': (context) => SignupScreen(userType: "Admin"),
        '/admin_community_post': (context) => CommunityPost(username: 'Admin'),
        '/admin_chatbot': (context) => Chatbot(),
        '/adminProfile': (context) => ProfilePage(),
        '/teacherLogin': (context) => LoginScreen(userType: 'Teacher'),
        '/teacherSignup': (context) => SignupScreen(userType: 'Teacher'),
        '/teacherCommunityPost': (context) => CommunityPost(username: 'Teacher'),
        '/teacherChatroom': (context) => Chatroom(),
        '/teacherChatbot': (context) => Chatbot(),
        '/teacherProfile': (context) => ProfilePage(),
        '/studentLogin': (context) => LoginScreen(userType: "Student"),
        '/studentSignup': (context) => SignupScreen(userType: "Student"),
        '/studentCommunityPost': (context) => CommunityPost(username: 'Student'),
        '/studentChatroom': (context) => Chatroom(),
        '/studentChatbot': (context) => Chatbot(),
        '/studentProfile': (context) => ProfilePage(),
        '/guestLogin': (context) => LoginScreen(userType: 'Guest'),
        '/guestCommunityPost': (context) => CommunityPost(username: 'Guest'),
        '/guestChatbot': (context) => Chatbot(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MainPage(
              userType: args['userType'] as String,
              userId: args['userId'] as String,
            ),
          );
        }
        return null;
      },
    );
  }
}
