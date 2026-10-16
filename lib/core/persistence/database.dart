import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'database.g.dart';

class Projects extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get backup => text().nullable()();
  DateTimeColumn get modified => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Projects, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase(File file) : super(NativeDatabase.createInBackground(file));
  AppDatabase.memory() : super(NativeDatabase.memory());
  @override
  int get schemaVersion => 1;
}
