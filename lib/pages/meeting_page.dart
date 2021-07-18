import 'package:flutter/material.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../controllers/ion_controller.dart';
import 'package:get/get.dart';

class MeetingBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IonController>(() => IonController());
    Get.lazyPut<MeetingController>(() => MeetingController());
  }
}

class VideoRendererAdapter {
  String mid;
  bool local;
  RTCVideoRenderer? renderer;
  MediaStream stream;
  RTCVideoViewObjectFit _objectFit =
      RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
  VideoRendererAdapter._internal(this.mid, this.stream, this.local);

  static Future<VideoRendererAdapter> create(
      String mid, MediaStream stream, bool local) async {
    var renderer = VideoRendererAdapter._internal(mid, stream, local);
    await renderer.setupSrcObject();
    return renderer;
  }

  setupSrcObject() async {
    if (renderer == null) {
      renderer = new RTCVideoRenderer();
      await renderer?.initialize();
    }
    renderer?.srcObject = stream;
    if (local) {
      _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  switchObjFit() {
    _objectFit =
        (_objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitContain)
            ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
            : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain;
  }

  RTCVideoViewObjectFit get objFit => _objectFit;

  set objectFit(RTCVideoViewObjectFit objectFit) {
    _objectFit = objectFit;
  }

  dispose() async {
    if (renderer != null) {
      print('dispose for texture id ' + renderer!.textureId.toString());
      renderer?.srcObject = null;
      await renderer?.dispose();
      renderer = null;
    }
  }
}

class MeetingController extends GetxController {
  final _helper = Get.find<IonController>();
  late SharedPreferences prefs;
  LocalStream? _localStream;
  IonConnector? get ion => _helper.ion;
  var _microphoneOff = false.obs;
  var _speakerOn = true.obs;
  var _scaffoldKey = GlobalKey<ScaffoldState>();
  var name = ''.obs;
  var room = ''.obs;
  @override
  @mustCallSuper
  void onInit() async {
    super.onInit();
    prefs = await _helper.prefs();

    if (ion == null) {
      print('IonHelper is not initialized');
      print('goBack to /login');
      Get.offNamed('/login');
      return;
    }

    ion?.onJoin = (bool success, String reason) async {
      print('Join Success');
      if (success) {
        try {
          var _codec = prefs.getString('codec') ?? 'vp8';
          _localStream = await LocalStream.getUserMedia(
              constraints: Constraints(
            audio: true,
            video: false,
          ));
          ion?.sfu!.publish(_localStream!);
          // _addAdapter(await VideoRenderer) {}
        } catch (e) {
          print(e);
        }
      }
    };

    _switchSpeaker() {}
  }
}

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meetings Page'),
      ),
      body: Container(
        color: Colors.black87,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Color(0xFFd8e2dc),
                        Color(0xFFffe5d9),
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                      child: Center(child: Image.asset('assets/calling.png')),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
