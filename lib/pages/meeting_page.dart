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
  // RTCVideoViewObjectFit _objectFit =
  //     RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
  VideoRendererAdapter._internal(this.mid, this.stream, this.local);

  static Future<VideoRendererAdapter> create(
      String mid, MediaStream stream, bool local) async {
    VideoRendererAdapter renderer =
        VideoRendererAdapter._internal(mid, stream, local);
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
      // _objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
    }
  }

  // RTCVideoViewObjectFit get objFit => _objectFit;

  // set objectFit(RTCVideoViewObjectFit objectFit) {
  //   _objectFit = objectFit;
  // }

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
  final videoRenderers = Rx<List<VideoRendererAdapter>>([]);
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
          _localStream = await LocalStream.getUserMedia(
              constraints: Constraints(
            audio: true,
            video: false,
          ));
          ion?.sfu!.publish(_localStream!);
          _addAdapter(await VideoRendererAdapter.create(
              _localStream!.stream.id, _localStream!.stream, true));
        } catch (e) {
          print(e);
        }
      }
    };

    ion?.onLeave = (String reason) {
      print('reason: $reason');
    };

    ion?.onPeerEvent = (PeerEvent peerEvent) {
      String name = peerEvent.peer.info['name'];
      String state = '';
      switch (peerEvent.state) {
        case PeerState.NONE:
          break;
        case PeerState.JOIN:
          state = 'join';
          break;
        case PeerState.UPDATE:
          state = 'update';
          break;
        case PeerState.LEAVE:
          state = 'leave';
          break;
      }
      print('Peer:: [${peerEvent.peer.uid}:$name] $state::');
    };

    ion?.onStreamEvent = (StreamEvent streamEvent) async {
      switch (streamEvent.state) {
        case StreamState.NONE:
          break;
        case StreamState.ADD:
          if (streamEvent.streams.isNotEmpty) {
            String mid = streamEvent.streams[0].id;
            print('::::StreamAdd : [$mid]');
          }
          break;
        case StreamState.REMOVE:
          if (streamEvent.streams.isNotEmpty) {
            String mid = streamEvent.streams[0].id;
            print(':::Stream remove : [$mid]');
            _removeAdapter(mid);
          }
          break;
      }
    };

    ion?.onTrack = (MediaStreamTrack track, RemoteStream stream) async {
      print('track kind: ${track.kind}, onTrack is run');
      if (track.kind == 'audio') {
        _addAdapter(
            await VideoRendererAdapter.create(stream.id, stream.stream, false));
      }
    };

    name.value = prefs.getString('display_name') ?? 'guest';
    room.value = prefs.getString('room') ?? 'room1';
    _helper.join(room.value, name.value);
  }

  _removeAdapter(String mid) {
    videoRenderers.value.removeWhere((element) => element.mid == mid);
    videoRenderers.update((val) {});
  }

  _addAdapter(VideoRendererAdapter adapter) {
    videoRenderers.value.add(adapter);
    videoRenderers.update((val) {});
  }

  _switchSpeaker() {
    if (_localStr != null) {
      _speakerOn.value = !_speakerOn.value;
      MediaStreamTrack audioTrack = _localStr!.stream.getAudioTracks()[0];
      audioTrack.enableSpeakerphone(_speakerOn.value);
      print(':::Switch to : ${_speakerOn.value ? 'speaker' : 'earpiece'}');
    }
  }

  //Open or close audio
  _turnMicrophone() {
    print('turn mic was pressed');
    print('${_localStr == null}');
    if (_localStr != null && _localStr!.stream.getAudioTracks().length >= 0) {
      var muted = !_microphoneOff.value;
      _microphoneOff.value = muted;
      print('microphoneOff value: ${_microphoneOff.value.toString()}');
      _localStr?.stream.getAudioTracks()[0].enabled = !muted;
      print('::The microphone is ${muted ? 'muted' : 'unmuted'}::');
    }
    print('is above function run');
  }

  VideoRendererAdapter? get _localStr {
    VideoRendererAdapter? renderers;
    videoRenderers.value.forEach((element) {
      if (element.local) {
        renderers = element;
      }
    });
    return renderers;
  }

  List<VideoRendererAdapter> get _remoteStream {
    List<VideoRendererAdapter> renderers = ([]);
    videoRenderers.value.forEach((element) {
      if (!element.local) {
        renderers.add(element);
      }
    });
    return renderers;
  }

  _cleanUp() async {
    var ion = _helper.ion;

    if (_localStr != null) {
      await _localStream!.unpublish();
    }

    videoRenderers.value.forEach((item) async {
      var stream = item.stream;
      try {
        ion?.sfu!.close();
        await stream.dispose();
      } catch (e) {
        print('error in cleanup: $e');
      }
      videoRenderers.value.clear();
      await _helper.close();
    });
    Get.back();
  }

  _hangUp() {
    Get.dialog(AlertDialog(
      title: Text('HangUp'),
      content: Text('Are you sure you want to hangup?'),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text('Cancel')),
        TextButton(
            onPressed: () {
              Get.back();
              _cleanUp();
            },
            child: Text(
              'HangUp',
              style: TextStyle(color: Colors.red),
            ))
      ],
    ));
  }
}

class MeetingsPage extends GetView<MeetingController> {
  const MeetingsPage({Key? key}) : super(key: key);
  IonConnector? get ion => controller.ion;
  List<VideoRendererAdapter> get remoteStream => controller._remoteStream;

  // _buildMajorStream() {}
  // _buildLocalStream() {}
  // _buildStreamList() {}
  _buildLoading() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Waiting for other to join...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildTools() {
    return <Widget>[
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          onPressed: controller._turnMicrophone,
          shape: CircleBorder(
            side: BorderSide(color: Colors.white, width: 1),
          ),
          child: Obx(
            () => Icon(
              controller._microphoneOff.value
                  ? Icons.mic_off_rounded
                  : Icons.mic,
              color:
                  controller._microphoneOff.value ? Colors.red : Colors.white,
            ),
          ),
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          child: Obx(
            () => Icon(
              controller._speakerOn.value ? Icons.volume_up : Icons.phone,
            ),
          ),
          onPressed: controller._switchSpeaker,
        ),
      ),
      SizedBox(
        width: 36,
        height: 36,
        child: RawMaterialButton(
          onPressed: controller._hangUp,
          shape: CircleBorder(
            side: BorderSide(
              color: Colors.white,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.call_end,
            color: Colors.red,
          ),
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller._scaffoldKey,
      appBar: AppBar(
        title: Text('Meetings Page'),
      ),
      body: Container(
        color: Colors.black87,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Color(0xFFd8e2dc),
                  Color(0xFFffe5d9),
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        // child: _buildMajorStream(),

                        child: Text('THis is major stream'),
                      ),
                    ),
                    Positioned(
                      right: 7,
                      top: 45,
                      // child: _buildLocalStream(),
                      child: Text('local stream'),
                    ),
                    Positioned(
                      left: 5,
                      right: 5,
                      bottom: 45,
                      height: 90,
                      // child: _buildStreamList()
                      child: Text('stream list'),
                    )
                  ],
                ),
              ),
            ),
            Obx(() => (remoteStream.isEmpty) ? _buildLoading() : Container()),
            Positioned(
              left: 5,
              right: 5,
              bottom: 4,
              height: 48,
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    height: 48,
                    margin: EdgeInsets.all(0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: _buildTools(),
                    ),
                  )
                ],
              ),
            ),
            Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 48,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0.5,
                      child: Container(
                        margin: EdgeInsets.all(0),
                        child: Text(
                          'ION Conference : [${controller.room.value}]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
