import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import '../db/NoteDatabaseHelper.dart';
import '../model/Note.dart';
//import '../view/AddNoteScreen.dart';
//import '../view/EditNoteScreen.dart';
import '../view/NoteDetailScreen.dart';
import 'package:app_03/noteMS/view/NoteFrom.dart';

class NoteListScreen extends StatefulWidget {
  @override
  _NoteListScreenState createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  late Future<List<Note>> _notesFuture; // Danh sách ghi chú dạng Future
  bool isGridView = false; // Biến xác định kiểu hiển thị
  final TextEditingController searchController = TextEditingController();
  final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  Future<void> _refreshNotes() async {
    setState(() {
      _notesFuture = NoteDatabaseHelper.instance.getNotesByPriority();
    });
  }

  void _toggleView() {
    setState(() {
      isGridView = !isGridView;
    });
  }

  void _searchNotes(String query) {
    if (query.isEmpty) {
      _refreshNotes();
    } else {
      setState(() {
        _notesFuture = NoteDatabaseHelper.instance.searchNotes(query);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ghi chú của bạn'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _refreshNotes),
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Tìm kiếm ghi chú...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchNotes,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Note>>(
              future: _notesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Không có ghi chú nào.'));
                } else {
                  return isGridView
                      ? _buildGridView(snapshot.data!)
                      : _buildListView(snapshot.data!);
                }
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NoteForm()),
          );
          if (result == true) _refreshNotes();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.greenAccent ,
      ),
    );
  }

  // Hiển thị dạng danh sách
  Widget _buildListView(List<Note> notes) {
    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: notes.length,
      separatorBuilder: (_, __) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          color: _getPriorityColor(note.priority),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(note.title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(note.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text('Tạo: ${formatter.format(DateTime.parse(note.createdAt.toString()))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                Text('Sửa: ${formatter.format(DateTime.parse(note.modifiedAt.toString()))}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                // Thêm phần tag vào đây
                Row(
                  children: [
                    Text("Tags: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    if (note.tags?.isNotEmpty ?? false)
                      ...note.tags!.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.shade200,
                        ),
                      )).toList()
                    else
                      Chip(
                        label: Text('Không có tags'),
                        backgroundColor: Colors.grey.shade300,
                      ),
                  ],
                ),
              ],
            ),
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
              );
              if (updated == true) _refreshNotes();
            },
            trailing: _buildTrailingButtons(note),
          ),
        );
      },
    );
  }

  // Hiển thị dạng lưới
  Widget _buildGridView(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return GestureDetector(
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
            );
            if (updated == true) _refreshNotes();
          },
          child: Container(
            decoration: BoxDecoration(
              color: _getPriorityColor(note.priority),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                SizedBox(height: 6),
                Text(note.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                Spacer(),
                Text('Tạo: ${formatter.format(DateTime.parse(note.createdAt.toString()))}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                Text('Sửa: ${formatter.format(DateTime.parse(note.modifiedAt.toString()))}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                // Thêm phần tag vào đây
                Row(
                  children: [
                    Text("Tags: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    if (note.tags?.isNotEmpty ?? false)
                      ...note.tags!.map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Chip(
                          label: Text(tag),
                          backgroundColor: Colors.blue.shade200,
                        ),
                      )).toList()
                    else
                      Chip(
                        label: Text('Không có tags'),
                        backgroundColor: Colors.grey.shade300,
                      ),
                  ],
                ),
                Align(alignment: Alignment.bottomRight, child: _buildTrailingButtons(note)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tạo hai nút chỉnh sửa và xoá
  Widget _buildTrailingButtons(Note note) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue.shade500),
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteForm(note: note)),
            );
            if (updated == true) _refreshNotes();
          },
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red.shade800),
          onPressed: () => _confirmDelete(note),
        ),
      ],
    );
  }

  // Hiển thị hộp thoại xác nhận xoá
  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận xoá'),
        content: Text('Bạn chắc chắn muốn xoá ghi chú này?'),
        actions: [
          TextButton(child: Text('Huỷ'), onPressed: () => Navigator.pop(context)),
          TextButton(
            child: Text('Xoá'),
            onPressed: () async {
              await NoteDatabaseHelper.instance.deleteNote(note.id!);
              _refreshNotes();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Đổi màu theo mức độ ưu tiên
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red.shade300;
      case 2:
        return Colors.orange.shade300;
      case 3:
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}
