import 'dart:async';
import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:intl/intl.dart';
import 'package:sportistan_partners/authentication/slot_setting.dart';
import 'package:sportistan_partners/bookings/book_a_slot.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';

class GroundDetailsRegister extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;
  final List<String> groundImages;

  const GroundDetailsRegister(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.address,
      required this.groundImages});

  @override
  State<GroundDetailsRegister> createState() => _GroundDetailsRegisterState();
}

class _GroundDetailsRegisterState extends State<GroundDetailsRegister> {
  TextEditingController nameController = TextEditingController();
  TextEditingController groundController = TextEditingController();
  GlobalKey<FormState> groundKey = GlobalKey<FormState>();
  GlobalKey<FormState> nameKey = GlobalKey<FormState>();
  ValueNotifier<bool> fileUpload = ValueNotifier<bool>(false);
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  final _auth = FirebaseAuth.instance;
  List<String> allFiles = [];
  final _storage = FirebaseStorage.instance;
  FilePickerResult? result;
  List<String> urls = [];

  final _server = FirebaseFirestore.instance;

  @override
  void dispose() {
    _server.terminate();
    nameController.dispose();
    groundController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _server.enableNetwork();
  }

  List<File>? selectedFiles = [];

  double? _progress;
  String? sportTags = "Cricket";
  List<String> sportOptions = [
    'Cricket',
    'Football',
    'Tennis',
    'Hockey',
    'Badminton',
    'Volleyball',
    'Swimming',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: DelayedDisplay(
          child: Column(
            children: [
              Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Ground Register"),
                  )),
              Text(
                "Let's create account & Complete The KYC",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.height / 40,
                    fontFamily: "DMSans",
                    color: Colors.black),
              ),
              Form(
                key: nameKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    validator: (input) {
                      if (input!.isEmpty) {
                        Errors.flushBarAuth("Enter Your Name", context);
                        return "Name is Missing";
                      } else {
                        return null;
                      }
                    },
                    style: const TextStyle(color: Colors.black87),
                    controller: nameController,
                    decoration: InputDecoration(
                        errorStyle: const TextStyle(color: Colors.black),
                        hintText: "Owner Name as Per Documents",
                        hintStyle: TextStyle(
                            fontSize: MediaQuery.of(context).size.height / 50,
                            color: Colors.black87,
                            fontFamily: "Nunito"),
                        fillColor: Colors.white,
                        filled: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        )),
                  ),
                ),
              ),
              Form(
                key: groundKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    maxLength: 40,
                    validator: (input) {
                      if (input!.isEmpty) {
                        Errors.flushBarAuth("Enter Your Ground Name", context);
                        return "Ground Name is Missing";
                      } else {
                        return null;
                      }
                    },
                    style: const TextStyle(color: Colors.black87),
                    controller: groundController,
                    decoration: InputDecoration(
                        counter: Container(),
                        errorStyle: const TextStyle(color: Colors.black),
                        hintText: "Ground Name",
                        hintStyle: TextStyle(
                            fontSize: MediaQuery.of(context).size.height / 50,
                            color: Colors.black87,
                            fontFamily: "Nunito"),
                        fillColor: Colors.white,
                        filled: true,
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                        )),
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    const Icon(
                      Icons.location_on_sharp,
                      color: Colors.green,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.address,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.height / 50,
                            fontFamily: "DMSans",
                            color: Colors.black),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        addAutomaticKeepAlives: true,
                        children: <Widget>[
                          Content(
                            title: 'Choose Ground Type',
                            child: ChipsChoice<String>.single(
                              value: sportTags,
                              onChanged: (val) =>
                                  setState(() => sportTags = val),
                              choiceItems: C2Choice.listFrom<String, String>(
                                source: sportOptions,
                                value: (i, v) => v,
                                label: (i, v) => v,
                                tooltip: (i, v) => v,
                              ),
                              choiceCheckmark: true,
                              choiceStyle: C2ChipStyle.filled(
                                selectedStyle: const C2ChipStyle(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(25),
                                  ),
                                ),
                              ),
                              wrapped: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Proof of Ownership",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: loading,
                      builder: (context, value, child) {
                        return value
                            ? Column(
                                children: [
                                  LinearProgressIndicator(
                                      value: _progress,
                                      color: Colors.green,
                                      backgroundColor: Colors.grey),
                                  const Text(
                                    "Uploading Images",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: "Nunito"),
                                  )
                                ],
                              )
                            : Container();
                      },
                    ),
                    const Column(
                      children: [
                        Text("-Attach your Identity Proof",
                            style: TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                        Text("-Attach your Ownership Proof",
                            style: TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        MaterialButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                            color: Colors.orangeAccent,
                            child: const Text("Choose File",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                      allowMultiple: true,
                                      type: FileType.image);
                              if (result != null) {
                                loading.value = true;
                                List<File> files = result.paths
                                    .map((path) => File(path!))
                                    .toList();
                                try {
                                  for (int i = 0; i < files.length; i++) {
                                    await _storage
                                        .ref(
                                            "${_auth.currentUser!.phoneNumber}")
                                        .putFile(files[i])
                                        .whenComplete(() async => {
                                              await _storage
                                                  .ref()
                                                  .storage
                                                  .ref(
                                                      "${_auth.currentUser!.phoneNumber}")
                                                  .getDownloadURL()
                                                  .then((value) =>
                                                      {urls.add(value)}),
                                              setState(() {
                                                allFiles.add(
                                                    DateTime.now().toString());
                                              }),
                                            });
                                  }

                                  fileUpload.value = true;
                                  loading.value = false;
                                } catch (e) {
                                  fileUpload.value = false;
                                }
                              } else {
                                // User canceled the picker
                              }
                            }),
                        ValueListenableBuilder(
                          valueListenable: fileUpload,
                          builder: (context, value, child) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).size.height / 15,
                                  bottom:
                                      MediaQuery.of(context).size.height / 15),
                              child: CupertinoButton(
                                  color: Colors.green,
                                  onPressed: value
                                      ? () async {
                                          if (nameKey.currentState!.validate() |
                                              groundKey.currentState!
                                                  .validate()) {
                                            setEverything();
                                          } else {
                                            Errors.flushBarInform(
                                                "Field is Missing",
                                                context,
                                                "Missing");
                                          }
                                        }
                                      : null,
                                  child: const Text(
                                    "Set Slots",
                                    style: TextStyle(color: Colors.white),
                                  )),
                            );
                          },
                        )
                      ],
                    ),
                    ValueListenableBuilder(
                      valueListenable: fileUpload,
                      builder: (context, value, child) {
                        return value
                            ? ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: allFiles.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: const Icon(Icons.image),
                                    title: Text(allFiles[index]),
                                    trailing: InkWell(
                                        onTap: () {
                                          _storage
                                              .ref(
                                                  "${_auth.currentUser!.phoneNumber}/${allFiles[index]}")
                                              .delete()
                                              .whenComplete(() => setState(() {
                                                    allFiles.removeAt(index);
                                                    if (allFiles.isEmpty) {
                                                      fileUpload.value = false;
                                                    }
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(SnackBar(
                                                            duration:
                                                                const Duration(
                                                                    seconds: 1),
                                                            content: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                const Text(
                                                                    "Deleting"),
                                                                Platform.isIOS
                                                                    ? const CupertinoActivityIndicator()
                                                                    : const CircularProgressIndicator()
                                                              ],
                                                            )));
                                                    Errors.flushBarInform(
                                                        "Deleted",
                                                        context,
                                                        "Success");
                                                  }));
                                        },
                                        child: const Icon(Icons.close)),
                                  );
                                },
                              )
                            : Container();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> setEverything() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Registering"),
          CircularProgressIndicator(
            color: Colors.green,
            strokeWidth: 1,
          )
        ],
      ),
      duration: Duration(seconds: 1),
    ));
    try {
      if (_auth.currentUser != null) {
        String uniqueID = UniqueID.generateRandomString();
        await _server.collection("SportistanPartners").doc(uniqueID).set({
          'geo': GeoFirePoint(GeoPoint(widget.latitude, widget.longitude)).data,
          'locationName': widget.address,
          'isVerified': false,
          'groundType': sportTags,
          'userID': _auth.currentUser!.uid,
          'groundID': uniqueID,
          'groundName': groundController.value.text,
          'kycImageLinks': urls,
          'groundImages': widget.groundImages,
          'name': nameController.value.text,
          'accountCreatedAt':
              DateFormat('E, d MMMM yyyy HH:mm:ss').format(DateTime.now()),
        }).then((value) => {
              _server
                  .collection("SportistanPartnersProfile")
                  .doc(_auth.currentUser!.uid)
                  .collection("Account")
                  .doc(DateTime.now().toString())
                  .set({'accountCreatedAt': DateTime.now()}).then((value) => {
                        PageRouter.pushRemoveUntil(
                            context,
                            SlotSettings(
                              groundName: groundController.value.text,
                              groundID: uniqueID,
                            ))
                      }),
            });
      }
    } catch (e) {
      if (mounted) {
        Errors.flushBarInform("Something went wrong", context, "Error");
      }
    }
  }


}
