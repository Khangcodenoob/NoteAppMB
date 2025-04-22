import '../model/Note.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';

class NoteDatabaseHelper {
  static final NoteDatabaseHelper instance = NoteDatabaseHelper._init();
  static Database? _database;

  NoteDatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          priority INTEGER,
          createdAt TEXT NOT NULL,
          modifiedAt TEXT NOT NULL,
          tags TEXT,
          color TEXT
        )
      ''');

    // Tạo sẵn dữ liệu mẫu
    await _insertSampleData(db);
  }

  // Phương thức chèn dữ liệu mẫu
  Future _insertSampleData(Database db) async {
    // Danh sách dữ liệu mẫu
    final List<Map<String, dynamic>> sampleNotes = [
      {
        'title': 'Lập trình Mobile',
        'content': 'Ứng dụng Notes cơ bản bằng Flutter và Dart',
        'priority': '3',
        'createdAt': DateTime.now().toIso8601String(),
        'modifiedAt': DateTime.now().toIso8601String(),
        'tags': 'Flutter,Mobile,Dart',
        'color': '#faebd7',
      },

    ];

    // Chèn từng note vào cơ sở dữ liệu
    for (final noteData in sampleNotes) {
      await db.insert('notes', noteData);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  /*
  instance: Singleton pattern đảm bảo chỉ có một instance của DatabaseHelper
  database: Getter trả về instance của Database, tạo mới nếu chưa tồn tại
  _initDB: Khởi tạo database với đường dẫn cụ thể
  _createDB: Tạo các bảng khi database được tạo lần đầu
  close: Đóng kết nối database
   */

  // Create - Thêm note mới
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // getAllNotes
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    print(maps);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // getNoteById
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // updateNote
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  // deleteNote
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // getNotesByPriority
  Future<List<Note>> getNotesByPriority() async {
    final db = await database;
    final result = await db.query(
        'notes',
        orderBy: 'priority ASC' // hoặc DESC tùy độ ưu tiên bạn muốn
    );
    return result.map((e) => Note.fromMap(e)).toList();
  }

  // searchNotes
  Future<List<Note>> searchNotes(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes', where: 'title LIKE ?', whereArgs: ['%$query%']);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

}