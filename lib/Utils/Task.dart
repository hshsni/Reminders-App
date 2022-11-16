import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class TaskClass {
  final String uid;
  final String description;
  final String date;
  double rating=0;

  TaskClass({required this.uid, required this.description, required this.date,required this.rating});

  factory TaskClass.fromJson(Map<String, dynamic> json) => _taskFromJson(json);

  Map<String, dynamic> toJson() => _taskToJson(this);

  @override
  String toString() => 'Description <$description>';

  Map<String,dynamic> gpsValues(Position position,int gpsCount){
    var latitude=position.latitude;
    var longitude=position.longitude;

    return {
      'gpsPositions': FieldValue.arrayUnion([
        {
          'latitude': latitude,
          'longitude':longitude
        }
      ]),
      'gpsCount':gpsCount
    };
  }
}

TaskClass _taskFromJson(Map<String, dynamic> json) {
  return TaskClass(
    uid: json['uid'] as String,
    description: json['description'] as String,
    date: json['date'] as String,
    rating: json['rating'] as double
  );
}

// 2
Map<String, dynamic> _taskToJson(TaskClass instance) => <String, dynamic>{
      'uid': instance.uid,
      'description': instance.description,
      'date': instance.date,
      'rating':instance.rating
    };

