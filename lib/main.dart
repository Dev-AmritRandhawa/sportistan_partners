import 'dart:async';
import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportistan_partners/authentication/phone_authentication.dart';
import 'package:sportistan_partners/bookings/local_notifications.dart';
import 'package:sportistan_partners/firebase_options.dart';
import 'package:sportistan_partners/nav_bar/nav_home.dart';
import 'package:sportistan_partners/onBoarding/onboard.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug);
  requestPermission();

  initializeDateFormatting('en', '').then((value) => null);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MaterialApp(home: MyApp()));
  });
}



final messaging = FirebaseMessaging.instance;

Future<void> requestPermission() async {
  final settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
    registerFCM();
  }
}

Future<void> registerFCM() async {
  String? token = await messaging.getToken();
  Notifications.init();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final _auth = FirebaseAuth.instance;

  final _server = FirebaseFirestore.instance;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(const Duration(milliseconds: 3500), () async {
              _auth.authStateChanges().listen((User? user) async {
                if (user != null) {
                  try {
                    CollectionReference collectionReference = _server
                        .collection("SportistanPartnersProfile")
                        .doc(_auth.currentUser!.uid)
                        .collection("Account");
                    QuerySnapshot querySnapshot =
                        await collectionReference.get();
                    if (querySnapshot.docs.isEmpty) {
                      if (mounted) {
                        PageRouter.pushRemoveUntil(
                            context, const PhoneAuthentication());
                      }
                    } else {
                      if (mounted) {
                        PageRouter.pushRemoveUntil(context, const NavHome());
                      }
                    }
                  } on SocketException catch (e) {
                    if (mounted) {
                      Errors.flushBarInform(
                          e.message, context, "Connectivity Error");
                    }
                  }
                } else {
                  _userStateSave();
                }
              });
            }));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(),
              SizedBox(
                height: MediaQuery.of(context).size.height / 4,
                width: MediaQuery.of(context).size.width / 2,
                child: Lottie.asset(
                  'assets/loading.json',
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..repeat();
                  },
                ),
              ),
              AnimatedTextKit(
                animatedTexts: [
                  RotateAnimatedText('Made With ❤️ of Ground Owners',
                      textStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.height / 40),
                      duration: const Duration(milliseconds: 3500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _moveToDecision(Widget widget) async {
    if (mounted) {
      PageRouter.pushRemoveUntil(context, widget);
    }
  }

  Future<void> _userStateSave() async {
    final value = await SharedPreferences.getInstance();
    final bool? result = value.getBool('onBoarding');
    if (result != null) {
      if (result) {
        _moveToDecision(const PhoneAuthentication());
      } else {
        _moveToDecision(const OnBoard());
      }
    } else {
      _moveToDecision(const OnBoard());
    }
  }
}
