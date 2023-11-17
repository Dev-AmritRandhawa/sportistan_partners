import 'dart:io';
import 'package:chips_choice/chips_choice.dart';
import 'package:delayed_display/delayed_display.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:sportistan_partners/authentication/ground_details_register.dart';
import 'package:sportistan_partners/bookings/book_a_slot.dart';
import 'package:sportistan_partners/utils/page_router.dart';
import 'package:sportistan_partners/utils/register_data_class.dart';

class GroundPhotos extends StatefulWidget {
  const GroundPhotos({super.key});



  @override
  State<GroundPhotos> createState() => _GroundPhotosState();
}

class _GroundPhotosState extends State<GroundPhotos>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  List<String> serviceTags = ['Washroom'];
  List<String> serviceOptions = [
    'Flood Lights',
    'Parking',
    'Sound System',
    'Warm Up Area',
    'Washroom',
    'Coaching Available',
  ];

  var currentPage = 0;

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


  TextEditingController nameController = TextEditingController();
  TextEditingController groundController = TextEditingController();
  GlobalKey<FormState> groundKey = GlobalKey<FormState>();
  GlobalKey<FormState> nameKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: DelayedDisplay(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                        RegisterDataClass.address,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.height / 40,
                            fontFamily: "DMSans",
                            color: Colors.black),
                      ),
                    ),
                    RegisterDataClass.groundImages.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 20),
                            child: CupertinoButton(
                                color: Colors.orangeAccent,
                                child: const Text("Select Images"),
                                onPressed: () async {
                                  uploadImages();
                                }),
                          )
                        : Container(),
                    ListView.builder(
                      itemCount: RegisterDataClass.groundImages.length,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return RegisterDataClass.groundImages.isNotEmpty
                            ? ListTile(
                                title: Text(RegisterDataClass.groundImages[index].name.toString()),
                                leading: SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height / 25,
                                    child:
                                        Image.file(File(RegisterDataClass.groundImages[index].path))),
                                onTap: () async {
                                  setState(() {
                                    RegisterDataClass.groundImages.removeAt(index);
                                  });
                                },
                                trailing: const Icon(Icons.delete_forever,
                                    color: Colors.red),
                              )
                            : Container();
                      },
                    ),
                  ],
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
                      title: 'Choose Ground Services if Available',
                      child: ChipsChoice<String>.multiple(
                        value: serviceTags,
                        onChanged: (val) => setState(() => serviceTags = val),
                        choiceItems: C2Choice.listFrom<String, String>(
                          source: serviceOptions,
                          value: (i, v) => v,
                          label: (i, v) => v,
                          tooltip: (i, v) => v,
                        ),
                        choiceCheckmark: true,
                        choiceStyle: C2ChipStyle.filled(
                          color: Colors.green,
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
              RegisterDataClass.groundImages.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CupertinoButton(
                          color: Colors.green,
                          onPressed: () async {
                            RegisterDataClass.groundServices = serviceTags;
                            PageRouter.push(context, const GroundDetailsRegister());
                          },
                          child: const Text(
                            "Next Step",
                            style: TextStyle(fontFamily: "DMSans"),
                          )),
                    )
                  : Container(),
              SizedBox(
                height: MediaQuery.of(context).size.height / 10,
              )
            ],
          ),
        ),
      )),
    );
  }


  uploadImages() async {
    final ImagePicker picker = ImagePicker();
    RegisterDataClass.groundImages = await picker.pickMultiImage(imageQuality: 50);
    if (RegisterDataClass.groundImages.isNotEmpty) {
      setState(() {});
    }
  }






}
