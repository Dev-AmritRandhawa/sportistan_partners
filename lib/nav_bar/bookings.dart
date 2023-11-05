import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sportistan_partners/nav_bar/booking_info.dart';
import 'package:sportistan_partners/utils/page_router.dart';

class Bookings extends StatefulWidget {
  const Bookings({super.key});

  @override
  State<Bookings> createState() => _BookingsState();
}

class _BookingsState extends State<Bookings> {
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  DateTime dateTime = DateTime.now();
  int groundIndex = 0;
  List<String> dropDownList = [];
  String dropDownValue = "";
  List<String> groundID = [];
  List<String> groundAddress = [];
  ValueNotifier<bool> switchGrounds = ValueNotifier<bool>(true);
  ValueNotifier<bool> myBookings = ValueNotifier<bool>(false);

  Future<void> _futureGroundTypes() async {
    try {
      await _server
          .collection("SportistanPartners")
          .where("userID", isEqualTo: _auth.currentUser!.uid)
          .get()
          .then((value) => {
                for (int i = 0; i < value.size; i++)
                  {
                    dropDownList.add(value.docs[i]["groundName"]),
                    groundID.add(value.docs[i]["groundID"]),
                    groundAddress.add(
                      value.docs[i]["locationName"],
                    ),
                  },
                dropDownValue = dropDownList[groundIndex],
              })
          .then((value) =>
              {switchGrounds.value = false, myBookings.value = true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("No Ground Found")));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    _futureGroundTypes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.teal.shade400,
        body: SlidingUpPanel(
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30), topLeft: Radius.circular(30)),
          minHeight: MediaQuery.of(context).size.height / 1.5,
          maxHeight: MediaQuery.of(context).size.height / 1.5,
          panelBuilder: (sc) => panel(sc),
          body: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.calendar_today, color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Bookings",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: "DMSans",
                            fontSize: MediaQuery.of(context).size.height / 25,
                          ) //TextStyle
                          ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: switchGrounds,
                  builder: (context, value, child) => value
                      ? const Card(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(7.0),
                                child: CircularProgressIndicator(
                                  color: Colors.black45,
                                  strokeWidth: 1,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          shadowColor: Colors.green,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DropdownButton(
                                elevation: 0,
                                underline: Container(),
                                value: dropDownValue,
                                dropdownColor: Colors.white,
                                style: TextStyle(
                                  fontFamily: "DMSans",
                                  fontSize:
                                      MediaQuery.of(context).size.height / 50,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                items: dropDownList.map((String items) {
                                  groundIndex =
                                      dropDownList.indexOf(dropDownValue);
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (dropDownValue != newValue) {
                                    dropDownValue = newValue!;
                                    switchGrounds.value = true;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ));
  }

  Color setStatusColor(String result) {
    switch (result) {
      case "Booked":
        {
          return Colors.green;
        }
      case "Half Booked":
        {
          return Colors.orangeAccent;
        }
      case "Fees Due":
        {
          return Colors.red.shade200;
        }
    }
    return Colors.white;
  }

  panel(ScrollController sc) {
    return ValueListenableBuilder(
      valueListenable: myBookings,
      builder: (context, value, child) {
        return value
            ? StreamBuilder<QuerySnapshot>(
                stream: _server
                    .collection("GroundBookings")
                    .where("bookingCreated",
                        isGreaterThanOrEqualTo: DateTime(
                            dateTime.year, dateTime.month, dateTime.day))
                    .where("groundID", isEqualTo: groundID[groundIndex]).where('userID', isEqualTo: _auth.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  return snapshot.hasData
                      ? ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = snapshot.data!.docs[index];

                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: doc["isBookingCancelled"]
                                    ? null
                                    : () {
                                        PageRouter.push(
                                            context,
                                            BookingInfo(
                                              bookingID: doc["bookingID"],
                                            ));
                                      },
                                child: Card(
                                  color: Colors.grey.shade50,
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Booked by",
                                        style: TextStyle(
                                            fontFamily: "DMSans",
                                            color: Colors.black45),
                                      ),
                                      Text(
                                        doc["bookingPerson"],
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black87,
                                            fontFamily: "DMSans",
                                            fontWeight: FontWeight.bold),
                                      ),
                                      doc["isBookingCancelled"]
                                          ? const Text(
                                              "Cancelled",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.red,
                                                  fontFamily: "DMSans",
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : Container(),
                                      ListTile(
                                        title: Text(doc["slotTime"],
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        subtitle: Text(DateFormat.yMEd().format(
                                            DateTime.parse(doc["group"]))),
                                        trailing:
                                            const Icon(Icons.arrow_forward_ios),
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              setStatusColor(doc["slotStatus"]),
                                          child: const Icon(
                                              Icons.calendar_today,
                                              color: Colors.white),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(doc["slotStatus"],
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: "DMSans")),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: doc["feesDue"] == 0
                                                ? const Text(
                                                    "Paid",
                                                    style: TextStyle(
                                                        color: Colors.green),
                                                  )
                                                : Row(
                                                    children: [
                                                      Text(
                                                        "Due Amount : Rs.",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .red.shade200,
                                                        ),
                                                      ),
                                                      Text(
                                                          doc["feesDue"]
                                                              .toString(),
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .red.shade200,
                                                              fontSize: 15,
                                                              fontFamily:
                                                                  "DMSans")),
                                                    ],
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          })
                      : const Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                           Center(child: Text("No Bookings Found",style: TextStyle(fontFamily: "DMSans")),)
                          ],
                        );
                })
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                      child: CircularProgressIndicator(
                    strokeWidth: 1,
                  )),
                ],
              );
      },
    );
  }
}
