import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SpeedometerDashboard(),
  ));
}

class SpeedometerDashboard extends StatefulWidget {
  const SpeedometerDashboard({super.key});

  @override
  State<SpeedometerDashboard> createState() => _SpeedometerDashboardState();
}

class _SpeedometerDashboardState extends State<SpeedometerDashboard>
    with SingleTickerProviderStateMixin {
  double _speed = 0;
  double _displayedSpeed = 0;

  // NEW REPORT VARIABLES
  double _totalKilometers = 0;
  String _carIssue = "No issues detected";

  final AudioPlayer _enginePlayer = AudioPlayer();
  final AudioPlayer _actionPlayer = AudioPlayer();
  bool _engineRunning = false;

  late final AnimationController _controller;
  late Animation<double> _speedAnimation;

  Timer? _increaseTimer;
  Timer? _decreaseTimer;
  Timer? _kmTimer; // Kilometer tracker

  // Dashboard indicators
  bool _batteryOn = false;
  bool _handbrakeOn = false;
  bool _fuelLow = false;
  bool _headlightsOn = false;
  bool _leftIndicator = false;
  bool _rightIndicator = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _speedAnimation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {
          _displayedSpeed = _speedAnimation.value;
        });
      });
  }

  // Start engine
  Future<void> _startEngine() async {
    if (!_engineRunning) {
      setState(() {
        _engineRunning = true;
        _batteryOn = true;
        _handbrakeOn = true;
        _fuelLow = true;
        _headlightsOn = true;
        _leftIndicator = true;
        _rightIndicator = true;
      });

      // 1️⃣ Play engine start sound ONCE
      await _enginePlayer.setReleaseMode(ReleaseMode.stop);
      await _enginePlayer.play(AssetSource('sounds/volvo_engine.mp3'));

      // Wait until start sound finishes
      await _enginePlayer.onPlayerComplete.first;

      if (!_engineRunning) return; // Safety check

      // 2️⃣ Start main engine loop sound
      await _enginePlayer.setReleaseMode(ReleaseMode.loop);
      await _enginePlayer.play(AssetSource('sounds/volvo_engine2.mp3'));

      // Start KM counter
      _kmTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_speed > 0) {
          setState(() {
            _totalKilometers += _speed / 3600;
          });
        }
      });
    }
  }

  // Stop engine
  Future<void> _stopEngine() async {
    await _enginePlayer.stop();
    _kmTimer?.cancel();

    setState(() {
      _engineRunning = false;
      _batteryOn = false;
      _handbrakeOn = false;
      _fuelLow = false;
      _headlightsOn = false;
      _leftIndicator = false;
      _rightIndicator = false;
      _speed = 0;
      _displayedSpeed = 0;
    });
  }

  // Horn
  Future<void> _playActionSound() async {
    await _actionPlayer.play(AssetSource('sounds/volvo_horn.mp3'));
  }

  void _startIncreasingSpeed() {
    _increaseTimer?.cancel();
    _decreaseTimer?.cancel();
    _increaseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        if (_speed < 180) {
          _speed += 2;
          _checkIssues();
          _animateNeedle();
        }
      });
    });
  }

  void _stopIncreasingSpeed() {
    _increaseTimer?.cancel();
    _startDecreasingSpeed();
  }

  void _startDecreasingSpeed() {
    _decreaseTimer?.cancel();
    _decreaseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        if (_speed > 0) {
          _speed -= 2;
          if (_speed < 0) _speed = 0;
          _checkIssues();
          _animateNeedle();
        } else {
          _decreaseTimer?.cancel();
        }
      });
    });
  }

  void _animateNeedle() {
    _speedAnimation =
        Tween<double>(begin: _displayedSpeed, end: _speed).animate(_controller);
    _controller.forward(from: 0);
  }

  // Issue checker
  void _checkIssues() {
    if (_speed > 140) {
      _carIssue = "⚠ Overspeed Warning!";
    } else if (_fuelLow) {
      _carIssue = "⚠ Fuel Low!";
    } else if (_handbrakeOn && _speed > 0) {
      _carIssue = "⚠ Handbrake ON while driving!";
    } else {
      _carIssue = "No issues detected";
    }
  }

  Widget _buildIndicator(IconData icon, bool active, Color activeColor) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.black54,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  @override
  void dispose() {
    _increaseTimer?.cancel();
    _decreaseTimer?.cancel();
    _kmTimer?.cancel();
    _controller.dispose();
    _enginePlayer.dispose();
    _actionPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C1C1C), Color(0xFF4F4F4F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTapDown: (_) {
                if (_engineRunning) _startIncreasingSpeed();
              },
              onTapUp: (_) {
                if (_engineRunning) _stopIncreasingSpeed();
              },
              onTapCancel: () {
                if (_engineRunning) _stopIncreasingSpeed();
              },
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 180,
                    startAngle: 150,
                    endAngle: 30,
                    showTicks: true,
                    showLabels: true,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 30,
                      cornerStyle: CornerStyle.bothCurve,
                      color: Colors.black54,
                      thicknessUnit: GaugeSizeUnit.logicalPixel,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 100,
                        gradient: const SweepGradient(
                          colors: [Colors.greenAccent, Colors.green],
                        ),
                        startWidth: 30,
                        endWidth: 30,
                      ),
                      GaugeRange(
                        startValue: 100,
                        endValue: 140,
                        gradient: const SweepGradient(
                          colors: [Colors.yellowAccent, Colors.orange],
                        ),
                        startWidth: 30,
                        endWidth: 30,
                      ),
                      GaugeRange(
                        startValue: 140,
                        endValue: 180,
                        gradient: const SweepGradient(
                          colors: [Colors.redAccent, Colors.deepOrange],
                        ),
                        startWidth: 30,
                        endWidth: 30,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: _displayedSpeed,
                        needleLength: 0.8,
                        needleColor: Colors.redAccent,
                        needleStartWidth: 2,
                        needleEndWidth: 6,
                        knobStyle: const KnobStyle(
                          color: Colors.redAccent,
                          borderColor: Colors.white,
                          borderWidth: 3,
                          sizeUnit: GaugeSizeUnit.logicalPixel,
                          knobRadius: 12,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          _displayedSpeed.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(top: 80, left: 50, child: _buildIndicator(Icons.battery_full, _batteryOn, Colors.green)),
            Positioned(top: 80, right: 50, child: _buildIndicator(Icons.light_mode, _headlightsOn, Colors.yellow)),
            Positioned(bottom: 80, left: 50, child: _buildIndicator(Icons.local_gas_station, _fuelLow, Colors.orange)),
            Positioned(bottom: 80, right: 50, child: _buildIndicator(Icons.handshake, _handbrakeOn, Colors.red)),
            Positioned(left: 0, top: MediaQuery.of(context).size.height / 2 - 20,
                child: _buildIndicator(Icons.arrow_left, _leftIndicator, Colors.green)),
            Positioned(right: 0, top: MediaQuery.of(context).size.height / 2 - 20,
                child: _buildIndicator(Icons.arrow_right, _rightIndicator, Colors.green)),

            // Buttons
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _engineRunning ? null : _startEngine,
                    child: const Text("Start Engine"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _engineRunning ? _stopEngine : null,
                    child: const Text("Stop Engine"),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _playActionSound,
                    child: const Text("Horn"),
                  ),
                  const SizedBox(width: 20),

                  // NEW REPORT BUTTON
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarReportScreen(
                            totalKm: _totalKilometers,
                            engineOn: _engineRunning,
                            issue: _carIssue,
                            currentSpeed: _displayedSpeed,
                          ),
                        ),
                      );
                    },
                    child: const Text("Report"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SEPARATE REPORT SCREEN =================

class CarReportScreen extends StatelessWidget {
  final double totalKm;
  final bool engineOn;
  final String issue;
  final double currentSpeed;

  const CarReportScreen({
    super.key,
    required this.totalKm,
    required this.engineOn,
    required this.issue,
    required this.currentSpeed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Report"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reportItem("Engine Status", engineOn ? "ON" : "OFF"),
            _reportItem("Total Kilometers Driven", "${totalKm.toStringAsFixed(2)} km"),
            _reportItem("Current Speed", "${currentSpeed.toInt()} km/h"),
            _reportItem("Car Issues", issue),
          ],
        ),
      ),
    );
  }

  Widget _reportItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            Text(value, style: const TextStyle(color: Colors.cyanAccent)),
          ],
        ),
      ),
    );
  }
}
