import 'package:drift/drift.dart';

/// Local cache of the active device playlist (mirrors
/// `devices/{deviceId}/playlist/{entryId}` in Firestore — see
/// backend/schema/firestore-schema.md). Ordering is explicit via
/// [sortOrder] rather than list position, since it must survive
/// out-of-order sync updates. ("order" is a reserved SQL keyword, hence
/// the name.)
@DataClassName('PlaylistEntryRow')
class PlaylistEntries extends Table {
  TextColumn get id => text()();
  TextColumn get videoId => text()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
