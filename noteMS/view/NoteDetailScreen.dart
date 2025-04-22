import 'dart:io';
import 'package:flutter/material.dart';
import '../db/NoteDatabaseHelper.dart';
import '../model/Note.dart';
//import 'EditNoteScreen.dart';
import 'package:app_03/noteMS/view/NoteFrom.dart';



class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  _NoteDetailScreenState createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Note note;

  @override
  void initState() {
    super.initState();
    note = widget.note;
  }

  Future<void> _refreshNote() async {
    if (note.id == null) {
      print('Note ID is null, cannot refresh');
      return;
    }

    final refreshed = await NoteDatabaseHelper.instance.getNoteById(note.id!);
    if (refreshed != null) {
      setState(() {
        note = refreshed;
      });
    } else {
      Navigator.pop(context); // Quay lại nếu ghi chú bị xoá
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Chi tiết Ghi chú'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),// icon chỉnh sửa
            onPressed: () async {
              final isUpdated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteForm(note: note),// trỏ đến màn hình chỉnh sửa ghi chú
                ),
              );

              if (isUpdated == true) {
                await _refreshNote();
                Navigator.pop(context, true); // Quay lại và báo là đã cập nhật
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiêu đề ghi chú
            Text(
              note.title,
              style: TextStyle(
                fontSize: 32,  // Tăng kích thước font tiêu đề
                fontWeight: FontWeight.bold,
                color: Colors.black87,  // Màu chữ dễ đọc
              ),
            ),
            SizedBox(height: 12), // Tăng khoảng cách giữa tiêu đề và nội dung

            // Nội dung ghi chú
            Text(
              'Nội dung:',
              style: TextStyle(
                fontSize: 26,  // Tăng kích thước font cho tiêu đề nội dung
                fontWeight: FontWeight.w800,
                color: Colors.black,  // Màu chữ nhạt hơn một chút
              ),
            ),

            SizedBox(height: 8),
            Text(
              note.content,
              style: TextStyle(
                fontSize: 20,  // Tăng kích thước font nội dung chính
                height: 1.5,  // Tăng chiều cao dòng để dễ đọc
                color: Colors.black87,  // Màu chữ dễ đọc
              ),
            ),
            SizedBox(height: 20), // Khoảng cách giữa nội dung và thời gian

            // Thời gian tạo và cập nhật
            Text(
              'Thời gian tạo: ${note.createdAt}',
              style: TextStyle(
                fontSize: 16,  // Kích thước vừa phải cho thời gian
                color: Colors.orange,  // Màu chữ nhẹ nhàng cho thời gian
              ),
            ),

            SizedBox(height: 8),  // Khoảng cách giữa thời gian tạo và thời gian cập nhật
            Text(
              'Thời gian cập nhật: ${note.modifiedAt}',
              style: TextStyle(
                fontSize: 16,  // Kích thước vừa phải cho thời gian
                color: Colors.orange,  // Màu chữ nhẹ nhàng cho thời gian
              ),
            ),

            SizedBox(height: 20), // Khoảng cách giữa thời gian và tags
            // Mức độ ưu tiên
            Text(
              'Mức độ ưu tiên: ${note.priority}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,  // Màu sắc nổi bật cho ưu tiên
              ),
            ),

            SizedBox(height: 20), // Khoảng cách giữa ưu tiên và tags
            // Tags nếu có
            if (note.tags!.isNotEmpty) ...[
              Text(
                'Tags:',
                style: TextStyle(
                  fontSize: 20,  // Kích thước font cho tiêu đề tags
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,  // Màu chữ dễ đọc
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: note.tags!.map((tag) => Chip(
                  label: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 16,  // Kích thước font của tag
                      color: Colors.white,  // Màu chữ trắng trong tag
                    ),
                  ),
                  backgroundColor: Colors.blue.shade100,  // Màu nền tag
                )).toList(),
              ),
            ],
          ],
        ),
      ),

    );
  }
}
