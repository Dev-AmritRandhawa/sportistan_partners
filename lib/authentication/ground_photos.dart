import 'dart:io';
import 'package:delayed_display/delayed_display.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:lottie/lottie.dart';
import 'package:sportistan_partners/authentication/ground_details_register.dart';
import 'package:sportistan_partners/utils/errors.dart';
import 'package:sportistan_partners/utils/page_router.dart';

class GroundPhotos extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String address;

  const GroundPhotos(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.address});

  @override
  State<GroundPhotos> createState() => _GroundPhotosState();
}

class _GroundPhotosState extends State<GroundPhotos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  ValueNotifier<bool> imagesPreview = ValueNotifier<bool>(false);

  final _storage = FirebaseStorage.instance;
  double? _progress;

  TextEditingController nameController = TextEditingController();
  TextEditingController groundController = TextEditingController();
  GlobalKey<FormState> groundKey = GlobalKey<FormState>();
  GlobalKey<FormState> nameKey = GlobalKey<FormState>();
  ValueNotifier<bool> fileUpload = ValueNotifier<bool>(false);
  ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  final _auth = FirebaseAuth.instance;
  List<String> allFiles = [];
  FilePickerResult? result;
  List<String> urls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CupertinoButton(
          onPressed: () {
              const number = '+918591719905'; //set the number here
              FlutterPhoneDirectCaller.callNumber(number);
          },
          child: const Text("Need Help? Contact Customer Support")),
      body: SafeArea(
          child: DelayedDisplay(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 10,
                  width: MediaQuery.of(context).size.height / 10,
                  child: Image.asset(
                    "assets/logo.png",
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 5,
                width: MediaQuery.of(context).size.height / 5,
                child: Lottie.asset(
                  "assets/groundPhotos.json",
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller
                      ..duration = composition.duration
                      ..repeat();
                  },
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
                            fontSize: MediaQuery.of(context).size.height / 40,
                            fontFamily: "DMSans",
                            color: Colors.black),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: CupertinoButton(
                          color: Colors.orangeAccent,
                          child: const Text("Upload Ground Images"),
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                    allowMultiple: true, type: FileType.image);
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
                                              allFiles.add(DateTime.now().toString());
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
                    ),
                    ValueListenableBuilder(
                      valueListenable: loading,
                      builder: (context, value, child) {
                        return value
                            ? Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  children: [
                                    LinearProgressIndicator(
                                        value: _progress,
                                        color: Colors.green,
                                        backgroundColor: Colors.grey),
                                  ],
                                ),
                              )
                            : Container();
                      },
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
                                          try {
                                            _storage
                                                .ref(
                                                    "${_auth.currentUser!.phoneNumber}/${allFiles[index]}")
                                                .delete()
                                                .whenComplete(() =>
                                                    setState(() {
                                                      allFiles.removeAt(index);
                                                      if (allFiles.isEmpty) {
                                                        fileUpload.value =
                                                            false;
                                                      }
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                                  duration:
                                                                      const Duration(
                                                                          seconds:
                                                                              2),
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
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    duration:
                                                        Duration(seconds: 2),
                                                    content: Text(
                                                        "Something went wrong")));
                                          }
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
              ValueListenableBuilder(
                valueListenable: fileUpload,
                builder: (context, value, child) {
                  return Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 15,
                        bottom: MediaQuery.of(context).size.height / 15),
                    child: CupertinoButton(
                        color: Colors.green,
                        onPressed: value
                            ? () async {
                                setEverything();
                              }
                            : null,
                        child: const Text("Next Step")),
                  );
                },
              ),
            ],
          ),
        ),
      )),
    );
  }

  Future<void> setEverything() async {
    PageRouter.push(
        context,
        GroundDetailsRegister(
            latitude: widget.latitude,
            longitude: widget.longitude,
            address: widget.address,
            groundImages: urls));
  }
}
