import 'package:flutter/material.dart';
import 'package:flutter_voice_call/controllers/ion_controller.dart';
import 'package:flutter_voice_call/pages/login.dart';
import 'package:flutter_voice_call/pages/meeting_page.dart';
import 'package:get/get.dart';

void main() {
  Get.put(IonController(), permanent: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pion/ion P2P audio calling',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Pion/ion one to many broadcast'),
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => LoginView(),
          binding: LoginBindings(),
        ),
        GetPage(
          name: '/meeting',
          page: () => MeetingsPage(),
        )
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
