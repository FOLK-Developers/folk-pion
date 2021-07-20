import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_voice_call/controllers/ion_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    Get.lazyPut<IonController>(() => IonController());
  }
}

class LoginController extends GetxController {
  final _helper = Get.find<IonController>();
  late SharedPreferences prefs;
  late var _server = ''.obs;
  late var _sid = ''.obs;

  @override
  @mustCallSuper
  void onInit() async {
    prefs = await SharedPreferences.getInstance();
    _server.value = prefs.getString('server') ?? '127.0.0.1';
    _sid.value = prefs.getString('room') ?? 'test room';
    super.onInit();
  }

  bool handleJoin() {
    if (_server.value.length == 0 || _sid.value.length == 0) {
      return false;
    }
    prefs.setString('server', _server.value);
    prefs.setString('room', _sid.value);
    // _helper.editUrl(_server.value, _sid.value);

    _helper.connect(_server);
    Get.toNamed('/meeting');
    return true;
  }
}

class LoginView extends GetView<LoginController> {
  Widget buildJoinView() {
    return Align(
      alignment: Alignment(0, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 260,
            child: Obx(() => TextField(
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12)),
                      hintText: 'Enter ION Server'),
                  onChanged: (value) {
                    controller._server.value = value;
                  },
                  controller: TextEditingController.fromValue(TextEditingValue(
                      text: controller._server.value,
                      selection: TextSelection.fromPosition(TextPosition(
                          offset: '${controller._server.value}'.length)))),
                )),
          ),
          SizedBox(
            height: 260,
            child: Obx(() => TextField(
                  keyboardType: TextInputType.text,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(10),
                      border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black12)),
                      hintText: 'Enter RoomID'),
                  onChanged: (value) {
                    controller._sid.value = value;
                  },
                  controller: TextEditingController.fromValue(TextEditingValue(
                      text: controller._sid.value,
                      selection: TextSelection.fromPosition(TextPosition(
                          offset: '${controller._sid.value}'.length)))),
                )),
          ),
          SizedBox(width: 260.0, height: 48.0),
          InkWell(
            child: Container(
              width: 220,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xFFe13b3f), width: 1),
              ),
              child: Center(
                child: Text(
                  'Join',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            onTap: () {
              if (!controller.handleJoin()) {
                Get.dialog(AlertDialog(
                  title: Text('Room/Server is empty'),
                  content: Text('Please input Room id'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Okay'),
                    )
                  ],
                ));
              }
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PION'),
      ),
      body: Center(
        child: buildJoinView(),
      ),
    );
  }
}
