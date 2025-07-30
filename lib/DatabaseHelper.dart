import 'dart:io';
import 'dart:core';

import 'package:aws_client/lex_models_v2_2020_08_07.dart';
import 'package:kribadostore/AppTheme.dart';
import 'package:kribadostore/Buttons.dart';
import 'package:kribadostore/DataSingleton.dart';
import 'package:kribadostore/MetaDetails.dart';
import 'package:kribadostore/models/autologin.dart';
import 'package:kribadostore/models/database_models/camp_plan_data.dart';
import 'package:kribadostore/models/division_details_response.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'Camp.dart';
import 'Doctor.dart';
import 'Resources.dart';
import 'UserMr.dart';

class DatabaseHelper {
  static final _databaseName = "abhishek_db2";
  static final _databaseVersion = 5;

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  late Database _database;

  Future<void> initializeDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE userMr (
      mr_code TEXT,
      subscriber_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE doctors (
        country_code TEXT,
        state_code TEXT,
        city_code TEXT,
        area_code TEXT,
        doc_code TEXT ,
        doc_name TEXT,
        doc_speciality TEXT,
        div_id INTEGER,
        dr_id TEXT UNIQUE,
        dr_consent INTEGER,
        doctor_meta TEXT
        

      )
    ''');

    await db.execute('''
  CREATE TABLE camps (
 camp_id TEXT,
  camp_date TEXT,
  test_date TEXT,
  test_start_time TEXT,
  test_end_time TEXT,
  created_at TEXT,
  scale_id TEXT,
  test_score DOUBLE,
  interpretation TEXT,
  language TEXT,
  
  pat_age TEXT,
  pat_gender TEXT,
  pat_email TEXT,
  pat_mobile TEXT,
  pat_name TEXT,
  pat_id TEXT,
  patient_consent INTEGER,
  dr_consent INTEGER,

  division_id INTEGER,
  
  answers TEXT,
  
  subscriber_id TEXT,
  doc_speciality TEXT,
  mr_code TEXT,
  
  country_code TEXT,
  state_code TEXT,
  city_code TEXT,
  area_code TEXT,
  doc_code TEXT,
  doc_name TEXT,
  dr_id TEXT,
   doctor_meta TEXT,
   patient_meta TEXT
  )
''');

    //to store division details
    await db.execute('''
      CREATE TABLE resources (
        user_id TEXT,
        division_detail TEXT,
        scales_list TEXT,
        s3_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE divisiondetail (
        user_id TEXT,
        division_detail TEXT,
        scales_list TEXT,
        s3_json TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE campPlanDetail (
        camp_plan_data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE allDetails (
        details TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE themes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme_color TEXT,
        text_color TEXT
      )
    ''');


    await db.execute('''
      CREATE TABLE buttons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        print_btn TEXT,
        download_btn TEXT,
        print_download_btn TEXT
      )
    ''');


    await db.execute('''
      CREATE TABLE metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qr_url TEXT,
        qr_label
      )
    ''');



  //  print('Database created successfully');
  }

  Future<int> insertUser(UserMr userMr) async {
    return await _database.insert('userMr', userMr.toMap());
  }

  Future<int> insertDoctor(Doctor doctors) async {
    return await _database.insert('doctors', doctors.toMap());
  }

  Future<int> insertCamp(Camp camps) async {
    return await _database.insert('camps', camps.toMap());
  }

  Future<int> insertResources(Resources resources) async {
    return await _database.insert('resources', resources.toMap());
  }


  //camp plan list module

  Future<int> insertCampPlanDetail(CampPlanData campPlanData) async {
    return await _database.insert('campPlanDetail', campPlanData.toMap());
  }

  Future<int> updateCampPlanDetail(String newCount) async {
    final Database db = await _database;
    return await db.update(
      'campPlanDetail',
      {'camp_plan_data': newCount}, // Key-value pair for the column to update
      where: '1=1', // Since this table has only one row, you can use a condition that always matches
    );
  }

  Future<int> doesCampPlanDetailExist() async {
    final Database db = await _database;
    // Query to count rows in the camps_report_count table
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM campPlanDetail');
    // If the count is greater than 0, return 1; otherwise, return 0
    return (Sqflite.firstIntValue(result) ?? 0) > 0 ? 1 : 0;
  }

  Future<List<Map<String, dynamic>>> getAllCampPlanListData() async {
    final Database db = await _database;
    return await db.query('campPlanDetail');
  }


  //camp plan list module

  Future<int> insertDivisiondetail(Resources resources) async {
    print('@@## divisiondetail table Insert successfully');
    return await _database.insert('divisiondetail', resources.toMap());

  }

  Future<void> insertTheme(AppTheme theme) async {
    final db = await _database;
    await db.insert(
      'themes',
      theme.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<void> insertMeta(MetaDetails metaDetails) async {
    final db = await _database;
    await db.insert(
      'metadata',
      metaDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertButton(Buttons buttons) async {
    final db = await _database;
    await db.insert(
      'buttons',
      buttons.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  Future<int> allDetails(AutoLoginResp resources) async {
    return await _database.insert('allDetails', resources.toMap());
  }

  Future<void> updateDivisiondetailField(
      String id, String fieldName, String newValue) async {
    final Database db = await _database;

    await db.update(
      'divisiondetail',
      {fieldName: newValue},
      where: 'user_id = ?',
      whereArgs: [id],
    );
  }

  // Future<List<Map<String, dynamic>>> getAlldoctors1(int divisionId) async {
  //   final Database db = await _database;
  //   return await db.query('doctors', where: 'div_id = ?', whereArgs: [divisionId]);
  // }

  Future<List<Map<String, dynamic>>> getAlldoctors1(int divisionId) async {
    final Database db = await _database;
    try {
      return await db
          .query('doctors', where: 'div_id = ?', whereArgs: [divisionId]);
    } catch (e) {
      // Handle SQLite exceptions, e.g., duplicate doc_code
      //print('Error querying doctors: $e');
      return [];
      // Return an empty list or handle as needed
    }
  }

  Future<List<Map<String, dynamic>>> getAlldoctors() async {
    final Database db = await _database;
    //return await db.query('doctors');
    //return await db.query('SELECT * FROM doctors ORDER BY doc_name DESC');
    return db.query(
        'doctors',
        orderBy: "doc_name ASC"
    );
  }

  Future<void> updateDoctorField(
      String id, String fieldName, int newValue) async {
    final Database db = await _database;

    await db.update(
      'doctors',
      {fieldName: newValue},
      where: 'dr_id = ?',
      whereArgs: [id],
    );
  }


  Future<void> updateDoctorTable(
      String id,
      String country_code,
      String state_code,
      String city_code,
      String area_code,
      String doc_code,
      String doc_name,
      String doc_speciality,
      int division_id,
      String encoded,
      int dr_consent,
      String jsonstringmap
      ) async {
    final Database db = await _database;

    await db.update(
      'doctors',
      {
        'country_code': country_code,
        'state_code': state_code,
        'city_code': city_code,
        'area_code': area_code,
        'doc_code': doc_code,
        'doc_name': doc_name,
        'doc_speciality': doc_speciality,
        'div_id': division_id,
        'dr_id': encoded,
        'dr_consent': dr_consent,
        'doctor_meta': jsonstringmap
      },
      where: 'dr_id = ?',
      whereArgs: [id],
    );
  }


  Future<int> doesDoctorExist(String drId) async {
    final Database db = await _database;
    final result =
        await db.query('doctors', where: 'dr_id = ?', whereArgs: [drId]);
    return result.isNotEmpty ? 1 : 0;
  }



  Future<int> doesDivisionsDetailsExist(String drId) async {
    final Database db = await _database;
    final result = await db
        .query('divisiondetail', where: 'user_id = ?', whereArgs: [drId]);
    return result.isNotEmpty ? 1 : 0;
  }

  Future<List<Map<String, dynamic>>> getAllcamps() async {
    final Database db = await _database;
    return await db.query('camps');
  }

  Future<List<Map<String, dynamic>>> getAllusers() async {
    final Database db = await _database;
    return await db.query('userMr');
  }

  Future<List<Map<String, dynamic>>> getAllresources() async {
    final Database db = await _database;
    return await db.query('resources');
  }

  Future<List<Map<String, dynamic>>> getAllDivisiondetail() async {
    final Database db = await _database;


    final result = await db.query(
       'divisiondetail',
        limit: 1
    );

    return result;
   // return await db.query('divisiondetail');
  }

  Future<List<Map<String, dynamic>>> getTheme() async {
    final Database db = await _database;
    return await db.query('themes');
  }

  Future<List<Map<String, dynamic>>> getMetaData() async {
    final Database db = await _database;
    return await db.query('metadata');
  }

  Future<List<Map<String, dynamic>>> getButtons() async {
    final Database db = await _database;
    return await db.query('buttons');
  }

  Future<void> updateTheme(AppTheme theme) async {
    final db = await _database;
    await db.update(
      'themes',
      theme.toMap(),
      where: 'id = ?',
      whereArgs: [1], // Assuming there is only one theme with ID 1
    );
  }


  Future<void> updateMetaData(MetaDetails metaData) async {
    final db = await _database;
    await db.update(
      'metadata',
      metaData.toMap(),
      where: 'id = ?',
      whereArgs: [1], // Assuming there is only one theme with ID 1
    );
  }


  Future<void> updateButtons(Buttons buttons) async {
    final db = await _database;
    await db.update(
      'buttons',
      buttons.toMap(),
      where: 'id = ?',
      whereArgs: [1], // Assuming there is only one theme with ID 1
    );
  }


  Future<bool> themeExists() async {
    final db = await _database;
    final result = await db.query('themes');
    return result.isNotEmpty;
  }

  Future<bool> metaDataExists() async {
    final db = await _database;
    final result = await db.query('metadata');
    return result.isNotEmpty;
  }

  Future<bool> buttonExists() async {
    final db = await _database;
    final result = await db.query('buttons');
    return result.isNotEmpty;
  }




  Future<void> clearDivisionDetailTable() async {
    final Database db = _database;
    await db.delete('divisiondetail');
    print('@@## divisiondetail table cleared successfully');
  }

   clearDivisionDetail_Table() async {
    final Database db = _database;
    print('@@## divisiondetail table cleared successfully');
    await db.delete('divisiondetail');

  }

  Future<void> clearCampsTable() async {
    final Database db = await _database;
    await db.delete('camps');
    //print('Camps table cleared successfully');
  }

  Future<void> clearUsersTable() async {
    final Database db = await _database;
    await db.delete('userMr');
    print('#########Users table cleared successfully');
  }

  Future<void> clearDoctorsTable() async {
    final Database db = await _database;
    await db.delete('doctors');
   // print('doctors table cleared successfully');
  }

  Future<int> getCampsCount() async {
    final Database db = await _database;
    final List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT COUNT(*) as count FROM camps');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count;
  }

  Future<List<Map<String, dynamic>>> getAlldoctorsByCode(String doc_code) async {
    final Database db = await _database;
    try {
      return await db
          .query('doctors', where: 'doc_code = ?', whereArgs: [doc_code]);
    } catch (e) {
      // Handle SQLite exceptions, e.g., duplicate doc_code
      //print('Error querying doctors: $e');
      return [];
      // Return an empty list or handle as needed
    }
  }
}
