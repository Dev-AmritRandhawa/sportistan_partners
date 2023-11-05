import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sportistan_partners/nav_bar/slot_add_settings.dart';
import 'package:sportistan_partners/utils/errors.dart';

class SlotSettingsID {
  static String? groundID;
  static String? groundName;
}

class UniqueID {
  static String generateRandomString() {
    var r = Random();
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(20, (index) => chars[r.nextInt(chars.length)]).join();
  }
}

class SlotSettings extends StatefulWidget {
  final String groundName;
  final String groundID;

  const SlotSettings(
      {super.key, required this.groundName, required this.groundID});

  @override
  SlotSettingsState createState() => SlotSettingsState();
}

class SlotSettingsState extends State<SlotSettings> {
  final PageController _pageController = PageController(initialPage: 0);

  int currentPage = 0;

  _onPageChanged(int index) {
    setState(() {
      currentPage = index;
    });
  }

  @override
  void initState() {
    SlotSettingsID.groundID = widget.groundID;
    SlotSettingsID.groundName = widget.groundName;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            itemCount: 7,
            onPageChanged: _onPageChanged,
            itemBuilder: (ctx, i) => _listOfWidget[i],
          ),
          SafeArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  child: const Text("Next",
                      style:
                          TextStyle(color: Colors.black, fontFamily: "DMSans")),
                  onPressed: () {
                    if (DataSave.entries.isNotEmpty) {
                      if (DataSave.isDataSave) {
                        _pageController.animateToPage(currentPage + 1,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeIn);
                        DataSave.isDataSave = false;
                        DataSave.entries.clear();
                      } else {
                        showDialog(
                          context: context,
                          builder: (ctx) => Platform.isAndroid
                              ? AlertDialog(
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("Ok"))
                                  ],
                                  title: const Text("Save Data"),
                                  content:
                                      const Text("Please Save The Slots First"),
                                )
                              : CupertinoAlertDialog(
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text("Ok"))
                                  ],
                                  title: const Text("Save Data"),
                                  content:
                                      const Text("Please Save The Slots First"),
                                ),
                        );
                      }
                    } else {
                      Alert.flushBarBadAlert(
                          message: "Please Save a Slot",
                          context: context,
                          title: "Slot is Required");
                    }
                  }),
            ]),
          ),
        ],
      ),
    );
  }
  final List<Widget> _listOfWidget = <Widget>[
    const SlotAddSettings(
      day: 'Monday',
    ),
    const SlotAddSettings(
      day: 'Tuesday',
    ),
    const SlotAddSettings(
      day: 'Wednesday',
    ),
    const SlotAddSettings(
      day: 'Thursday',
    ),
    const SlotAddSettings(
      day: 'Friday',
    ),
    const SlotAddSettings(
      day: 'Saturday',
    ),
    const SlotAddSettings(
      day: 'Sunday',
    ),
  ];
}
