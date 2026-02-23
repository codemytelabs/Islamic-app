import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class QiblaScreen extends StatefulWidget {
  final bool showScaffold;
  final Widget? topWidget;

  const QiblaScreen({
    super.key,
    this.showScaffold = true,
    this.topWidget,
  });

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;
  static const double _lockDeltaThreshold = 2.5;
  static const int _lockStableSamples = 5;
  static const double _maxGoodCompassAccuracy = 20;
  static const double _flatHorizontalThreshold = 3.0;
  static const double _flatVerticalMin = 8.5;
  static const int _maxUnreliableSamples = 12;
  static const Duration _lockWatchdogTimeout = Duration(seconds: 10);

  double? _qiblaBearing;
  double? _heading;
  double? _compassAccuracy;
  double? _lastHeading;
  int _stableHeadingSamples = 0;
  bool _isDirectionLocked = false;
  bool _hasLocationFix = false;
  bool _isFlatSurface = false;
  bool _compassPausedForUnreliable = false;
  int _unreliableSamples = 0;
  String _status = 'Locating...';
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _lockWatchdog;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _status = 'Enable location to calculate Qibla');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _status = 'Location permission required for Qibla');
        return;
      }

      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      _updateQiblaBearing(initialPosition);

      _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
        ),
      ).listen(
        _updateQiblaBearing,
        onError: (_) {
          if (!mounted) return;
          setState(() => _status = 'Unable to track location updates');
        },
      );

      _startCompassListener();

      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = accelerometerEventStream().listen((event) {
        if (!mounted) return;

        final horizontalMag = math.sqrt(event.x * event.x + event.y * event.y);
        final flat = horizontalMag <= _flatHorizontalThreshold &&
            event.z.abs() >= _flatVerticalMin;

        if (_isFlatSurface == flat) return;

        setState(() {
          _isFlatSurface = flat;
          if (!_isFlatSurface) {
            _isDirectionLocked = false;
            _stableHeadingSamples = 0;
          }
        });
      });

      if (!mounted) return;
      setState(() {
        _compassPausedForUnreliable = false;
        _unreliableSamples = 0;
        _status = 'Qibla direction updating';
      });

      _startLockWatchdog();
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Unable to calculate Qibla right now');
    }
  }

  bool _isReliableCompass({required double? heading, required double? accuracy}) {
    if (heading == null) return false;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid && accuracy == null) return false;
    if (accuracy == null) return true;
    return accuracy <= _maxGoodCompassAccuracy;
  }

  void _startCompassListener() {
    _compassSubscription?.cancel();
    _compassSubscription = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        final nextHeading = event.heading;
        final accuracy = event.accuracy;
        final reliableCompass = _isReliableCompass(
          heading: nextHeading,
          accuracy: accuracy,
        );

        if (!reliableCompass) {
          _unreliableSamples++;
        } else {
          _unreliableSamples = 0;
        }

        if (_unreliableSamples >= _maxUnreliableSamples) {
          _pauseCompassForUnreliable();
          return;
        }

        if (nextHeading != null && _lastHeading != null) {
          final delta = _angleDeltaDegrees(nextHeading, _lastHeading!);
          if (delta <= _lockDeltaThreshold) {
            _stableHeadingSamples++;
          } else {
            _stableHeadingSamples = 0;
          }
        } else {
          _stableHeadingSamples = 0;
        }

        _lastHeading = nextHeading;
        final locked =
            _hasLocationFix &&
            _isFlatSurface &&
            reliableCompass &&
            nextHeading != null &&
            _stableHeadingSamples >= _lockStableSamples;

        setState(() {
          _heading = nextHeading;
          _compassAccuracy = accuracy;
          _isDirectionLocked = locked;
          _status = _qiblaBearing == null
              ? 'Calculating Qibla...'
              : (_heading == null
                    ? 'Compass unavailable: use north-based direction'
                    : (!_isFlatSurface
                          ? 'Place phone flat on a horizontal surface'
                          : (!reliableCompass
                                ? 'Calibrate compass (move phone in a figure-8)'
                                : (_isDirectionLocked
                                      ? 'Qibla locked'
                                      : 'Keep phone steady to lock direction'))));
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _status = 'Compass unavailable on this device');
      },
    );
  }

  void _startLockWatchdog() {
    _lockWatchdog?.cancel();
    _lockWatchdog = Timer(_lockWatchdogTimeout, () {
      if (!mounted) return;
      if (_isDirectionLocked || _compassPausedForUnreliable) return;
      _pauseCompassForUnreliable();
    });
  }

  void _updateQiblaBearing(Position position) {
    final bearing = _calculateBearing(
      fromLat: position.latitude,
      fromLng: position.longitude,
      toLat: _kaabaLat,
      toLng: _kaabaLng,
    );

    if (!mounted) return;
    setState(() {
      _qiblaBearing = bearing;
      _hasLocationFix = true;
    });
  }

  void _pauseCompassForUnreliable() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _lockWatchdog?.cancel();

    if (!mounted) return;
    setState(() {
      _compassPausedForUnreliable = true;
      _heading = null;
      _lastHeading = null;
      _stableHeadingSamples = 0;
      _isDirectionLocked = false;
      _status =
          'Compass sensor is unreliable. Calibrate in figure-8 and tap Retry Compass.';
    });
  }

  void _retryCompassOnly() {
    if (!mounted) return;
    setState(() {
      _compassPausedForUnreliable = false;
      _unreliableSamples = 0;
      _status = 'Retrying compass...';
    });

    _startCompassListener();
    _startLockWatchdog();
  }

  double _angleDeltaDegrees(double a, double b) {
    var delta = (a - b).abs() % 360;
    if (delta > 180) delta = 360 - delta;
    return delta;
  }

  double _calculateBearing({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    final phi1 = _toRad(fromLat);
    final phi2 = _toRad(toLat);
    final deltaLambda = _toRad(toLng - fromLng);

    final y = math.sin(deltaLambda);
    final x =
        math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLambda);
    final theta = math.atan2(y, x);
    final bearing = (_toDeg(theta) + 360) % 360;
    return bearing;
  }

  double _toRad(double deg) => deg * math.pi / 180;
  double _toDeg(double rad) => rad * 180 / math.pi;

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _lockWatchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final body = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.topWidget != null) ...[
              const SizedBox(height: 2),
              widget.topWidget!,
            ],
            Card(
              elevation: 0,
              color: colors.tertiaryContainer.withValues(alpha: 0.30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      _qiblaBearing == null
                          ? _status
                          : 'Qibla: ${_qiblaBearing!.toStringAsFixed(1)}° from North',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 240,
                      child: Builder(
                        builder: (context) {
                          final hasQibla = _qiblaBearing != null;

                          if (!hasQibla) {
                            return const Center(
                              child: Text(
                                'Allow location to calculate Qibla direction',
                              ),
                            );
                          }

                          final headingRad =
                              ((_heading ?? 0) * math.pi / 180);
                          final relativeRotation = _heading == null
                              ? (_qiblaBearing! * math.pi / 180)
                              : ((_qiblaBearing! - _heading!) * math.pi / 180);

                          return Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: -headingRad,
                                  child: SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 220,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: colors.outlineVariant,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        const Positioned(top: 12, child: Text('N')),
                                        const Positioned(right: 14, child: Text('E')),
                                        const Positioned(bottom: 12, child: Text('S')),
                                        const Positioned(left: 14, child: Text('W')),
                                      ],
                                    ),
                                  ),
                                ),
                                Transform.rotate(
                                  angle: relativeRotation,
                                  child: Icon(
                                    Icons.navigation_rounded,
                                    size: 72,
                                    color: _isDirectionLocked
                                        ? Colors.green
                                        : colors.onSurfaceVariant,
                                  ),
                                ),
                                if (_heading == null)
                                  Positioned(
                                    bottom: 10,
                                    child: Text(
                                      'Compass unavailable: showing north-based arrow',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isDirectionLocked
                          ? 'Qibla locked. Follow the green arrow.'
                          : (!_isFlatSurface
                                ? 'Place the phone on a flat horizontal surface.'
                                : ((_compassAccuracy != null &&
                                          _compassAccuracy! >
                                              _maxGoodCompassAccuracy)
                                      ? 'Compass needs calibration: move phone in a figure-8.'
                                      : 'Keep phone steady to lock Qibla accurately.')),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _startTracking,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh location'),
                        ),
                        if (_compassPausedForUnreliable) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: _retryCompassOnly,
                            icon: const Icon(Icons.explore_rounded),
                            label: const Text('Retry compass'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Find Qibla')),
      body: body,
    );
  }
}
