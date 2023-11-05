import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:otp_timer_button/otp_timer_button.dart';
import 'package:pinput/pinput.dart';

import 'package:sportistan_partners/authentication/search_field.dart';
import 'package:sportistan_partners/nav_bar/nav_home.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneAuthentication extends StatefulWidget {
  const PhoneAuthentication({super.key});

  @override
  State<PhoneAuthentication> createState() => _PhoneAuthenticationState();
}

class _PhoneAuthenticationState extends State<PhoneAuthentication>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String countryCode = "+91";
  String? verification;

  final _auth = FirebaseAuth.instance;
  final _server = FirebaseFirestore.instance;

  int resendOtpCounter = 0;

  GoogleSignInAccount? currentUser;

  Future<void> _launchInBrowser(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchUniversalLinkIos(Uri url) async {
    final bool nativeAppLaunchSucceeded = await launchUrl(
      url,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (!nativeAppLaunchSucceeded) {
      await launchUrl(
        url,
        mode: LaunchMode.inAppWebView,
      );
    }
  }

  GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: '100473162886811688440',
  );
  final Uri toLaunch = Uri(
      scheme: 'https', host: 'www.sportslovez.in', path: 'Terms&Conditions/');

  @override
  void dispose() {
    numberController.dispose();
    otpController.dispose();
    _controller.dispose();
    _server.terminate();
    super.dispose();
  }

  @override
  void initState() {
    _server.enableNetwork();
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  TextEditingController numberController = TextEditingController();
  final otpController = TextEditingController();
  GlobalKey<FormState> numberKey = GlobalKey<FormState>();
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  ValueNotifier<bool> buttonDisable = ValueNotifier<bool>(false);
  ValueNotifier<bool> imageShow = ValueNotifier<bool>(true);
  OtpTimerButtonController controller = OtpTimerButtonController();

  requestOtp() {
    controller.loading();
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        loading.value = true;
        await _verifyByNumber(
            countryCode, numberController.value.text.toString());
      } on FirebaseAuthException catch (e) {
        _showError(e.message.toString());
      }
      controller.startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = Colors.white;
    const fillColor = Colors.white;
    const borderColor = Colors.white;

    final defaultPinTheme = PinTheme(
      width: MediaQuery
          .of(context)
          .size
          .width / 10,
      height: MediaQuery
          .of(context)
          .size
          .width / 10,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: DelayedDisplay(
          child: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/permissionBackground.png"),
                    fit: BoxFit.fill),
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: imageShow,
                          builder: (context, value, child) {
                            return value
                                ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: DelayedDisplay(
                                child: Image.asset(
                                  "assets/logo.png",
                                  color: Colors.white,
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height /
                                      10,
                                ),
                              ),
                            )
                                : Container();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Let's",
                                style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize:
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height / 20,
                                    color: Colors.white),
                              ),
                              Container()
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Start",
                                style: TextStyle(
                                    fontFamily: "DMSans",
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                    MediaQuery
                                        .of(context)
                                        .size
                                        .height / 10,
                                    color: Colors.white),
                              ),
                              SizedBox(
                                height: MediaQuery
                                    .of(context)
                                    .size
                                    .height / 10,
                                child: Lottie.asset(
                                  'assets/bouncingBall.json',
                                  controller: _controller,
                                  onLoaded: (composition) {
                                    _controller
                                      ..duration = composition.duration
                                      ..repeat();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: loading,
                          builder:
                              (BuildContext context, value, Widget? child) {
                            return SizedBox(
                              width: MediaQuery
                                  .of(context)
                                  .size
                                  .width / 1.2,
                              child: Form(
                                key: numberKey,
                                child: TextFormField(
                                  onTap: () {
                                    imageShow.value = false;
                                  },
                                  readOnly: loading.value,
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Number required.";
                                    } else if (value.length <= 9) {
                                      return "Enter 10 digits.";
                                    } else {
                                      return null;
                                    }
                                  },
                                  controller: numberController,
                                  onChanged: (data) {
                                    numberKey.currentState!.validate();
                                  },
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  autofillHints: const [
                                    AutofillHints.telephoneNumberLocal
                                  ],
                                  decoration: InputDecoration(
                                      suffixIcon: InkWell(
                                          onTap: () {
                                            loading.value = false;
                                            otpController.clear();
                                            numberController.clear();
                                          },
                                          child: const Icon(Icons.edit)),
                                      fillColor: Colors.white,
                                      border: const OutlineInputBorder(),
                                      errorStyle:
                                      const TextStyle(color: Colors.white),
                                      filled: true,
                                      prefixIcon: CountryCodePicker(
                                        showCountryOnly: true,
                                        onChanged: (value) {
                                          countryCode =
                                              value.dialCode.toString();
                                        },
                                        favorite: const ["IN"],
                                        initialSelection: "IN",
                                      ),
                                      hintText: "Phone Number",
                                      hintStyle:
                                      const TextStyle(color: Colors.black),
                                      labelStyle:
                                      const TextStyle(color: Colors.black)),
                                ),
                              ),
                            );
                          },
                        ),
                        ValueListenableBuilder(
                          valueListenable: loading,
                          builder: (context, value, child) {
                            return value
                                ? Padding(
                              padding: EdgeInsets.all(
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width / 25),
                              child: Pinput(
                                controller: otpController,
                                androidSmsAutofillMethod:
                                AndroidSmsAutofillMethod
                                    .smsUserConsentApi,
                                listenForMultipleSmsOnAndroid: true,
                                defaultPinTheme: defaultPinTheme,
                                length: 6,
                                separatorBuilder: (index) =>
                                const SizedBox(width: 8),
                                hapticFeedbackType:
                                HapticFeedbackType.lightImpact,
                                onCompleted: (pin) {
                                  _manualVerify(pin);
                                },
                                cursor: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 9),
                                      width: 22,
                                      height: 1,
                                      color: focusedBorderColor,
                                    ),
                                  ],
                                ),
                                focusedPinTheme: defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!
                                      .copyWith(
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: focusedBorderColor),
                                  ),
                                ),
                                submittedPinTheme:
                                defaultPinTheme.copyWith(
                                  decoration: defaultPinTheme.decoration!
                                      .copyWith(
                                    color: fillColor,
                                    borderRadius:
                                    BorderRadius.circular(19),
                                    border: Border.all(
                                        color: focusedBorderColor),
                                  ),
                                ),
                                errorPinTheme:
                                defaultPinTheme.copyBorderWith(
                                  border:
                                  Border.all(color: Colors.redAccent),
                                ),
                              ),
                            )
                                : Container();
                          },
                        ),
                        ValueListenableBuilder(
                          builder:
                              (BuildContext context, value, Widget? child) {
                            return value
                                ? Container()
                                : Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CupertinoButton(
                                onPressed: () async {
                                  if (numberKey.currentState!
                                      .validate()) {
                                    try {
                                      loading.value = true;
                                      await _verifyByNumber(
                                          countryCode,
                                          numberController.value.text
                                              .toString());
                                    } on FirebaseAuthException catch (e) {
                                      _showError(e.message.toString());
                                    }
                                  }
                                },
                                color: Colors.green,
                                child: const Text(
                                  "Send OTP",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                          valueListenable: loading,
                        ),
                        ValueListenableBuilder(
                          valueListenable: loading,
                          builder: (BuildContext context, bool value,
                              Widget? child) {
                            return value
                                ? SizedBox(
                              width:
                              MediaQuery
                                  .of(context)
                                  .size
                                  .width / 2,
                              child: OtpTimerButton(
                                buttonType: ButtonType.elevated_button,
                                controller: controller,
                                onPressed: () {
                                  requestOtp();
                                },
                                text: const Text('Resend OTP',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: "DMSans")),
                                duration: 30,
                              ),
                            )
                                : Container();
                          },
                        ),
                      ],
                    ),
                    CupertinoButton(
                        color: Colors.white,
                        onPressed: () {
                          handleSignIn();
                        },
                        child: SizedBox(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width / 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const Text(
                                "Continue with Google",
                                style: TextStyle(
                                    color: Colors.black, fontFamily: "DMSans"),
                              ),
                              Image.asset("assets/gicon.png",
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height / 45)
                            ],
                          ),
                        )),
                    ValueListenableBuilder(
                      valueListenable: buttonDisable,
                      builder: (context, value, child) {
                        return value
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : Container();
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery
                              .of(context)
                              .size
                              .width / 8,
                          left: MediaQuery
                              .of(context)
                              .size
                              .width / 30,
                          right: MediaQuery
                              .of(context)
                              .size
                              .width / 30),
                      child: GestureDetector(
                        onTap: () async {
                          Platform.isIOS
                              ? _launchUniversalLinkIos(toLaunch)
                              : _launchInBrowser(toLaunch);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'By pressing continue, you agree to our ',
                            style: TextStyle(
                              fontFamily: "DMSans",
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: MediaQuery
                                  .of(context)
                                  .size
                                  .width / 28,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms,',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "DMSans",
                                  fontSize:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width / 30,
                                ),
                              ),
                              TextSpan(
                                text: ' Privacy Policy',
                                style: TextStyle(
                                  fontFamily: "DMSans",
                                  color: Colors.white,
                                  fontSize:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width / 30,
                                ),
                              ),
                              TextSpan(
                                text: ' and ',
                                style: TextStyle(
                                  fontFamily: "DMSans",
                                  color: Colors.white,
                                  fontSize:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width / 30,
                                ),
                              ),
                              TextSpan(
                                text: 'Cookies Policy',
                                style: TextStyle(
                                  fontFamily: "DMSans",
                                  color: Colors.white,
                                  fontSize:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .width / 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          ),
        ));
  }

  void _showError(String error) {
    Errors.flushBarAuth(error, context);
  }

  Future<void> _verifyByNumber(String countryCode, String number) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: countryCode + number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          buttonDisable.value = true;
          await _auth
              .signInWithCredential(credential)
              .then((value) => {_checkUserExistence()});
        } on FirebaseAuthException catch (e) {
          buttonDisable.value = false;
          _showError(e.message.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          buttonDisable.value = false;

          _showError("'The provided phone number is not valid.'");
        } else {
          buttonDisable.value = false;

          _showError(e.message.toString());
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verification = verificationId;
      },
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _manualVerify(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verification.toString(), smsCode: smsCode);
    try {
      buttonDisable.value = true;
      await _auth
          .signInWithCredential(credential)
          .then((value) => {_checkUserExistence()});
    } on FirebaseAuthException catch (e) {
      buttonDisable.value = false;

      _showError(e.message.toString());
    }
  }

  Future<void> handleSignOut() async {
    if (currentUser != null) {
      googleSignIn.disconnect();
    }
  }

  Future<void> handleSignIn() async {
    try {
      currentUser = await googleSignIn.signIn();
      if (currentUser != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
        await currentUser!.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          if (mounted) {
            _checkUserExistence();
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
      else if (e.code == 'invalid-credential') {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

Future<void> _checkUserExistence() async {
  CollectionReference collectionReference = _server
      .collection("SportistanPartnersProfile")
      .doc(_auth.currentUser!.uid)
      .collection("Account");
  QuerySnapshot querySnapshot = await collectionReference.get();
  if (querySnapshot.docs.isEmpty) {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _server
          .collection("SportistanPartners")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) =>
      {
        if (value.docs.isNotEmpty)
          {
            _server
                .collection("SportistanPartnersProfile")
                .doc(_auth.currentUser!.uid)
                .collection("Account")
                .doc(DateTime.now().toString())
                .set({'accountCreatedAt': DateTime.now()}).then(
                    (value) => {_moveToHome()}),
          }
        else
          {
            _moveToRegister()}
      });
    }
  } else {
    _moveToHome();
  }
}

void _moveToRegister() {
  PageRouter.pushRemoveUntil(context, const SearchField());
}

void _moveToHome() {
  PageRouter.pushRemoveUntil(context, const NavHome());
}}
