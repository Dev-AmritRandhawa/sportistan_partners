import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import 'package:sportistan_partners/utils/errors.dart';

class SportistanCredit extends StatefulWidget {
  const SportistanCredit({super.key});

  @override
  State<SportistanCredit> createState() => _SportistanCreditState();
}

class _SportistanCreditState extends State<SportistanCredit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  String? result;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    _futureGroundTypes();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> groundID = [];
  int groundIndex = 0;
  List<String> dropDownList = [];
  String? dropDownValue;

  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  ValueNotifier<bool> switchGrounds = ValueNotifier<bool>(true);
  ValueNotifier<bool> showError = ValueNotifier<bool>(false);

  late num balance;

  Future<void> _futureGroundTypes() async {
    dropDownList.clear();
    groundID.clear();

    _server
        .collection("SportistanPartners")
        .where("userID", isEqualTo: _auth.currentUser!.uid)
        .get()
        .then((value) => {
              if (value.docChanges.isNotEmpty)
                {
                  for (int i = 0; i < value.size; i++)
                    {
                      dropDownList.add(value.docs[i]["groundName"]),
                      groundID.add(value.docs[i]["groundID"]),
                    },
                  dropDownValue = dropDownList[0],
                  getBalance()
                }
              else
                {
                  Errors.flushBarInform("Ground not found or may deleted",
                      context, "No Ground Found")
                },
            });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(children: [
        SafeArea(
          child: ValueListenableBuilder(
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
                    color: Colors.teal.shade400,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton(
                          elevation: 0,
                          underline: Container(),
                          value: dropDownValue,
                          dropdownColor: Colors.black,
                          style: TextStyle(
                            fontFamily: "DMSans",
                            fontSize: MediaQuery.of(context).size.height / 50,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          items: dropDownList.map((String items) {
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
        ),
        ValueListenableBuilder(
            valueListenable: switchGrounds,
            builder: (context, value, child) => value
                ? Container()
                : DelayedDisplay(
                    child: Center(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              overflow: TextOverflow.fade,
                              "Your Balance in ${dropDownList[groundIndex]}",
                              style: const TextStyle(
                                  fontFamily: "DMSans", fontSize: 20),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Rs.",
                                style: TextStyle(
                                    fontFamily: "DMSans", fontSize: 25),
                              ),
                              Text(
                                balance.toString(),
                                style: const TextStyle(
                                    fontFamily: "DMSans", fontSize: 100),
                              ),
                            ],
                          ),
                          CupertinoButton(
                              color: Colors.green,
                              onPressed: () {
                                showModalBottomSheet(enableDrag: true,

                                  context: context,
                                  builder: (context) {
                                    return  SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: Column(
                                            children: [
                                              const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text("Select Payment Method",
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: "DMSans")),
                                              ),
                                              customPaymentCardButton(
                                                  assetName: 'assets/upi.png', index: 0),
                                              customPaymentCardButton(
                                                  assetName: 'assets/logo-paytm.png',
                                                  index: 1),
                                              customPaymentCardButton(
                                                  assetName: 'assets/visa.png', index: 2),
                                              customPaymentCardButton(
                                                  assetName: 'assets/mastercard.png',
                                                  index: 3),
                                              SizedBox(height: MediaQuery.of(context).size.height/5,)
                                            ],
                                          ),

                                    );
                                  },
                                );
                              },
                              child: const Text("Add Credits")),
                        ],
                      ),
                    ),
                  )),

        Lottie.asset(
          'assets/wallet.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
        ),
        const Text(
          "Payment Gateway is Safe & Secure",
          style: TextStyle(fontFamily: "DMSans", color: Colors.black54),
        )
      ]),
    );
  }

  Future<void> getBalance() async {
    await _server
        .collection("SportistanPartners")
        .where("groundID", isEqualTo: groundID[groundIndex])
        .get()
        .then((value) => {
              if (value.docChanges.isNotEmpty)
                {
                  balance = value.docChanges.first.doc.get('sportistanCredit'),
                  switchGrounds.value = false,
                }
              else
                {showError.value = true}
            });
  }

  Widget customPaymentCardButton(
      {required String assetName, required int index}) {
    return OutlinedButton(
      onPressed: () {
        goPaymentMode(index);
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      ),
      child: Image.asset(
        assetName,
        height: 80,
        width: double.infinity,
      ),
    );
  }

  List<String> pMode = ['UPI', 'Wallet', 'Visa', 'MasterCard'];

  void goPaymentMode(int index) {
    switch (index) {
      case 0:
        {
          paytmIntegratedCall(0);
        }
      case 1:
        {
          paytmIntegratedCall(1);
        }
      case 2:
        {
          paytmIntegratedCall(2);
        }
      case 3:
        {
          paytmIntegratedCall(3);
        }
    }
  }

  Future<void> paytmIntegratedCall(index) async {
    var bytes = utf8.encode(jsonEncode({"body": {"mid": "SPORTS33075460479694", "orderId": "SPORTS3307"}})); // data being hashed

    var digest = sha256.convert(bytes);

    print("Digest as hex string: $digest");
    const String url = 'https://securegw-stage.paytm.in/v3/order/status';
    final String body = jsonEncode({
      "body": {"mid": "SPORTS33075460479694", "orderId": "SPORTS3307"},
      "head": {"signature": "$digest"}
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      // Successful POST request
      print('Response: ${response.body}');
    } else {
      // Handle the error
      print('Error: ${response.statusCode}');
    }
  }

  startTransaction({
    required String mid,
    required String orderId,
    required String amount,
    required String txnToken,
    required String callbackurl,
    required bool isStaging,
    required bool restrictAppInvoke,
  }) {
    var response = AllInOneSdk.startTransaction(mid, orderId, amount, txnToken,
        callbackurl, isStaging, restrictAppInvoke);
    response.then((value) {
      print(value);
      setState(() {
        result = value.toString();
      });
    }).catchError((onError) {
      if (onError is PlatformException) {
        result = "${onError.message} \n  ${onError.details}";
        print(result);
      } else {
        result = onError.toString();
        print(result);
      }
    });
  }
}
