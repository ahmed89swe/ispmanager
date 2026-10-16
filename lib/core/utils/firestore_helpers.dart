import 'package:cloud_firestore/cloud_firestore.dart';

DateTime tsToDate(dynamic v) {
  if (v == null) return DateTime.now();
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  return DateTime.now();
}

T? enumFromName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name == name) return v;
  }
  return null;
}
