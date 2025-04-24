import 'package:flutter/material.dart';
import '../model/Note.dart';
import '../db/NoteDatabaseHelper.dart';

class NoteForm extends StatefulWidget {
  final Note? note;

  const NoteForm({super.key, this.note});

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagInputController;
  late List<String> _tags;
  late int _priority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _tagInputController = TextEditingController();
    _tags = List.from(widget.note?.tags ?? []);
    _priority = widget.note?.priority ?? 3;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  //Hàm kiểm tra tag, nếu đa ton tai thi thong bao cho nguoi dung
  void _showTagExistsDialog({required String message}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Lỗi!"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Đã rõ"),
            ),
          ],
        );
      },
    );
  }

  //Hàm thêm tags
  void _addTag() {
    final tag = _tagInputController.text.trim();

    // Kiểm tra tag trống
    if (tag.isEmpty) {
      _showTagExistsDialog(message: "Tag không được để trống.");
      return;
    }

    // Giới hạn chỉ cho phép 2 tag
    if (_tags.length >= 2) {
      _showTagExistsDialog(message: "Chỉ được thêm tối đa 2 tag.");
      return;
    }

    // Kiểm tra nếu tag đã tồn tại
    if (_tags.contains(tag)) {
      _showTagExistsDialog(message: "Tag này đã có trong danh sách.");
      return;
    }

    setState(() {
      _tags.add(tag);
      _tagInputController.clear();
    });
  }

  //Hàm xoá tag
  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty) {
      if (_tags.isEmpty) _tags.add("Không có tags");
      final note = Note(
        id: widget.note?.id,
        title: _titleController.text,
        content: _contentController.text,
        priority: _priority,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
        tags: _tags,
        color: '#FFFFFF',
      );

      if (widget.note == null) {
        await NoteDatabaseHelper.instance.insertNote(note);
      } else {
        await NoteDatabaseHelper.instance.updateNote(note);
      }
      Navigator.pop(context, true);
    }
  }

  InputDecoration _inputDecoration(String label, Icon icon) => InputDecoration(
    labelText: label,
    prefixIcon: icon,
    filled: true,
    fillColor: Colors.grey[100],
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade700, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.8),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // -------------------Giao dien nguoi dung-------------------
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Sửa Ghi chú' : 'Thêm Ghi chú')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Tiêu đề', Icon(Icons.title)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: _inputDecoration('Nội dung', Icon(Icons.notes)),
              maxLines: 6,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagInputController,
                    decoration: _inputDecoration('Thêm tag', Icon(Icons.label)),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addTag,
                  icon: Icon(Icons.add),
                  label: Text(
                    "Thêm",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Làm chữ đậm
                      fontSize: 16, // Thay đổi kích thước chữ nếu cần
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    elevation: 10, // Độ nổi của nút
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children:
                  _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.shade100,
                          deleteIcon: Icon(Icons.cancel),
                          onDeleted: () => _removeTag(tag),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _priority,
              onChanged: (value) => setState(() => _priority = value ?? 3),
              decoration: _inputDecoration(
                'Mức độ ưu tiên',
                Icon(Icons.priority_high),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Cao')),
                DropdownMenuItem(value: 2, child: Text('Trung bình')),
                DropdownMenuItem(value: 3, child: Text('Thấp')),
              ],
            ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save, size: 24),
                    SizedBox(width: 8),
                    Text(
                      isEditing ? 'Sửa Ghi chú' : 'Thêm Ghi chú', // Đúng cấu trúc cho nút sửa và nút thêm ghi chú
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
