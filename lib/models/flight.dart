import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';

class Flight {
  static final flightInputFormatter = DateFormat("yyyy-MM-dd");
  static final flightOutputFormatter =
      DateFormat("EEEE d 'de' MMMM, yyyy", "es_ES");

  final String uuid, name, description;
  final DateTime date;
  final int processingTime;
  final double progress;
  final FlightState state;
  final String camera;
  final bool deleted;

  Flight(
      {this.uuid,
      this.name,
      this.description,
      this.date,
      this.processingTime,
      this.state,
      this.progress,
      this.camera,
      this.deleted});

  factory Flight.fromMap(Map<String, dynamic> json) {
    return Flight(
      uuid: json["uuid"],
      name: json['name'],
      description: json['annotations'],
      date: flightInputFormatter.parse(json["date"]),
      processingTime: max(json["processing_time"] ~/ 1000,
          (json["nodeodm_info"]["processingTime"] ?? 0) ~/ 1000),
      state: FlightState.values
          .firstWhere((e) => e.toString() == 'FlightState.' + json["state"]),
      progress: double.parse(
          (json["nodeodm_info"]["progress"]?.toDouble() ?? 0.0)
              .toStringAsFixed(2)),
      camera : json['camera'],
      deleted: json['deleted']
    );
  }

  static List<Flight> parseList(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Flight>((json) => Flight.fromMap(json)).toList();
  }

  String humanizedProcessingTime() => _humanize(this.processingTime);

  String humanizeTimeLeft() {
    final timeLeft = (processingTime / (progress / 100) - processingTime).round();
    return _humanize(timeLeft);
  }

  String _humanize(int seconds) {
    var hours = seconds ~/ (60 * 60);
    var minutes = (seconds - hours * 60 * 60) ~/ 60;
    return "$hours h, $minutes min";
  }
}

enum FlightState { WAITING, PROCESSING, COMPLETE, ERROR, CANCELED }

enum Camera { RGB, MICASENSE }

class CameraHelper {
  static String description(Camera c) =>
      {Camera.RGB: "RGB", Camera.MICASENSE: "Micasense"}[c];

  static String toJson(Camera c) =>
      {Camera.RGB: "RGB", Camera.MICASENSE: "MICASENSE"}[c];
}
