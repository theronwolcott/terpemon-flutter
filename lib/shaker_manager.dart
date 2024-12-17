import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeManager {
  static ShakeManager? _instance;
  double _maxAcceleration = 0.0;
  bool _isRecording = false;
  bool _didShake = false;
  late StreamSubscription<AccelerometerEvent> streamSubscription;
  Function()? _callback;

  bool get didShake => _didShake;

  ShakeManager._internal() {
    streamSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen(_onAccelerometerEvent);
  }

  static ShakeManager getInstance() {
    _instance ??= ShakeManager._internal();
    return _instance!;
  }

  // sensor handler
  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_isRecording || _didShake) return;
    double acceleration = _calculateAcceleration(event);
    if (acceleration > 10.0) {
      _didShake = true;
      if (_callback != null) {
        _callback!();
      }
    }
  }

  double _calculateAcceleration(AccelerometerEvent event) {
    return sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z));
  }

  // pass in optional callback function to be called with every additional shake
  // callback function is used for updates between start and stop, for example
  // tracking shakes over 10 seconds and updating UI
  void start([void Function()? callback]) {
    _callback = callback;
    _isRecording = true;
  }

// _currentResults, which this returns, is how we will update total shakes
// and max acceleration for a user
  void stop() {
    _isRecording = false;
    _callback = null;
    _didShake = false;
    return;
  }

  void dispose() {
    streamSubscription.cancel();
  }
}

// class ShakeManagerResults {
//   int count = 0;
//   Duration duration = const Duration(seconds: 0);
//   double maxAcceleration = 0.0;
//   DateTime startTime = DateTime.now();
// }
