import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:intl/intl.dart';
import 'package:sportistan_partners/authentication/slot_setting.dart';
import 'package:sportistan_partners/nav_bar/nav_home.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';
import 'package:sportistan_partners/utils/register_data_class.dart';

class SlotAddSettings extends StatefulWidget {
  final String day;

  const SlotAddSettings({
    super.key,
    required this.day,
  });

  @override
  SlotAddSettingsState createState() => SlotAddSettingsState();
}

class SlotAddSettingsState extends State<SlotAddSettings> {
  var nameTECs = <int, TextEditingController>{};
  var nameTECs2 = <int, TextEditingController>{};
  var mailTECs = <int, TextEditingController>{};

  var item = <int, Widget>{};
  final _server = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  ValueNotifier<bool> listLoad = ValueNotifier<bool>(true);

  int onwardsAmount = 0;

  final _storage = FirebaseStorage.instance;




  @override
  void initState() {
getSlots();
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
  }

  ondDone() async {
    DataSave.entries.clear();
    for (int i = 0; i <= nameTECs.keys.last; i++) {
      var name = nameTECs[i]?.value.text;
      var name2 = nameTECs2[i]?.value.text;
      var mail = mailTECs[i]?.value.text;
      if (name != null && mail != null && name2 != null) {
        DataSave.entries.add(Entry(
            name: name.toString(),
            name2: name2.toString(),
            email: mail.toString()));
        onwardsAmount = int.parse(mailTECs[i]!.value.text);
        if(int.parse(mailTECs[i]!.value.text) > onwardsAmount){
          onwardsAmount = int.parse(mailTECs[i]!.value.text);
        }
      }
    }
    await setSlot();
  }

