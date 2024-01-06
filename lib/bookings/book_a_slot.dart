import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sportistan_partners/authentication/slot_setting.dart';
import 'package:sportistan_partners/nav_bar/booking_info.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';

class BookASlot extends StatefulWidget {
  final String group;
  final String slotID;
  final String bookingID;
  final String groundType;
  final String date;
  final String nonFormattedTime;
  final String groundID;
  final String groundName;
  final String groundAddress;
  final num slotPrice;

  final String slotTime;
  final String slotStatus;

  const BookASlot({
    super.key,
    required this.group,
    required this.date,
    required this.slotID,
    required this.bookingID,
    required this.slotTime,
    required this.slotStatus,
    required this.slotPrice,
    required this.groundName,
    required this.groundID,
    required this.groundAddress,
    required this.groundType,
    required this.nonFormattedTime,
  });

  @override
  State<BookASlot> createState() => _BookASlotState();
}

class _BookASlotState extends State<BookASlot> {
  late BuildContext buildContextWaiting;
  String countryCode = '+91';
  TextEditingController teamControllerA = TextEditingController();
  TextEditingController teamControllerB = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController nameControllerB = TextEditingController();
  TextEditingController nameControllerA = TextEditingController();
  TextEditingController numberControllerA = TextEditingController();
  TextEditingController numberControllerB = TextEditingController();
  GlobalKey<FormState> nameKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> nameKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> numberKeyB = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyA = GlobalKey<FormState>();
  GlobalKey<FormState> teamControllerKeyB = GlobalKey<FormState>();

  ValueNotifier<bool> checkBoxTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> showTeamB = ValueNotifier<bool>(false);
  ValueNotifier<bool> hideData = ValueNotifier<bool>(false);

  bool amountUpdated = false;

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  TextEditingController notesTeamA = TextEditingController();
  TextEditingController notesTeamB = TextEditingController();

  late num updatedPrice;

  bool updateSmsAlert = true;
  bool alreadyCommissionCharged = false;
  late num commissionCharged;

  int teamALevelTag = 1;
  int teamBLevelTag = 1;
  List<String> teamALevelTagOptions = [
    'Beginner',
    'Intermediate',
    'Advance',
    'Pro',
  ];
  List<String> teamBLevelTagOptions = [
    'Beginner',
    'Intermediate',
    'Advance',
    'Pro',
  ];

  PanelController pc = PanelController();


  late num calculateDeduction;
  late num newAmount;

  Future<void> serverInit() async {
    QuerySnapshot<Map<String, dynamic>> partner = await _server
        .collection('SportistanPartners')
        .where('groundID', isEqualTo: widget.groundID.toString())
        .get();
    num commission = partner.docChanges.first.doc.get("commission");
    double result = int.parse(priceController.value.text.trim()) / 100;
    double newCommissionCharge = result * commission.toInt();

    if (alreadyCommissionCharged) {
      serverCommissionCharge = newCommissionCharge - commissionCharged;
    } else {
      serverCommissionCharge = newCommissionCharge;
    }

    if (widget.bookingID.isNotEmpty) {
      await _server
          .collection("GroundBookings")
          .where("bookingID", isEqualTo: widget.bookingID)
          .get()
          .then((value) => {
                if (value.docs.isNotEmpty)
                  {
                    updatedPrice = value.docs[0]["feesDue"],
                    teamControllerA.text =
                        value.docs.first["teamA"]["teamName"],
                    teamControllerB.text =
                        value.docs.first["teamB"]["teamName"],
                    numberControllerA.text =
                        value.docs.first["teamA"]["phoneNumber"],
                    numberControllerB.text =
                        value.docs.first["teamB"]["phoneNumber"],
                    nameControllerA.text =
                        value.docs.first["teamA"]["personName"],
                    nameControllerB.text =
                        value.docs.first["teamB"]["personName"],
                    notesTeamA.text = value.docs.first["teamA"]["notesTeamA"],
                    notesTeamB.text = value.docs.first["teamB"]["notesTeamB"],
                    updatedPrice = value.docs.first["slotPrice"],
                    priceController.text =
                        value.docs.first["totalSlotPrice"].toString(),
                    checkBoxTeamB.value = true,
                    hideData.value = true,
                    showTeamB.value = true,
                    alreadyCommissionCharged = true,
                    commissionCharged =
                        value.docs.first["bookingCommissionCharged"],
                    teamALevelTag = value.docs.first["teamASkill"],
                    teamBLevelTag = value.docs.first["teamBSkill"],
                  },
              });
    } else {
      updatedPrice = widget.slotPrice;
      double newAmount = updatedPrice / 2.toInt().round();
      priceController.text = newAmount.round().toInt().toString();
    }

  }

