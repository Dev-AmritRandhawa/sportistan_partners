import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sportistan_partners/authentication/location_permission.dart';
import 'package:sportistan_partners/authentication/search_field.dart';
import 'package:sportistan_partners/main.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';
import 'dart:async';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _auth = FirebaseAuth.instance;
  final otpController = TextEditingController();
  final numberController = TextEditingController();
  GlobalKey<FormState> numberKey = GlobalKey<FormState>();
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);

  String countryCode = "+91";
  String? verification;
  PanelController pc = PanelController();
  ScrollController sc = ScrollController();

  GoogleSignInAccount? currentUser;
  bool isAuthorized = false;

  GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: '100473162886811688440',
  );
  late String urls;
  Future<void> _handleSignIn() async {
    try {
      currentUser = await googleSignIn.signIn();
      linkGoogleAccountWithNumber();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> handleSignOut() async {
    if (currentUser != null) {
      googleSignIn.disconnect();
    }
  }

  @override
  void initState() {
    check();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0XFFfffbf0),
      body: SlidingUpPanel(
        controller: pc,
        panelBuilder: (sc) => panel(sc),
        maxHeight: MediaQuery.of(context).size.height / 2,
        minHeight: 0,
        body: SafeArea(
            child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CupertinoButton(
                            onPressed: () {
                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (ctx) {
                                  return Platform.isIOS
                                      ? CupertinoAlertDialog(
                                          content: const Text(
                                              "Would you like to Logout?",
                                              style: TextStyle(
                                                  fontFamily: "Nunito")),
                                          title: const Text("Account Logout"),
                                          actions: [
                                            TextButton(
                                                onPressed: () async {
                                                  await FirebaseAuth.instance
                                                      .signOut()
                                                      .then((value) => {
                                                            handleSignOut()
                                                                .then(
                                                                    (value) => {
                                                                          Navigator.pop(
                                                                              ctx),
                                                                          PageRouter.pushRemoveUntil(
                                                                              context,
                                                                              const MyApp())
                                                                        })
                                                          });
                                                },
                                                child: const Text(
                                                  "Logout",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ],
                                        )
                                      : AlertDialog(
                                          content: const Text(
                                              "Would you like to Logout?",
                                              style: TextStyle(
                                                  fontFamily: "Nunito")),
                                          title: const Text("Account Logout"),
                                          actions: [
                                            TextButton(
                                                onPressed: () async {
                                                  await FirebaseAuth.instance
                                                      .signOut()
                                                      .then((value) => {
                                                            handleSignOut()
                                                                .then(
                                                                    (value) => {
                                                                          Navigator.pop(
                                                                              ctx),
                                                                          PageRouter.pushRemoveUntil(
                                                                              context,
                                                                              const MyApp())
                                                                        })
                                                          });
                                                },
                                                child: const Text(
                                                  "Logout",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ],
                                        );
                                },
                              );
                            },
                            child: Row(
                              children: [
                                Icon(Icons.power_settings_new,
                                    color: Colors.green.shade900),
                                Text(
                                  "Logout",
                                  style:
                                      TextStyle(color: Colors.green.shade900),
                                ),
                              ],
                            )),
                      ],
                    ),
                    TextButton(
                        onPressed: () async {},
                        child: const Text(
                          "Change Profile Photo",
                          style: TextStyle(color: Colors.black54),
                        )),
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade400,
                      maxRadius: MediaQuery.of(context).size.height / 15,
                      child: Icon(Icons.account_circle,
                          color: Colors.white,
                          size: MediaQuery.of(context).size.height / 10),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _auth.currentUser!.phoneNumber != null
                              ? _auth.currentUser!.phoneNumber.toString()
                              : _auth.currentUser!.email.toString(),
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: MediaQuery.of(context).size.height / 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: "DMSans"),
                        )),
                    isAuthorized
                        ? CupertinoButton(
                            borderRadius: BorderRadius.zero,
                            color: Colors.black87,
                            onPressed: () {
                              _handleSignIn();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Text(
                                  "Connect with Google Account",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset("assets/gicon.png",
                                      height:
                                          MediaQuery.of(context).size.height /
                                              45),
                                )
                              ],
                            )) : Card(
                        color: Colors.green,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              "Connected (${_auth.currentUser!.email})",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: "DMSans")),
                        )),
                  ],
                ),
                isAuthorized
                    ? Container()
                    : const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Connect with Google Account helps you to login faster",
                          style: TextStyle(
                              color: Colors.black54, fontFamily: "DMSans"),
                        ),
                      ),
                DelayedDisplay(
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.height / 40),
                          child: InkWell(
                            onTap: () async {
                              LocationPermission permission;
                              permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.always ||
                                  permission == LocationPermission.whileInUse) {
                                if (mounted) {
                                  PageRouter.push(context, const SearchField());
                                }
                              } else {
                                if (mounted) {
                                  PageRouter.push(
                                      context, const CheckLocationPermission());
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Add New Ground & New Facility",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.sports_baseball,
                                  color: Colors.lightGreen,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.height / 40),
                          child: InkWell(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (ctx) => Platform.isIOS
                                      ? CupertinoAlertDialog(
                                          title: const Text("Want to talk?"),
                                          content: const Text(
                                              "We will connect to you to a person who will assist you",
                                              style: TextStyle(
                                                  fontFamily: "DMSans")),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  _callNumber();
                                                },
                                                child: const Text(
                                                  "Call Now",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ],
                                        )
                                      : AlertDialog(
                                          title: const Text("Want to talk?"),
                                          content: const Text(
                                              "We will connect to you to a person who will assist you"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  _callNumber();
                                                },
                                                child: const Text(
                                                  "Call Now",
                                                  style: TextStyle(
                                                      color: Colors.green),
                                                )),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                },
                                                child: const Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                )),
                                          ],
                                        ));
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Contact Helpdesk",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.support_agent,
                                  color: Colors.green,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.height / 40),
                          child: InkWell(
                            onTap: () {
                              pc.open();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Change Number",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.phone,
                                  color: Colors.green,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.height / 40),
                          child: InkWell(
                            onTap: () {
                              shareApp();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Share App",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.ios_share_outlined,
                                  color: Colors.green,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      isAuthorized
                          ? Container() : Card(
                        child: Padding(
                          padding: EdgeInsets.all(
                              MediaQuery.of(context).size.height / 40),
                          child: InkWell(
                            onTap: () async {
                              try {
                                currentUser = await googleSignIn.signIn();
                                String? idToken;
                                await currentUser!.authentication.then(
                                        (value) => {idToken = value.idToken});
                                final credential =
                                GoogleAuthProvider.credential(
                                  idToken: idToken,
                                );

                                await FirebaseAuth.instance.currentUser
                                    ?.unlink(
                                  credential.providerId,
                                )
                                    .then((value) => {
                                  if (mounted)
                                    {
                                      handleSignOut()
                                          .then((value) => {
                                        setState(() {
                                          isAuthorized =
                                          false;
                                        })
                                      }),
                                      ScaffoldMessenger.of(
                                          context)
                                          .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Unlinked")))
                                    }
                                });
                              } catch (error) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                      content: Text(
                                          "Failed to unlinked")));
                                }
                              }
                            },
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Unlink Google Account",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        color: Colors.red,
                                        fontSize: MediaQuery.of(context)
                                            .size
                                            .height /
                                            50)),
                                const Icon(
                                  Icons.link_off_sharp,
                                  color: Colors.green,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 8,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        )),
      ),
    );
  }

  Future<void> shareApp() async {
    const String androidAppLink =
        'https://play.google.com/store/apps/details?cat=-1&id=com.whatsapp&hl=en_AU';
    const String appleAppLink =
        'https://apps.apple.com/in/app/whatsapp-messenger/id310633997';
    if (Platform.isAndroid) {
      const String message =
          'Now You can also list your Facilities & get bookings and start earning: $androidAppLink';
      await FlutterShare.share(
        title: 'Sportistan Partner',
        text: message,
        linkUrl: androidAppLink,
      );
    }
    if (Platform.isIOS) {
      const String message =
          'Now You can also list your Facilities & get bookings and start earning:: $appleAppLink';
      await FlutterShare.share(
        title: 'Sportistan Partner',
        text: message,
        linkUrl: appleAppLink,
      );
    }
  }

  panel(ScrollController sc) {
    const focusedBorderColor = Colors.black;
    const fillColor = Colors.black87;
    const borderColor = Colors.black;

    final defaultPinTheme = PinTheme(
      width: MediaQuery.of(context).size.width / 10,
      height: MediaQuery.of(context).size.width / 10,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () {
                  pc.close();
                },
                icon: const CircleAvatar(child: Icon(Icons.close)))
          ],
        ),
        const Text("Change Number Request",
            style: TextStyle(fontSize: 15, fontFamily: "DMSans")),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (BuildContext context, value, Widget? child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width / 1.2,
              child: Form(
                key: numberKey,
                child: TextFormField(
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.telephoneNumberLocal],
                  decoration: InputDecoration(
                    suffixIcon: InkWell(
                        onTap: () {
                          otpController.clear();
                          loading.value = false;
                        },
                        child: const Icon(Icons.edit)),
                    fillColor: Colors.white,
                    border: InputBorder.none,
                    errorStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    prefixIcon: CountryCodePicker(
                      showCountryOnly: true,
                      onChanged: (value) {
                        countryCode = value.dialCode.toString();
                      },
                      favorite: const ["IN"],
                      initialSelection: "IN",
                    ),
                    hintText: "Phone Number",
                    hintStyle: const TextStyle(color: Colors.black45),
                  ),
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
                    padding:
                        EdgeInsets.all(MediaQuery.of(context).size.width / 25),
                    child: Pinput(
                      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                      controller: otpController,
                      androidSmsAutofillMethod:
                          AndroidSmsAutofillMethod.smsUserConsentApi,
                      listenForMultipleSmsOnAndroid: true,
                      defaultPinTheme: defaultPinTheme,
                      length: 6,
                      separatorBuilder: (index) => const SizedBox(width: 8),
                      hapticFeedbackType: HapticFeedbackType.lightImpact,
                      cursor: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            width: 22,
                            height: 1,
                            color: focusedBorderColor,
                          ),
                        ],
                      ),
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: focusedBorderColor),
                        ),
                      ),
                      submittedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: focusedBorderColor),
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyBorderWith(
                        border: Border.all(color: Colors.redAccent),
                      ),
                    ),
                  )
                : Container();
          },
        ),
        ValueListenableBuilder(
          builder: (BuildContext context, value, Widget? child) {
            return value
                ? Container()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CupertinoButton(
                      onPressed: () async {
                        if (numberKey.currentState!.validate()) {
                          try {
                            loading.value = true;
                            _verifyByNumber(
                                countryCode, numberController.value.text);
                          } on FirebaseAuthException catch (e) {
                            if (mounted) {
                              Errors.flushBarInform(
                                  e.message.toString(), context, "Sorry");
                            }
                          }
                        }
                      },
                      color: Colors.green,
                      child: const Text(
                        "Change Number",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  );
          },
          valueListenable: loading,
        ),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (context, value, child) {
            return value
                ? CupertinoButton(
                    color: Colors.green.shade700,
                    onPressed: () {
                      _manualVerify(otpController.value.text);
                    },
                    child: const Text("Submit OTP"),
                  )
                : Container();
          },
        ),
        ValueListenableBuilder(
          valueListenable: loading,
          builder: (context, value, child) {
            return value
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                : Container();
          },
        ),
      ]),
    );
  }

  Future<void> _manualVerify(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verification.toString(), smsCode: smsCode);
    try {
      loading.value = true;
      await _auth.currentUser!.updatePhoneNumber(credential).then((value) => {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Phone Number Updated Successfully")))
          });
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      if (mounted) {
        Errors.flushBarInform(e.message.toString(), context, "Sorry");
      }
    }
  }

  Future<void> _verifyByNumber(String countryCode, String number) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: countryCode + number,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          loading.value = true;
          await _auth.signInWithCredential(credential).then((value) => {});
        } on FirebaseAuthException catch (e) {
          loading.value = false;
          if (mounted) {
            Errors.flushBarInform(e.message.toString(), context, "Error");
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          loading.value = false;
          Errors.flushBarInform(
              'The provided phone number is not valid.', context, "Error");
        } else {
          loading.value = false;
          Errors.flushBarInform(e.message.toString(), context, "Error");
        }
      },
      codeSent: (String verificationId, int? resendToken) async {
        verification = verificationId;
      },
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  _callNumber() async {
    const number = '+918591719905'; //set the number here
    FlutterPhoneDirectCaller.callNumber(number);
  }

  linkGoogleAccountWithNumber() async {
    String? idToken;
    await currentUser!.authentication
        .then((value) => {idToken = value.idToken});
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    try {
      await FirebaseAuth.instance.currentUser
          ?.linkWithCredential(credential)
          .then((value) => {
                if (mounted)
                  {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Successfully Linked"),
                      backgroundColor: Colors.green,
                    )),
                    setState(() {
                      isAuthorized = true;
                    })
                  }
              });
    } on FirebaseAuthException catch (e) {
      handleSignOut();
      switch (e.code) {
        case "provider-already-linked":
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text("The provider has already been linked to the user.")));
          }
          break;
        case "invalid-credential":
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("The provider's credential is not valid.")));
          }
          break;
        case "credential-already-in-use":
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text("The user is already linked with another account.")));
          }
          break;
        case "email-already-in-use":
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Already linked with another account")));
          }
          break;
      }
    }
  }

  Future<void> check() async {
    GoogleSignInAccount? account = await googleSignIn.signInSilently();

    if (account != null) {
      if(mounted){

      setState(() {
        isAuthorized = true;
      });
    }
    }
  }
}
