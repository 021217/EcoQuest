import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'stepConversion.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StepCounter extends StatefulWidget {
  @override
  _StepCounterState createState() => _StepCounterState();
}

class _StepCounterState extends State<StepCounter> {
  int _steps = 0;
  int _points = 0;
  int _bonusPoints = 0;
  bool todayFirstLogin = false;
  int _baseSteps = 0;
  int _yesterdaySteps = 0;
  String status = "Checking sensor...";
  late Stream<StepCount> _stepCountStream;

  @override
  void initState() {
    super.initState();
    //_checkSensor();
    _initPedometerState();
    _scheduleMidnightReset();
  }

  void _scheduleMidnightReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now);
    //final durationUntilMidnight = Duration(seconds: 15);  //testing

    Timer(durationUntilMidnight, () async {
      final prefs = await SharedPreferences.getInstance();
      todayFirstLogin = true; // Reset flag

      prefs.setInt('yesterdaySteps', _steps);

      prefs.remove(
        'lastLoginDate',
      ); // Remove so it reinitializes on next step event
      _initPedometerState(); // Re-run setup to capture new base steps
      _scheduleMidnightReset(); // Schedule again for next day
    });
  }

  // void _checkSensor() {
  //   Pedometer.stepCountStream.listen(
  //         (event) {
  //       setState(() {
  //         status = "Sensor working! Steps: ${event.steps}";
  //       });
  //     },
  //     onError: (error) {
  //       setState(() {
  //         status = "Sensor not available: $error";
  //       });
  //     },
  //   );
  // }
  //
  // void _initPedometerState() async{
  //   //var status = await Permission.activityRecognition.status;
  //   var permissionStatus = await Permission.activityRecognition.status;
  //   if(!permissionStatus.isGranted){
  //    await Permission.activityRecognition.request();
  //   }
  //
  //   _stepCountStream = Pedometer.stepCountStream;
  //   _stepCountStream.listen(
  //     _onStepCount,
  //     onError: _onStepCountError,
  //     cancelOnError: true,
  //   );
  // }
  void _initPedometerState() async {
    final prefs = await SharedPreferences.getInstance();
    _yesterdaySteps = prefs.getInt('yesterdaySteps') ?? 0;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? lastLoginDate = prefs.getString('lastLoginDate');
    int savedBaseSteps = prefs.getInt('baseSteps') ?? 0;

    if (lastLoginDate != today) {
      todayFirstLogin = true;
      prefs.setString('lastLoginDate', today);
    } else {
      todayFirstLogin = false;
      _baseSteps = savedBaseSteps;
    }

    var permissionStatus = await Permission.activityRecognition.status;
    if (!permissionStatus.isGranted) {
      await Permission.activityRecognition.request();
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(
      (event) {
        _onStepCount(event);
        setState(() {
          status = "Sensor working! Steps: ${event.steps}";
        });
      },
      onError: (error) {
        _onStepCountError(error);
        setState(() {
          status = "Sensor not available: $error";
        });
      },
      cancelOnError: true,
    );
  }

  void _onStepCount(StepCount event) async {
    debugPrint('Step Count Event Triggered: ${event.steps}');
    final prefs = await SharedPreferences.getInstance();

    if (todayFirstLogin) {
      _baseSteps = event.steps;
      await prefs.setInt('baseSteps', _baseSteps);
      todayFirstLogin = false;
    }
    /*else {
      _steps = event.steps - _baseSteps;
    }*/

    int todaySteps = event.steps - _baseSteps;
    final result = StepConversion.convertSteps(todaySteps < 0 ? 0 : todaySteps);

    setState(() {
      _steps = result.steps;
      _points = result.points;
      _bonusPoints = result.bonusPoints;
    });
  }

  void _onStepCountError(error) {
    debugPrint('Step Count Error: $error');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('EcoQuest Step Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text('Steps Today: $_steps', style: TextStyle(fontSize: 24)),
            Text(
              'Points: ${_points + _bonusPoints}',
              style: TextStyle(fontSize: 20),
            ),

            Text('Status: $status', style: TextStyle(fontSize: 20)),

            Text(
              'Yesterday: $_yesterdaySteps steps',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