  newMethod(
    BuildContext context,
    int index,
  ) {
    var nameController = TextEditingController();
    var nameController2 = TextEditingController();
    var mailController = TextEditingController();
    nameTECs.addAll({index: nameController});
    nameTECs2.addAll({index: nameController2});
    mailTECs.addAll({index: mailController});
    return Card(
      elevation: 5.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text("SLOT : ${index + 1}",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontFamily: "DMSans")),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: TextFormField(
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay? tod = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (tod != null) {
                        nameController.text = formatTimeOfDay(tod);
                      }
                    },
                    controller: nameController,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Set Slot Time";
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.access_time_outlined, color: Colors.green),
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      filled: true,
                      hintText: "Start Time",
                      hintStyle:
                          TextStyle(color: Colors.black, fontFamily: "DMSans"),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2.5,
                  child: TextFormField(
                    readOnly: true,
                    onTap: () async {
                      TimeOfDay? tod = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            DateTime.now().add(const Duration(hours: 2))),
                      );
                      if (tod != null) {
                        nameController2.text = formatTimeOfDay(tod);
                      }
                    },
                    controller: nameController2,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Set Slot Time";
                      } else {
                        return null;
                      }
                    },
                    decoration: const InputDecoration(
                      prefixIcon:
                          Icon(Icons.access_time_outlined, color: Colors.amber),
                      fillColor: Colors.white,
                      border: InputBorder.none,
                      filled: true,
                      hintText: "End Time",
                      hintStyle:
                          TextStyle(color: Colors.black, fontFamily: "DMSans"),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
                controller: mailController,
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Set Slot Price";
                  } else if (int.parse(value) < 99) {
                    return "Invalid Slot Price";
                  } else {
                    return null;
                  }
                },
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.green),
                  suffixIcon: Text("Change",
                      style: TextStyle(
                          color: Colors.black54, fontFamily: "DMSans")),
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  filled: true,
                  hintText: "Set Slot Price",
                  hintStyle:
                      TextStyle(color: Colors.black, fontFamily: "DMSans"),
                )),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0, left: 8.0),
            child: Divider(
              color: Colors.black38,
              height: 1,
            ),
          ),
          MaterialButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
            color: Colors.red,
            onPressed: () {
              setState(() {
                item.removeWhere((key, value) => key == index);
                nameTECs.removeWhere((key, value) => key == index);
                nameTECs2.removeWhere((key, value) => key == index);
                mailTECs.removeWhere((key, value) => key == index);
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.white,
            centerTitle: true,
            title: Text(
              widget.day,
              style:
                  const TextStyle(fontFamily: "DMSans", color: Colors.black54),
            )),
        bottomNavigationBar: item.isNotEmpty
            ? CupertinoButton(
                borderRadius: const BorderRadius.all(Radius.zero),
                color: Colors.green.shade800,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ondDone();

                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.save),
                    Text("Save Slots for ${widget.day}"),
                  ],
                ),
              )
            : CupertinoButton(
                borderRadius: const BorderRadius.all(Radius.zero),
                color: Colors.indigo,
                onPressed: () {
                  setState(() {
                    item.addAll({0: newMethod(context, 0)});
                  });
                },
                child: const Text("Add Slot",
                    style: TextStyle(fontFamily: "DMSans")),
              ),
        body: ValueListenableBuilder(
          valueListenable: listLoad,
          builder: (context, value, child) {
            return listLoad.value
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 1, color: Colors.green),
                  )
                : SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          ListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: item.length,
                              itemBuilder: (context, index) {
                                return item.values.elementAt(index);
                              }),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: MaterialButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  color: Colors.green,
                                  elevation: 0,
                                  onPressed: () {
                                    setState(() {
                                      if (item.isNotEmpty) {
                                        item.addAll({
                                          item.keys.last + 1: newMethod(
                                              context, item.keys.last + 1)
                                        });
                                      } else {
                                        item.addAll({0: newMethod(context, 0)});
                                      }
                                    });
                                  },
                                  child: const Text('Add Slot + ',
                                      style: TextStyle(
                                          fontFamily: "DMSans",
                                          color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
          },
        ));
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    final format = DateFormat.jm();
    return format.format(dt);
  }

  void showLoading() {
    showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: false,
      enableDrag: false,
      context: context,
      builder: (ctx) {
        return Column(
          children: [
            Text(
              "Account Creation",
              style: TextStyle(
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.height / 40),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "We are creating an account",
                style: TextStyle(
                    fontFamily: "DMSans",
                    color: Colors.black45,
                    fontSize: MediaQuery.of(context).size.height / 55),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white,
                color: Colors.green,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                  strokeWidth: 1, color: Colors.green),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Please Don't back or close the app",
                style: TextStyle(
                    fontFamily: "DMSans",
                    color: Colors.black45,
                    fontSize: MediaQuery.of(context).size.height / 45),
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> setSlot() async {
    if (RegisterDataClass.serverInit) {
      try {
        await _server
            .collection("SportistanPartners")
            .doc(RegisterDataClass.groundID.toString())
            .update({
              widget.day: [
                for (int i = 0; i < DataSave.entries.length; i++)
                  {
                    'time': DataSave.entries[i].name,
                    'timeEnd': DataSave.entries[i].name2,
                    'price': int.parse(DataSave.entries[i].email),
                    'slotID': UniqueID.generateRandomString(),
                  }
              ]
            })
            .then((value) => {
                  DataSave.isDataSave = true,
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Saved"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: Colors.green,
                  ))
                })
            .then((value) => {
                  if (widget.day == "Sunday")
                    {
                      getKycLinks(),
                    }
                });
      } catch (e) {
        if (mounted) {
          Errors.flushBarInform(
              "Unable to set slots something went wrong",
              context,
              'Error while creating please check internet or any other permission');
        }
      }
    } else {
      _server.collection("SportistanPartners").doc(RegisterDataClass.groundID.toString()).set({
        'Monday': [],
        'Tuesday': [],
        'Wednesday': [],
        'Thursday': [],
        'Friday': [],
        'Saturday': [],
        'Sunday': [],
        'geo': '',
        'locationName': '',
        'isVerified': false,
        'groundType': '',
        'userID': '',
        'groundID': '',
        'groundName': '',
        'kycImageLinks': [],
        'groundServices': [],
        'groundImages': [],
        'name': [],
        'onwards' : '',
        'accountCreatedAt': '',
      });
      RegisterDataClass.serverInit = true;
      setSlot();
    }
  }

  void getSlots() async {
    try {
      var daySlots = [];
      var collection = _server.collection('SportistanPartners');
      var docSnapshot = await collection.doc(RegisterDataClass.groundID.toString()).get();
      Map<String, dynamic> data = docSnapshot.data()!;
      daySlots = data["Monday"];
      if (mounted) {
        await addSlots(daySlots.length - 1);
      }
      for (int i = 0; i < daySlots.length; i++) {
        nameTECs[i]?.text = data["Monday"][i]['time'];
        nameTECs2[i]?.text = data["Monday"][i]['timeEnd'];
        mailTECs[i]?.text = data["Monday"][i]['price'].toString();
      }
      listLoad.value = false;
    } catch (e) {
      listLoad.value = false;
    }
  }

  Future<void> addSlots(int daySlots) async {
    for (int i = 0; i <= daySlots; i++) {
      item.addAll({i: newMethod(context, i)});
    }
    setState(() {});
  }



  Future<void> getKycLinks() async {
    showLoading();

    for (int i = 0; i < RegisterDataClass.kycImages.length; i++) {
      TaskSnapshot task = await _storage
          .ref(_auth.currentUser!.uid)
          .child("kyc")
          .child(RegisterDataClass.kycImages[i].name.toString())
          .putFile(File(RegisterDataClass.kycImages[i].path));
      await task.ref.getDownloadURL().then((value) => {
          RegisterDataClass.kycUrls.add(value)
          });
    }
    await getGroundLinks();

  }

  Future<void> getGroundLinks() async {
    for (int i = 0; i < RegisterDataClass.groundImages.length; i++) {
      TaskSnapshot task = await _storage
          .ref(_auth.currentUser!.uid)
          .child("kyc")
          .child(RegisterDataClass.groundImages[i].name.toString())
          .putFile(File(RegisterDataClass.groundImages[i].path));
      await task.ref.getDownloadURL().then((value) => {
            if (value.isNotEmpty) {RegisterDataClass.groundUrls.add(value)}
          });
    }
  setEverything();
  }
  Future<void> setEverything() async {

    try{
      await _server.collection("SportistanPartners").doc(RegisterDataClass.groundID).update({
        'geo': GeoFirePoint(GeoPoint(
            RegisterDataClass.latitude, RegisterDataClass.longitude))
            .data,
        'locationName': RegisterDataClass.address,
        'isVerified': false,
        'groundType': RegisterDataClass.sportsTag,
        'userID': _auth.currentUser!.uid,
        'groundID': RegisterDataClass.groundID,
        'groundName': RegisterDataClass.groundName,
        'kycImageLinks': RegisterDataClass.kycUrls,
        'groundServices': RegisterDataClass.groundServices,
        'groundImages': RegisterDataClass.groundUrls,
        'name': RegisterDataClass.personName,
        'onwards' : onwardsAmount,
        'accountCreatedAt':
        DateFormat('E, d MMMM yyyy HH:mm:ss').format(DateTime.now()),
      }).then((value) => {
      RegisterDataClass.clear(),

          PageRouter.pushRemoveUntil(context, const NavHome())
      });
    }catch(e){
      if (mounted) {
        Errors.flushBarInform("Something went wrong", context, "Try Again");
      }
    }



  }

}

class Entry {
  final String name;
  final String name2;
  final String email;

  Entry({required this.name, required this.name2, required this.email});
}

class DataSave {
  static bool isDataSave = false;
  static List<Entry> entries = [];
}
