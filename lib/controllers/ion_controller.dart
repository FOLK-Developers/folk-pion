import 'package:get/state_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ion/flutter_ion.dart';
import 'package:uuid/uuid.dart';

class IonController extends GetxController {
  SharedPreferences? _prefs;
  String? _sid;
  String? _name;
  IonConnector? _ion;
  final String _uid = Uuid().v4();
  var signal;
  IonConnector? get ion => _ion;
  String? get sid => _sid;
  String get uid => _uid;
  String? get name => _name;
  Client? get sfu => _ion?.sfu;

  @override
  void onInit() {
    print('onInit method');
    super.onInit();
  }

  Future<SharedPreferences> prefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  connect(host) async {
    if (_ion == null) {
      var url = 'http://$host:5551';
      _ion = IonConnector(url: url);
    }
  }

  join(String sid, String displayName) async {
    _sid = sid;
    _name = displayName;
    _ion?.join(sid: sid, uid: uid, info: {'name': displayName});
  }

  close() async {
    _ion?.leave(uid);
    _ion?.close();
    _ion = null;
  }
}