  @override
  void dispose() {
    priceController.dispose();
    teamControllerA.dispose();
    teamControllerB.dispose();
    numberControllerA.dispose();
    numberControllerB.dispose();
    nameControllerA.dispose();
    nameControllerB.dispose();
    super.dispose();
  }

  @override
  void initState() {
    serverInit();
    super.initState();
  }

  PhoneContact? _phoneContact;

  checkPermissionForContacts(TextEditingController controller) async {
    final granted = await FlutterContactPicker.hasPermission();
    if (granted) {
      final PhoneContact contact =
          await FlutterContactPicker.pickPhoneContact();
      setState(() {
        _phoneContact = contact;
      });
      if (_phoneContact!.phoneNumber != null) {
        if (_phoneContact!.phoneNumber!.number!.length > 10) {
          controller.text = _phoneContact!.phoneNumber!.number!
              .substring(3)
              .split(" ")
              .join("");
        } else {
          controller.text =
              _phoneContact!.phoneNumber!.number!.split(" ").join("");
        }
      }
    } else {
      requestPermission(controller);
    }
  }

  requestPermission(controller) async {
    await FlutterContactPicker.requestPermission();
    checkPermissionForContacts(controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.groundName),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Card(
                      color: Colors.green.shade900,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Row(
                              children: [
                                const Text("Slot Time :",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(widget.slotTime,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text("Date :",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    DateFormat.yMMMd()
                                        .format(DateTime.parse(widget.group)),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: hideData,
                      builder: (context, value, child) {
                        return Column(children: [
                          SizedBox(
                              width: double.infinity,
                              child: Card(
                                  color: Colors.grey.shade100,
                                  child: Column(children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                        key: teamControllerKeyA,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
                                          child: TextFormField(
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return "Team name required.";
                                              } else if (value.length <= 2) {
                                                return "Enter Correct Name.";
                                              } else {
                                                return null;
                                              }
                                            },
                                            controller: teamControllerA,
                                            onChanged: (data) {
                                              nameKeyA.currentState!.validate();
                                            },
                                            enabled: !value,
                                            obscureText: value,
                                            decoration: const InputDecoration(
                                                fillColor: Colors.white,
                                                border: InputBorder.none,
                                                errorStyle: TextStyle(
                                                    color: Colors.red),
                                                labelText: "Team A Name*",
                                                filled: true,
                                                labelStyle: TextStyle(
                                                    color: Colors.black)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                        key: nameKeyA,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
                                          child: TextFormField(
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return "Name required.";
                                              } else if (value.length <= 2) {
                                                return "Enter Correct Name.";
                                              } else {
                                                return null;
                                              }
                                            },
                                            controller: nameControllerA,
                                            onChanged: (data) {
                                              nameKeyA.currentState!.validate();
                                            },
                                            keyboardType: TextInputType.name,
                                            enabled: !value,
                                            obscureText: value,
                                            decoration: const InputDecoration(
                                                fillColor: Colors.white,
                                                labelText: "Contact Person*",
                                                border: InputBorder.none,
                                                errorStyle: TextStyle(
                                                    color: Colors.red),
                                                filled: true,
                                                labelStyle: TextStyle(
                                                    color: Colors.black)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Form(
                                        key: numberKeyA,
                                        child: SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              1.2,
                                          child: TextFormField(
                                            maxLength: 10,
                                            validator: (value) {
                                              if (value!.isEmpty) {
                                                return "Number required.";
                                              } else if (value.length != 10) {
                                                return "Enter 10 digits.";
                                              } else {
                                                return null;
                                              }
                                            },
                                            enabled: !value,
                                            obscureText: value,
                                            controller: numberControllerA,
                                            onChanged: (data) {
                                              numberKeyA.currentState!
                                                  .validate();
                                            },
                                            keyboardType: TextInputType.phone,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                  RegExp('[0-9]')),
                                            ],
                                            autofillHints: const [
                                              AutofillHints.telephoneNumberLocal
                                            ],
                                            decoration: InputDecoration(
                                                fillColor: Colors.white,
                                                border: InputBorder.none,
                                                errorStyle: const TextStyle(
                                                    color: Colors.red),
                                                filled: true,
                                                prefixIcon: IconButton(
                                                    onPressed: () async {
                                                      checkPermissionForContacts(
                                                          numberControllerA);
                                                    },
                                                    icon: const Icon(Icons
                                                        .contacts_rounded)),
                                                suffixIcon: IconButton(
                                                    onPressed: () async {
                                                      if (numberControllerA
                                                          .value.text.isEmpty) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                                const SnackBar(
                                                                    content: Text(
                                                                        "No Number Available")));
                                                      } else {
                                                        FlutterPhoneDirectCaller
                                                            .callNumber(
                                                                numberControllerA
                                                                    .value
                                                                    .text);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.call,
                                                      color: Colors.blue,
                                                    )),
                                                labelText: "Contact Number*",
                                                labelStyle: const TextStyle(
                                                    color: Colors.black)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    ListView(
                                        shrinkWrap: true,
                                        addAutomaticKeepAlives: true,
                                        children: <Widget>[
                                          Content(
                                            title: 'Choose Skills',
                                            child: ChipsChoice<int>.single(
                                              value: teamALevelTag,
                                              onChanged: hideData.value
                                                  ? (v) => {}
                                                  : (val) => setState(() =>
                                                      teamALevelTag = val),
                                              choiceItems: C2Choice.listFrom<
                                                  int, String>(
                                                source: teamALevelTagOptions,
                                                value: (i, v) => i,
                                                label: (i, v) => v,
                                                tooltip: (i, v) => v,
                                              ),
                                              choiceCheckmark: true,
                                              choiceStyle: C2ChipStyle.filled(
                                                selectedStyle:
                                                    const C2ChipStyle(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(25),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                    Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          child: TextFormField(
                                            controller: notesTeamA,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white,
                                              border: InputBorder.none,
                                              errorStyle:
                                                  TextStyle(color: Colors.red),
                                              filled: true,
                                              hintText: "Notes (Optional)",
                                              hintStyle: TextStyle(
                                                  color: Colors.black45),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 40),
                                            ),
                                            enabled: !value,
                                            obscureText: value,
                                          ),
                                        ))
                                  ])))
                        ]);
                      },
                    ),
                    Column(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: showTeamB,
                          builder: (context, value, child) {
                            return value
                                ? Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Form(
                                          key: teamControllerKeyB,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.2,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Team name required.";
                                                } else if (value.length <= 2) {
                                                  return "Enter Correct Name.";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              controller: teamControllerB,
                                              onChanged: (data) {
                                                nameKeyB.currentState!
                                                    .validate();
                                              },
                                              decoration: const InputDecoration(
                                                  fillColor: Colors.white,
                                                  border: InputBorder.none,
                                                  errorStyle: TextStyle(
                                                      color: Colors.red),
                                                  labelText: "Team B Name*",
                                                  filled: true,
                                                  labelStyle: TextStyle(
                                                      color: Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Form(
                                          key: nameKeyB,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.2,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Name required.";
                                                } else if (value.length <= 2) {
                                                  return "Enter Correct Name.";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              controller: nameControllerB,
                                              onChanged: (data) {
                                                nameKeyB.currentState!
                                                    .validate();
                                              },
                                              decoration: const InputDecoration(
                                                  fillColor: Colors.white,
                                                  labelText: "Contact Person*",
                                                  border: InputBorder.none,
                                                  errorStyle: TextStyle(
                                                      color: Colors.red),
                                                  filled: true,
                                                  labelStyle: TextStyle(
                                                      color: Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Form(
                                          key: numberKeyB,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                1.2,
                                            child: TextFormField(
                                              validator: (value) {
                                                if (value!.isEmpty) {
                                                  return "Number required.";
                                                } else if (value.length != 10) {
                                                  return "Enter 10 digits.";
                                                } else {
                                                  return null;
                                                }
                                              },
                                              maxLength: 10,
                                              controller: numberControllerB,
                                              onChanged: (data) {
                                                numberKeyB.currentState!
                                                    .validate();
                                              },
                                              keyboardType: TextInputType.phone,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp('[0-9]')),
                                              ],
                                              autofillHints: const [
                                                AutofillHints
                                                    .telephoneNumberLocal
                                              ],
                                              decoration: InputDecoration(
                                                  fillColor: Colors.white,
                                                  border: InputBorder.none,
                                                  errorStyle: const TextStyle(
                                                      color: Colors.red),
                                                  filled: true,
                                                  prefixIcon: IconButton(
                                                      onPressed: () async {
                                                        checkPermissionForContacts(
                                                            numberControllerB);
                                                      },
                                                      icon: const Icon(Icons
                                                          .contacts_rounded)),
                                                  suffixIcon: IconButton(
                                                      onPressed: () async {
                                                        if (numberControllerB
                                                            .value
                                                            .text
                                                            .isEmpty) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                                  const SnackBar(
                                                                      content: Text(
                                                                          "No Number Available")));
                                                        } else {
                                                          FlutterPhoneDirectCaller
                                                              .callNumber(
                                                                  numberControllerB
                                                                      .value
                                                                      .text);
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.call,
                                                        color: Colors.blue,
                                                      )),
                                                  labelText: "Contact Number*",
                                                  labelStyle: const TextStyle(
                                                      color: Colors.black)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      ListView(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          addAutomaticKeepAlives: true,
                                          children: <Widget>[
                                            Content(
                                              title: 'Choose Skills',
                                              child: ChipsChoice<int>.single(
                                                value: teamBLevelTag,
                                                onChanged: (val) => setState(
                                                    () => teamBLevelTag = val),
                                                choiceItems: C2Choice.listFrom<
                                                    int, String>(
                                                  source: teamBLevelTagOptions,
                                                  value: (i, v) => i,
                                                  label: (i, v) => v,
                                                  tooltip: (i, v) => v,
                                                ),
                                                choiceCheckmark: true,
                                                choiceStyle: C2ChipStyle.filled(
                                                  selectedStyle:
                                                      const C2ChipStyle(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(25),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          child: TextFormField(
                                            controller: notesTeamB,
                                            decoration: const InputDecoration(
                                              fillColor: Colors.white,
                                              border: InputBorder.none,
                                              errorStyle:
                                                  TextStyle(color: Colors.red),
                                              filled: true,
                                              hintText: "Notes (Optional)",
                                              hintStyle: TextStyle(
                                                  color: Colors.black45),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      vertical: 40),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container();
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ValueListenableBuilder(
                              valueListenable: checkBoxTeamB,
                              builder: (context, value, child) => SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CupertinoSwitch(
                                            value: value,
                                            onChanged: widget
                                                    .bookingID.isNotEmpty
                                                ? null
                                                : (result) {
                                                    if (nameKeyA.currentState!
                                                            .validate() &
                                                        numberKeyA.currentState!
                                                            .validate() &
                                                        teamControllerKeyA
                                                            .currentState!
                                                            .validate()) {
                                                      checkBoxTeamB.value =
                                                          result;
                                                      teamControllerB.text =
                                                          teamControllerA
                                                              .value.text;
                                                      nameControllerB.text =
                                                          nameControllerA
                                                              .value.text;
                                                      numberControllerB.text =
                                                          numberControllerA
                                                              .value.text;
                                                      showTeamB.value = result;
                                                      if (result) {
                                                        setState(() {
                                                          num newAmount =
                                                              updatedPrice;
                                                          priceController.text =
                                                              newAmount
                                                                  .toString();
                                                        });
                                                      } else {
                                                        setState(() {
                                                          double newAmount =
                                                              updatedPrice /
                                                                  2
                                                                      .toInt()
                                                                      .round();
                                                          priceController.text =
                                                              newAmount
                                                                  .round()
                                                                  .toInt()
                                                                  .toString();
                                                        });
                                                      }
                                                    }
                                                  }),
                                        const Text(
                                          "Book for both Teams",
                                          style:
                                              TextStyle(fontFamily: "DMSans"),
                                        )
                                      ],
                                    ),
                                  )),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 4,
                    )
                  ],
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width / 8,
                right: MediaQuery.of(context).size.width / 8,
                bottom: MediaQuery.of(context).size.height / 6,
                child: CupertinoButton(
                    color: Colors.indigo,
                    onPressed: () {
                      if (nameKeyA.currentState!.validate() &
                          numberKeyA.currentState!.validate() &
                          teamControllerKeyA.currentState!.validate()) {
                        if (checkBoxTeamB.value) {
                          if (nameKeyB.currentState!.validate() &
                              numberKeyB.currentState!.validate() &
                              teamControllerKeyB.currentState!.validate()) {
                            createBooking();
                          } else {
                            Errors.flushBarInform("Field Required for Team B*",
                                context, "Enter field");
                          }
                        } else {
                          createBooking();
                        }
                      } else {
                        Errors.flushBarInform("Field Required for Team A*",
                            context, "Enter field");
                      }
                    },
                    child: const Text(
                      "Book Slot",
                      style: TextStyle(color: Colors.white),
                    )),
              ),
            ],
          ),
        ),
    );
  }



  Future<void> sendSms({required String number}) async {
    String url =
        'http://api.bulksmsgateway.in/sendmessage.php?user=sportslovez&password=7788330&mobile=$number&message=Your Booking is Confirmed for ${widget.groundName} on ${DateFormat.yMMMd().format(DateTime.parse(widget.group))} at ${widget.slotTime} Thanks for Choosing Facility on Sportistan&sender=SPTNOT&type=3&template_id=1407170003612415391';
    await http.post(Uri.parse(url));
  }

  Future<void> alertUser({required String bookingID}) async {
    if (updateSmsAlert) {
      if (numberControllerA.value.text.isNotEmpty) {
        await sendSms(number: numberControllerA.value.text);
        if (numberControllerB.value.text.isNotEmpty) {
          if (numberControllerA.value.text != numberControllerB.value.text) {
            await sendSms(number: numberControllerA.value.text);
          }
        }
      }
    }
    updateSmsAlert = false;
    moveToReceipt(bookingID: bookingID);
  }

  moveToReceipt({required String bookingID}) async {
    PageRouter.pushReplacement(context, BookingInfo(bookingID: bookingID));
  }

  late num serverCommissionCharge;

  createBooking() async {


    if (widget.bookingID.isEmpty) {
      String uniqueID = UniqueID.generateRandomString();
      try {
        await _server.collection("GroundBookings").add({
          'slotTime': widget.slotTime.toString(),
          'nonFormattedTime': widget.nonFormattedTime.toString(),
          'bookingPerson': 'Ground Owner',
          'groundName': widget.groundName,
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'groundType': widget.groundType,
          'shouldCountInBalance': false,
          'isBookingCancelled': false,
          'entireDayBooking': false,
          'userID': _auth.currentUser!.uid,
          'bookingCommissionCharged': serverCommissionCharge,
          'feesDue': calculateFeesDue(),
          'ratingGiven': false,
          'rating': 3.0,
          'ratingTags': [],
          'teamASkill': teamALevelTag.toInt(),
          'teamBSkill': showTeamB.value ? teamBLevelTag.toInt() : 1,
          'groundID': widget.groundID,
          'TeamA': alreadyCommissionCharged
              ? commissionCharged
              : serverCommissionCharge,
          'TeamB':
              checkBoxTeamB.value ? serverCommissionCharge : 'NotApplicable',
          "teamA": {
            'teamName': teamControllerA.value.text,
            'personName': nameControllerA.value.text,
            'phoneNumber': numberControllerA.value.text,
            "notesTeamA": notesTeamA.value.text.isNotEmpty
                ? notesTeamA.value.text.toString()
                : "",
          },
          "teamB": {
            'teamName': checkBoxTeamB.value ? teamControllerB.value.text : '',
            'personName': checkBoxTeamB.value ? nameControllerB.value.text : '',
            'phoneNumber':
                checkBoxTeamB.value ? numberControllerB.value.text : '',
            "notesTeamB": notesTeamB.value.text.isNotEmpty
                ? notesTeamB.value.text.toString()
                : "",
          },
          'slotPrice': checkBoxTeamB.value
              ? updatedPrice
              : updatedPrice / 2.toInt().round(),
          'totalSlotPrice': updatedPrice,
          'advancePayment': advancePaymentCalculate(),
          'slotStatus': slotStatus(),
          'bothTeamBooked': checkBoxTeamB.value,
          'slotID': widget.slotID,
          'bookingID': uniqueID,
          'date': widget.date,
        }).then((value) async => {
         await alertUser(bookingID: uniqueID)
            });
      } on SocketException catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Internet Connectivity");
        }
      } catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Error");
        }
      }
    } else {
      try {
        var refDetails = await _server
            .collection("GroundBookings")
            .where("bookingID", isEqualTo: widget.bookingID)
            .get();
        await _server
            .collection("GroundBookings")
            .doc(refDetails.docs.first.id)
            .update({
          'slotTime': widget.slotTime.toString(),
          'nonFormattedTime': widget.nonFormattedTime.toString(),
          'bookingPerson': 'Ground Owner',
          'groundName': widget.groundName,
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'groundType': widget.groundType,
          'shouldCountInBalance': false,
          'isBookingCancelled': false,
          'userID': _auth.currentUser!.uid,
          'bookingCommissionCharged': serverCommissionCharge,
          'feesDue': calculateFeesDue(),
          'ratingGiven': false,
          'entireDayBooking': false,
          'rating': 3.0,
          'ratingTags': [],
          'groundID': widget.groundID,
          'TeamA': alreadyCommissionCharged
              ? commissionCharged
              : serverCommissionCharge,
          'TeamB':
              checkBoxTeamB.value ? serverCommissionCharge : 'NotApplicable',
          'teamASkill': teamALevelTag.toInt(),
          'teamBSkill': showTeamB.value ? teamBLevelTag.toInt() : 1,
          "teamA": {
            'teamName': teamControllerA.value.text,
            'personName': nameControllerA.value.text,
            'phoneNumber': numberControllerA.value.text,
            "notesTeamA": notesTeamA.value.text.isNotEmpty
                ? notesTeamA.value.text.toString()
                : "",
          },
          "teamB": {
            'teamName': checkBoxTeamB.value ? teamControllerB.value.text : '',
            'personName': checkBoxTeamB.value ? nameControllerB.value.text : '',
            'phoneNumber':
                checkBoxTeamB.value ? numberControllerB.value.text : '',
            "notesTeamB": notesTeamB.value.text.isNotEmpty
                ? notesTeamB.value.text.toString()
                : "",
          },
          'slotPrice': checkBoxTeamB.value
              ? updatedPrice
              : updatedPrice / 2.toInt().round(),
          'totalSlotPrice': updatedPrice,
          'advancePayment': advancePaymentCalculate(),
          'slotStatus': slotStatus(),
          'bothTeamBooked': checkBoxTeamB.value,
          'slotID': widget.slotID,
          'bookingID': widget.bookingID,
          'date': widget.date,
        });
      } on SocketException catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Internet Connectivity");
        }
      } catch (e) {
        if (mounted) {
          Errors.flushBarInform(e.toString(), context, "Error");
        }
      }
    }
  }


  String slotStatus() {
    if (checkBoxTeamB.value) {
      return 'Booked';
    } else {
      return 'Half Booked';
    }
  }

  num advancePaymentCalculate() {
    if (alreadyCommissionCharged) {
      return commissionCharged + serverCommissionCharge;
    } else {
      return updatedPrice / 2.toInt().round() - serverCommissionCharge;
    }
  }

  num calculateFeesDue() {
    if (checkBoxTeamB.value) {
      return updatedPrice - serverCommissionCharge;
    }
    return updatedPrice / 2 - serverCommissionCharge;
  }

}

class Content extends StatefulWidget {
  final String title;
  final Widget child;

  const Content({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  ContentState createState() => ContentState();
}

class ContentState extends State<Content> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: "DMSans",
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Flexible(fit: FlexFit.loose, child: widget.child),
      ],
    );
  }
}
