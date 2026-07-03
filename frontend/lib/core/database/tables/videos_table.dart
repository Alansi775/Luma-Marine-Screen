import 'package:drift/drift.dart';

/// Local cache of the shared video catalog (mirrors the `videos/{videoId}`
/// Firestore collection — see backend/schema/firestore-schema.md). Only
/// videos referenced by the active playlist need to be present here.
@DataClassName('VideoRow')
class Videos extends Table {
  TextColumn get id => text()(); // matches the Firestore videoId
  TextColumn get storagePath => text()(); // Firebase Storage object path
  TextColumn get checksum => text().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get localFilePath => text().nullable()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
