import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databasePath = join(await getDatabasesPath(), 'todo_database.db');
  await deleteDatabase(databasePath);

  final database = await openDatabase(
    join(await getDatabasesPath(), 'todo_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE todos(id INTEGER PRIMARY KEY, title TEXT, description TEXT, itemCount INTEGER, itemCountInterval INTEGER)',
      );
    },
    version: 1,
  );

  runApp(
    MaterialApp(
      title: 'Passing Data',
      home: TodosScreen(database: database),
    ),
  );
}

class Todo {
  final int id;
  String title;
  String description;
  int itemCount;
  int itemCountInterval;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.itemCount,
    required this.itemCountInterval,
  });

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    int? itemCount,
    int? itemCountInterval,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
      itemCountInterval: itemCountInterval ?? this.itemCountInterval,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'itemCount': itemCount,
      'itemCountInterval': itemCountInterval,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int? ?? 0,
      title: map['title'] as String,
      description: map['description'] as String,
      itemCount: map['itemCount'] as int? ?? 0,
      itemCountInterval: map['itemCountInterval'] as int? ?? 0,
    );
  }
}

class TodosScreen extends StatefulWidget {
  final Database database;

  const TodosScreen({Key? key, required this.database}) : super(key: key);

  @override
  _TodosScreenState createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  Future<void> _fetchTodos() async {
    final todos = await widget.database.query('todos');
    setState(() {
      _todos = todos.map((map) => Todo.fromMap(map)).toList();
    });
  }

  void _addTodo() async {
    final newTodo = await Navigator.push<Todo>(
      this.context,
      MaterialPageRoute(
        builder: (context) => AddTodoScreen(database: widget.database),
      ),
    );
    if (newTodo != null) {
      setState(() {
        _todos.add(newTodo);
      });
    }
  }

  void _updateTodo(Todo updatedTodo) async {
    await widget.database.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [updatedTodo.id],
    );
    setState(() {
      _todos = _todos.map((todo) {
        return todo.id == updatedTodo.id ? updatedTodo : todo;
      }).toList();
    });
  }

  void _deleteTodo(Todo todo) async {
    await widget.database.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    setState(() {
      _todos.remove(todo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
      ),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_todos[index].title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TodoDetailScreen(
                    todo: _todos[index],
                    database: widget.database,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TodoDetailScreen extends StatefulWidget {
  final Todo todo;
  final Database database;

  TodoDetailScreen({required this.todo, required this.database});

  @override
  _TodoDetailScreenState createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _itemCountController;
  late TextEditingController _itemCountIntervalController;
  late bool _editMode;

  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController =
        TextEditingController(text: widget.todo.description);
    _itemCountController =
        TextEditingController(text: widget.todo.itemCount.toString());
    _itemCountIntervalController =
        TextEditingController(text: widget.todo.itemCountInterval.toString());
    _editMode = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _itemCountController.dispose();
    _itemCountIntervalController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
    });
  }

  void _decreaseItemCount() {
    setState(() {
      widget.todo.itemCount -= widget.todo.itemCountInterval;
      _itemCountController.text = widget.todo.itemCount.toString();
    });
  }

  void _increaseItemCount() {
    setState(() {
      widget.todo.itemCount += widget.todo.itemCountInterval;
      _itemCountController.text = widget.todo.itemCount.toString();
    });
  }

  Future<void> _updateTodo() async {
    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
      itemCount: int.parse(_itemCountController.text),
      itemCountInterval: int.parse(_itemCountIntervalController.text),
    );

    await widget.database.update(
      'todos',
      updatedTodo.toMap(),
      where: 'id = ?',
      whereArgs: [updatedTodo.id],
    );

    setState(() {
      _todos = _todos.map((todo) {
        return todo.id == updatedTodo.id ? updatedTodo : todo;
      }).toList();
      _editMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Title:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _titleController,
              enabled: _editMode,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Description:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _descriptionController,
              enabled: _editMode,
              maxLines: 1,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Item Count:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _itemCountController,
              enabled: _editMode,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Item Count Interval:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _itemCountIntervalController,
              enabled: _editMode,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decreaseItemCount,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _increaseItemCount,
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ElevatedButton(
              onPressed: _editMode ? _updateTodo : _toggleEditMode,
              child: Text(_editMode ? 'Save' : 'Edit'),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTodoScreen extends StatefulWidget {
  final Database database;

  const AddTodoScreen({Key? key, required this.database}) : super(key: key);

  @override
  _AddTodoScreenState createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _itemCountController;
  late TextEditingController _itemCountIntervalController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _itemCountController = TextEditingController();
    _itemCountIntervalController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _itemCountController.dispose();
    _itemCountIntervalController.dispose();
    super.dispose();
  }

  void _addTodo() async {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      description: _descriptionController.text,
      itemCount: int.tryParse(_itemCountController.text) ?? 0,
      itemCountInterval: int.tryParse(_itemCountIntervalController.text) ?? 1,
    );
    await widget.database.insert('todos', newTodo.toMap());
    Navigator.pop(this.context, newTodo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Todo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextFormField(
              controller: _itemCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Item Count'),
            ),
            TextFormField(
              controller: _itemCountIntervalController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Item Count Interval'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addTodo,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
