import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sportistan_partners/authentication/slot_setting.dart';
import 'package:sportistan_partners/bookings/book_a_slot.dart';
import 'package:sportistan_partners/utils/errors.dart';

import '../payments/payment_mode.dart';

class BookEntireDay extends StatefulWidget {
  final String date;
  final String groundID;
  final String groundName;

  const BookEntireDay(
      {super.key,
      required this.date,
      required this.groundID,
      required this.groundName});

  @override
  State<BookEntireDay> createState() => _BookEntireDayState();
}

class _BookEntireDayState extends State<BookEntireDay> {
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List finalAvailabilityList = [];

  ValueNotifier<bool> listShow = ValueNotifier<bool>(false);
  ValueNotifier<bool> switchBuilder = ValueNotifier<bool>(false);

  int total = 0;

  int updatedPrice = 0;

  @override
  void initState() {
    getAllSlots();
    super.initState();
  }

  List daySlots = [];
  TextEditingController priceController = TextEditingController();
  GlobalKey<FormState> priceKey = GlobalKey<FormState>();
  TextEditingController teamControllerA = TextEditingController();
  TextEditingController teamControllerB = TextEditingController();
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
  TextEditingController notesTeamA = TextEditingController();
  TextEditingController notesTeamB = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: CupertinoButton(
            borderRadius: BorderRadius.zero,
            color: Colors.green,
            onPressed: () {
              addDataEntire();
            },
            child: const Text("Book for Entire Day")),
        appBar: AppBar(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text("Book for Entire Day")),
        body: SafeArea(
            child: ValueListenableBuilder(
          valueListenable: listShow,
          builder: (context, value, child) {
            return value
                ? dataList()
                : const Center(
                    child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ));
          },
        )));
  }

  dataList() {
    Map groupItemsByCategory(List items) {
      return groupBy(items, (item) => item.group);
    }

    Map groupedItems = groupItemsByCategory(finalAvailabilityList);

    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            itemCount: groupedItems.length,
            itemBuilder: (BuildContext context, int index) {
              String group = groupedItems.keys.elementAt(index);
              List bookingGroup = groupedItems[group]!;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8, left: 8),
                    child: Text(
                        "${DateFormat.yMMMd().format(DateTime.parse(widget.date))} (${DateFormat.EEEE().format(DateTime.parse(widget.date))})",
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height / 12,
                    alignment: Alignment.topCenter,
                    child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: bookingGroup.length,
                        itemBuilder: (context, index) {
                          MySlots bookings = bookingGroup[index];
                          return Padding(
                              padding: const EdgeInsets.only(left: 2, right: 2),
                              child: Column(
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.green, width: 2),
                                    ),
                                    onPressed: () {},
                                    child: Text(
                                      bookings.slotTime,
                                      style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              30),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Slot ${index + 1} :",
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontFamily: "DMSans"),
                                      ),
                                      Text(
                                        bookings.slotPrice.toString(),
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                38,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                            fontFamily: "DMSans"),
                                      ),
                                    ],
                                  ),
                                ],
                              ));
                        }),
                  ),
                ],
              );
            },
          ),
          Column(
            children: [
              ValueListenableBuilder(
                valueListenable: listShow,
                builder: (context, value, child) {
                  listShow.value = true;
                  return value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Card(
                                child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "Amount to pay for entire day \nRs.${total.toString()}",
                                  style: const TextStyle(
                                      fontSize: 22, fontFamily: "DMSans")),
                            )),
                          ],
                        )
                      : Container();
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: priceKey,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width / 2,
                    child: TextFormField(
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Amount Required.";
                        } else {
                          return null;
                        }
                      },
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          fillColor: Colors.white,
                          border: InputBorder.none,
                          suffixIcon: Icon(Icons.edit),
                          errorStyle: TextStyle(color: Colors.red),
                          labelText: "Amount*",
                          filled: true,
                          labelStyle: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Would you like to update amount for entire day?",
                    style: TextStyle(fontSize: 16, fontFamily: "DMSans")),
              ),
              MaterialButton(
                  elevation: 0,
                  color: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                  onPressed: () {
                    if (priceKey.currentState!.validate()) {
                      if (total == int.parse(priceController.value.text)) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Already Same Amount"),
                          backgroundColor: Colors.red,
                        ));
                      } else {
                        setState(() {
                          total = int.parse(priceController.value.text);
                        });
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Updated"),
                          backgroundColor: Colors.green,
                        ));
                      }
                    }
                  },
                  child: const Text(
                    "Update Amount",
                    style: TextStyle(color: Colors.white),
                  )),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 8,
          ),
          Image.asset(
            "assets/logo.png",
            width: MediaQuery.of(context).size.height / 8,
            height: MediaQuery.of(context).size.height / 8,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 8,
          ),
        ],
      ),
    );
  }

  late Map<String, dynamic> allData;

  Future<void> getAllSlots() async {
    var collection = _server.collection('SportistanPartners');
    var docSnapshot = await collection.doc(widget.groundID).get();

    allData = docSnapshot.data()!;

    daySlots = allData[DateFormat.EEEE().format(DateTime.parse(widget.date))];

    for (int j = 0; j < daySlots.length; j++) {
      if (daySlots.isNotEmpty) {
        int slotAmount =
            allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                ["price"];
        total = slotAmount + total;
        finalAvailabilityList.add(MySlots(
          slotID: allData[DateFormat.EEEE().format(DateTime.parse(widget.date))]
              [j]["slotID"],
          group: widget.date,
          date: widget.date,
          bookingID: UniqueID.generateRandomString(),
          slotStatus: 'Available',
          slotTime:
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["time"],
          slotPrice:
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["price"],
          feesDue:
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["price"],
        ));
      }
    }
    priceController.text = total.toString();
    listShow.value = true;
  }

  Future<void> createBooking() async {
    for (int j = 0; j < allData.length; j++) {
      try {
        await _server.collection("GroundBookings").add({
          'slotTime':
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["time"],
          'bookingPerson': 'Ground Owner',
          'groundName': widget.groundName,
          'bookingCreated': DateTime.parse(widget.date),
          'bookedAt': DateTime.now(),
          'userID': _auth.currentUser!.uid,
          'group': widget.date,
          'isBookingCancelled': false,
          'feesDue': 0,
          'ratingGiven': false,
          'rating': 3.0,
          'bothTeamBooked': true,
          'groundID': widget.groundID,
          "teamA": {
            'teamName': teamControllerA.value.text,
            'personName': nameControllerA.value.text,
            'phoneNumber': numberControllerA.value.text,
            "notesTeamA": notesTeamA.value.text.isNotEmpty
                ? notesTeamA.value.text.toString()
                : "",
          },
          "teamB": {
            'teamName': teamControllerB.value.text,
            'personName': nameControllerB.value.text,
            'phoneNumber': numberControllerB.value.text,
            "notesTeamB": notesTeamB.value.text.toString(),
          },
          'slotPrice':
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["price"],
          'advancePayment': total,
          'slotStatus': "Booked",
          'slotID':
              allData[DateFormat.EEEE().format(DateTime.parse(widget.date))][j]
                  ["slotID"],
          'bookingID': UniqueID.generateRandomString(),
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

  void addDataEntire() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (context, setState) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      color: Colors.grey.shade100,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Form(
                              key: teamControllerKeyA,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 1.2,
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
                                  decoration: const InputDecoration(
                                      fillColor: Colors.white,
                                      border: InputBorder.none,
                                      errorStyle: TextStyle(color: Colors.red),
                                      labelText: "Team A Name*",
                                      filled: true,
                                      labelStyle:
                                          TextStyle(color: Colors.black)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Form(
                              key: nameKeyA,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 1.2,
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
                                  decoration: const InputDecoration(
                                      fillColor: Colors.white,
                                      labelText: "Contact Person*",
                                      border: InputBorder.none,
                                      errorStyle: TextStyle(color: Colors.red),
                                      filled: true,
                                      labelStyle:
                                          TextStyle(color: Colors.black)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Form(
                              key: numberKeyA,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width / 1.2,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Number required.";
                                    } else if (value.length <= 9) {
                                      return "Enter 10 digits.";
                                    } else {
                                      return null;
                                    }
                                  },
                                  controller: numberControllerA,
                                  onChanged: (data) {
                                    numberKeyA.currentState!.validate();
                                  },
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  autofillHints: const [
                                    AutofillHints.telephoneNumberLocal
                                  ],
                                  decoration: const InputDecoration(
                                      fillColor: Colors.white,
                                      border: InputBorder.none,
                                      errorStyle: TextStyle(color: Colors.red),
                                      filled: true,
                                      labelText: "Contact Number*",
                                      labelStyle:
                                          TextStyle(color: Colors.black)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              child: TextFormField(
                                controller: notesTeamA,
                                decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  errorStyle: TextStyle(color: Colors.red),
                                  filled: true,
                                  hintText: "Notes (Optional)",
                                  hintStyle: TextStyle(color: Colors.black45),
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 40),
                                ),
                              ),
                            ),
                          ),
                          ListView(
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            addAutomaticKeepAlives: true,
                            children: <Widget>[
                              Content(
                                title: 'Choose Mode Of Payment',
                                child: ChipsChoice<String>.single(
                                  value: PaymentMode.type,
                                  onChanged: (val) =>
                                      setState(() => PaymentMode.type = val),
                                  choiceItems:
                                      C2Choice.listFrom<String, String>(
                                    source: PaymentMode.paymentOptions,
                                    value: (i, v) => v,
                                    label: (i, v) => v,
                                    tooltip: (i, v) => v,
                                  ),
                                  choiceCheckmark: true,
                                  choiceStyle: C2ChipStyle.filled(
                                    color: Colors.blue,
                                    selectedStyle: const C2ChipStyle(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(25),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ValueListenableBuilder(
                            valueListenable: switchBuilder,
                            builder: (context, value, child) {
                              return CupertinoSwitch(
                                  value: value,
                                  onChanged: (result) {
                                    if (nameKeyA.currentState!.validate() &
                                        numberKeyA.currentState!.validate() &
                                        teamControllerKeyA.currentState!
                                            .validate()) {
                                      switchBuilder.value = result;
                                      if (result) {
                                        teamControllerB.text =
                                            teamControllerA.value.text;
                                        nameControllerB.text =
                                            nameControllerA.value.text;
                                        numberControllerB.text =
                                            numberControllerA.value.text;

                                        setState;
                                      }
                                    }

                                  });
                            },
                          ),
                          const Text(
                            "Copy Same as Above",
                            style: TextStyle(fontFamily: "DMSans"),
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: teamControllerKeyB,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
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
                                        nameKeyB.currentState!.validate();
                                      },
                                      decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          labelText: "Team B Name*",
                                          filled: true,
                                          labelStyle:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: nameKeyB,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
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
                                        nameKeyB.currentState!.validate();
                                      },
                                      decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          labelText: "Contact Person*",
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          filled: true,
                                          labelStyle:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Form(
                                  key: numberKeyB,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.2,
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return "Number required.";
                                        } else if (value.length <= 9) {
                                          return "Enter 10 digits.";
                                        } else {
                                          return null;
                                        }
                                      },
                                      controller: numberControllerB,
                                      onChanged: (data) {
                                        numberKeyB.currentState!.validate();
                                      },
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      autofillHints: const [
                                        AutofillHints.telephoneNumberLocal
                                      ],
                                      decoration: const InputDecoration(
                                          fillColor: Colors.white,
                                          border: InputBorder.none,
                                          errorStyle:
                                              TextStyle(color: Colors.red),
                                          filled: true,
                                          labelText: "Contact Number*",
                                          labelStyle:
                                              TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  child: TextFormField(
                                    controller: notesTeamB,
                                    decoration: const InputDecoration(
                                      fillColor: Colors.white,
                                      border: InputBorder.none,
                                      errorStyle: TextStyle(color: Colors.red),
                                      filled: true,
                                      hintText: "Notes (Optional)",
                                      hintStyle:
                                          TextStyle(color: Colors.black45),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 40),
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  CupertinoButton(
                      color: Colors.indigo,
                      child: const Text("Set & Book"),
                      onPressed: () {
                        if (nameKeyA.currentState!.validate() &
                            numberKeyA.currentState!.validate() &
                            teamControllerKeyA.currentState!.validate() &
                            nameKeyB.currentState!.validate() &
                            numberKeyB.currentState!.validate() &
                            teamControllerKeyB.currentState!.validate()) {
                          showTask();
                          createBooking();
                        } else {
                          Errors.flushBarInform(
                              "Please Fill The Details", context, "Error");
                        }
                      })
                ],
              ),
            );
          });
        });
  }

  void showTask() {
    showDialog(
      context: context,
      builder: (context) {
        return const CupertinoAlertDialog(
          content: Column(
            children: [
              CircularProgressIndicator(strokeWidth: 1),
            ],
          ),
        );
      },
    );
  }
}

class MySlots {
  final String slotID;
  final String group;
  final String date;
  final int slotPrice;
  final int feesDue;
  final String slotStatus;
  final String slotTime;
  final String bookingID;

  MySlots(
      {required this.slotID,
      required this.group,
      required this.feesDue,
      required this.date,
      required this.bookingID,
      required this.slotPrice,
      required this.slotStatus,
      required this.slotTime});

  Map groupItemsByGroup(List items) {
    return groupBy(items, (item) => item.group);
  }
}
