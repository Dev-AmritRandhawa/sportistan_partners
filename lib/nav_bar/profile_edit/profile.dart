import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';
import 'package:share/share.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sportistan_partners/authentication/location_permission.dart';
import 'package:sportistan_partners/authentication/phone_authentication.dart';
import 'package:sportistan_partners/authentication/search_field.dart';
import 'package:sportistan_partners/main.dart';
import 'package:sportistan_partners/nav_bar/profile_edit/crop.dart';
import 'package:sportistan_partners/nav_bar/profile_edit/edit_ground.dart';
import 'package:sportistan_partners/nav_bar/profile_edit/sportistan_credit.dart';
import 'package:sportistan_partners/nav_bar/profile_edit/verified_grounds.dart';
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
  final finalOTPController = TextEditingController();
  GlobalKey<FormState> numberKey = GlobalKey<FormState>();
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  ValueNotifier<bool> buttonDisable = ValueNotifier<bool>(false);
  ValueNotifier<bool> imageListener = ValueNotifier<bool>(false);

  String countryCode = "+91";
  String? verification;
  String? finalVerification;
  PanelController pc = PanelController();
  ScrollController sc = ScrollController();

  GoogleSignInAccount? currentUser;
  bool isAuthorized = true;
  String profileLink = '';
  GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId:
          '497512590176-k2357th2q9rkmq4484uhmu4lqvmivi50.apps.googleusercontent.com');
  late String urls;

  final _server = FirebaseFirestore.instance;

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
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          "Welcome",
                          style: TextStyle(fontFamily: 'DMSans', fontSize: 22),
                        ),
                        Text(
                          _auth.currentUser!.phoneNumber != null
                              ? _auth.currentUser!.phoneNumber.toString()
                              : _auth.currentUser!.email.toString(),
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: MediaQuery.of(context).size.height / 40,
                              fontWeight: FontWeight.bold,
                              fontFamily: "DMSans"),
                        ),
                        ValueListenableBuilder(
                          valueListenable: imageListener,
                          builder: (context, value, child) {
                            return value
                                ? profileLink.isNotEmpty
                                    ? Image.network(profileLink)
                                    : Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              PageRouter.push(context,
                                                      const CropImageTool())
                                                  .then((value) => {check()});
                                            },
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Colors.orange.shade200,
                                              maxRadius: 50,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Image.asset(
                                                    'assets/logo.png'),
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.camera_alt_rounded,
                                          )
                                        ],
                                      )
                                : const CircularProgressIndicator(
                                    strokeWidth: 1,
                                  );
                          },
                        )
                      ],
                    )),
                DelayedDisplay(
                  child: Column(
                    children: [
                      isAuthorized
                          ? CupertinoButton(
                              borderRadius: BorderRadius.zero,
                              color: Colors.black87,
                              onPressed: () {
                                _handleSignIn();
                              },
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                              ))
                          : Card(
                              color: Colors.green,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                    "Connected (${_auth.currentUser!.email})",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontFamily: "DMSans")),
                              )),
                      isAuthorized
                          ? Container()
                          : const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Connect with Google Account helps you to login faster",
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontFamily: "DMSans"),
                              ),
                            ),
                      InkWell(
                        onTap: () {
                          PageRouter.push(context, const SportistanCredit());
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Add Sportistan Credit",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.credit_score_sharp,
                                  color: Colors.teal,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
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
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
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
                      InkWell(
                        onTap: () {
                          PageRouter.push(context, const EditGround());
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(" Edit Grounds",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.photo,
                                  color: Colors.orangeAccent,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          PageRouter.push(context, const VerifiedGrounds());
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(" My Grounds",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (ctx) => Platform.isIOS
                                  ? CupertinoAlertDialog(
                                      title: const Text("Want to talk?"),
                                      content: const Text(
                                          "We will connect to you to a person who will assist you",
                                          style:
                                              TextStyle(fontFamily: "DMSans")),
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
                                              style:
                                                  TextStyle(color: Colors.red),
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
                                              style:
                                                  TextStyle(color: Colors.red),
                                            )),
                                      ],
                                    ));
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
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
                      InkWell(
                        onTap: () {
                          pc.open();
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
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
                      InkWell(
                        onTap: () {
                          shareApp();
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
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
                                  color: Colors.indigo,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => Platform.isAndroid
                                ? AlertDialog(
                                    title: const Text("Delete Ground?"),
                                    content: const Text(
                                        "Would you like to delete Account?",
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontFamily: "DMSans")),
                                    icon: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    actions: [
                                      TextButton(
                                          onPressed: () async {
                                            Navigator.pop(ctx);
                                            finalOTPController.clear();
                                            showPopupToVerifyDeletion();
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          )),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))
                                    ],
                                  )
                                : CupertinoAlertDialog(
                                    title: const Text("Delete Ground?"),
                                    content: const Text(
                                        "Would you like to delete ground from listing?",
                                        style: TextStyle(fontFamily: "DMSans")),
                                    actions: [
                                      TextButton(
                                          onPressed: () {},
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          )),
                                      TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text(
                                            "Cancel",
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ))
                                    ],
                                  ),
                          );
                        },
                        child: Card(
                          color: Colors.red,
                          child: Padding(
                            padding: EdgeInsets.all(
                                MediaQuery.of(context).size.height / 50),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Delete Account",
                                    style: TextStyle(
                                        fontFamily: "DMSans",
                                        color: Colors.white,
                                        fontSize:
                                            MediaQuery.of(context).size.height /
                                                50)),
                                const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                                                      (value) =>
                                                                          {
                                                                            Navigator.pop(ctx),
                                                                            PageRouter.pushRemoveUntil(context,
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
                                                                      (value) =>
                                                                          {
                                                                            Navigator.pop(ctx),
                                                                            PageRouter.pushRemoveUntil(context,
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
                      isAuthorized
                          ? Container()
                          : Card(
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
                                                                    true;
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
      await Share.share(androidAppLink, subject: message);
    }
    if (Platform.isIOS) {
      const String message =
          'Now You can also list your Facilities & get bookings and start earning:: $appleAppLink';
      await Share.share(appleAppLink, subject: message);
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

  void _showError(String error) {
    Errors.flushBarAuth(error, context);
  }

  Future<void> _verifyNumberForDelete({required String number}) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: number,
      verificationCompleted: (PhoneAuthCredential credential) async {},
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
        finalVerification = verificationId;
      },
      timeout: const Duration(seconds: 60),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> _manualVerifyNumberForDelete(String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: finalVerification.toString(), smsCode: smsCode);
    try {
      buttonDisable.value = true;
      await _auth
          .signInWithCredential(credential)
          .then((value) => {deleteKYC()});
    } on FirebaseAuthException catch (e) {
      buttonDisable.value = false;

      _showError(e.message.toString());
    }
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
                      isAuthorized = false;
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
    try {
      GoogleSignInAccount? account = await googleSignIn.signInSilently();
      if (account != null) {
        if (mounted) {
          setState(() {
            isAuthorized = false;
          });
        }
      }
      await _server
          .collection("profileImages")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                profileLink = value.docs.last.get("profileImageLink"),
                imageListener.value = true
              });
    } catch (e) {
      if (mounted) {
        profileLink = '';
        imageListener.value = true;
      }
    }
  }

  Future<void> deleteKYC() async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child("${_auth.currentUser!.uid}/kyc/")
          .listAll()
          .then((value) => {
                for (int i = 0; i < value.items.length; i++)
                  {
                    FirebaseStorage.instance
                        .ref(value.items[i].fullPath.toString())
                        .delete()
                  },
                deleteGroundImages()
              });
    } catch (e) {
      deleteGroundImages();
    }
  }

  deleteGroundImages() async {
    try {
      await FirebaseStorage.instance
          .ref()
          .child("${_auth.currentUser!.uid}/groundImages/")
          .listAll()
          .then((value) => {
                for (int i = 0; i < value.items.length; i++)
                  {
                    FirebaseStorage.instance
                        .ref(value.items[i].fullPath.toString())
                        .delete()
                  },
                deleteDeviceTokens()
              });
    } catch (e) {
      deleteDeviceTokens();
    }
  }

  deleteDeviceTokens() async {
    try {
      await FirebaseFirestore.instance
          .collection("SportistanPartners")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                for (int i = 0; i < value.size; i++)
                  {
                    FirebaseFirestore.instance
                        .collection("SportistanPartners")
                        .doc(value.docChanges[i].doc.id)
                        .delete()
                  },
                deleteUser()
              });
    } catch (e) {
      deleteUser();
    }
  }

  deleteUser() async {
    try {
      await FirebaseFirestore.instance
          .collection("DeviceTokens")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                for (int i = 0; i < value.size; i++)
                  {
                    FirebaseFirestore.instance
                        .collection("DeviceTokens")
                        .doc(value.docChanges[i].doc.id)
                        .delete()
                  },
                deleteUserAccount()
              });
    } catch (e) {
      deleteUserAccount();
    }
  }

  Future<void> deleteUserAccount() async {
    await _auth.signOut().then((value) =>
        {PageRouter.pushRemoveUntil(context, const PhoneAuthentication())});
  }

  Future<void> showPopupToVerifyDeletion() async {
    _verifyNumberForDelete(number: _auth.currentUser!.phoneNumber.toString());
    showModalBottomSheet(
      context: context,
      builder: (context) {
        const focusedBorderColor = Color.fromRGBO(23, 171, 144, 1);
        const fillColor = Color.fromRGBO(243, 246, 249, 0);
        const borderColor = Color.fromRGBO(23, 171, 144, 0.4);

        final defaultPinTheme = PinTheme(
          width: 56,
          height: 56,
          textStyle: const TextStyle(
            fontSize: 22,
            color: Color.fromRGBO(30, 60, 87, 1),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: borderColor),
          ),
        );

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Verify OTP to Delete Account",
                  style: TextStyle(fontSize: 16)),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Pinput(
                controller: finalOTPController,
                listenForMultipleSmsOnAndroid: true,
                defaultPinTheme: defaultPinTheme,
                separatorBuilder: (index) => const SizedBox(width: 8),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                onCompleted: (pin) {
                  debugPrint('onCompleted: $pin');
                },
                length: 6,
                onChanged: (value) {
                  debugPrint('onChanged: $value');
                },
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
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoButton(
                color: Colors.red,
                onPressed: () {
                  _manualVerifyNumberForDelete(finalOTPController.value.text);
                },
                child: const Text('Delete Account'),
              ),
            ),
            Flexible(child: Image.asset("assets/deleteAccount.png"))
          ],
        );
      },
    );
  }
}
