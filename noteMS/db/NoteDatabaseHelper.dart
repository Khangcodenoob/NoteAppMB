import '../model/Note.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';

class NoteDatabaseHelper {
  static final NoteDatabaseHelper instance = NoteDatabaseHelper._init();
  static Database? _database;

  NoteDatabaseHelper._init(); // Constructor chỉ khai báo 1 lần
  Future<Database> get database async {
    if (_database != null)
      return _database!; //Kiểm tra xem database có được khởi tạo chưa
    _database = await _initDB('notes.db'); //Nếu chưa khởi tạo thì khởi tạo
    return _database!;
  }

  // Khởi tạo database: tạo file, xác định đường dẫn
  Future<Database> _initDB(String filePath) async {
    final dbPath =
        await getDatabasesPath(); // Lấy đường dẫn thư mục chứa database
    final path = join(dbPath, filePath); // Ghép đường dẫn thư mục + tên file

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Hàm tạo bảng khi database được tạo lần đầu tiên
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

  // Đóng kết nối database khi không cần dùng nữa
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
  //-------------------------------CRUD----------------------------------------------------------------------

  // Create - Thêm note mới
  Future<int> insertNote(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // getAllNotes - - Lấy tất cả ghi chú
  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    print(maps);
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  // getNoteById - Lấy ghi chú theo ID
  Future<Note?> getNoteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    }
    return null;
  }

  // updateNote - Cập nhật ghi chú
  Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // deleteNote - Xoá ghi chú
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // getNotesByPriority - Lấy các ghi chú theo độ ưu tiên tăng dần
  Future<List<Note>> getNotesByPriority() async {
    final db = await database;
    final result = await db.query(
      'notes',
      orderBy: 'priority ASC', // hoặc DESC tùy độ ưu tiên bạn muốn
    );
    return result.map((e) => Note.fromMap(e)).toList();
  }

  // searchNotes
  Future<List<Note>> searchNotes(String keyword) async {
    final db = await database;
    int? priority;

    // mức độ ưu tiên sẽ tương ứng nếu keyword trùng khớp
    switch (keyword.toLowerCase()) {
      case 'cao':
        priority = 1;
        break;
      case 'trung bình':
      case 'trungbinh':
      case 'tb':
        priority = 2;
        break;
      case 'thấp':
      case 'thap':
        priority = 3;
        break;
      default:
        final parsed = int.tryParse(keyword);
        if ([1, 2, 3].contains(parsed)) priority = parsed;
    }

    // Base điều kiện tìm kiếm
    String whereClause = 'title LIKE ? OR content LIKE ? OR tags LIKE ?';
    List<dynamic> whereArgs = ['%$keyword%', '%$keyword%', '%$keyword%'];

    // Nếu có độ ưu tiên khớp
    if (priority != null) {
      whereClause += ' OR priority = ?';
      whereArgs.add(priority);
    }

    // Nếu keyword có dạng ngày/tháng
    final dateRegex = RegExp(
      r'^\d{4}(-\d{2}){0,2}$',
    ); // yyyy hoặc yyyy-MM hoặc yyyy-MM-dd
    if (dateRegex.hasMatch(keyword)) {
      whereClause += ' OR createdAt LIKE ? OR modifiedAt LIKE ?';
      whereArgs.add('%$keyword%');
      whereArgs.add('%$keyword%');
    }

    final maps = await db.query(
      'notes',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'priority ASC',
    );

    return maps.map((e) => Note.fromMap(e)).toList();
  }
}
