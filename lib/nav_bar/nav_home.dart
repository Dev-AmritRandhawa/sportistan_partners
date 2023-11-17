import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';
import 'package:sportistan_partners/nav_bar/bookings.dart';
import 'package:sportistan_partners/nav_bar/home.dart';
import 'package:sportistan_partners/nav_bar/profile_edit/profile.dart';

class NavHome extends StatefulWidget {
  const NavHome({super.key});

  @override
  State<NavHome> createState() => _NavHomeState();
}

class _NavHomeState extends State<NavHome> {
  late PageController _pageController;
  int selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedIndex);
    setupInteractedMessage();
  }

  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    onButtonPressed(1);
  }

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
    _pageController.animateToPage(selectedIndex,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuad);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              children: _listOfWidget,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SlidingClippedNavBar(
        backgroundColor: Colors.white,
        onButtonPressed: onButtonPressed,
        iconSize: 30,
        activeColor: const Color(0xFF01579B),
        selectedIndex: selectedIndex,
        barItems: <BarItem>[
          BarItem(
            icon: Icons.home_outlined,
            title: 'Home',
          ),
          BarItem(
            icon: Icons.calendar_today,
            title: 'My Bookings',
          ),
          BarItem(
            icon: Icons.account_circle,
            title: 'Profile',
          ),
        ],
      ),
    );
  }

  final List<Widget> _listOfWidget = <Widget>[
    const Home(),
    const Bookings(),
    const Profile()
  ];
}
