import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Todo {
  final int id;
  final String title;
  final String description;

  Todo({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    join(await getDatabasesPath(), 'todo_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT)',
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

class TodosScreen extends StatefulWidget {
  final Database database;

  TodosScreen({required this.database});

  @override
  _TodosScreenState createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  List<Todo> todos = [];

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  void fetchTodos() async {
    final List<Map<String, dynamic>> maps =
        await widget.database.query('todos');

    setState(() {
      todos = List.generate(
        maps.length,
        (index) {
          return Todo(
            id: maps[index]['id'],
            title: maps[index]['title'],
            description: maps[index]['description'],
          );
        },
      );
    });
  }

  void addTodo() async {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'New Todo',
      description: 'A description for the new todo',
    );

    await widget.database.insert(
      'todos',
      newTodo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos'),
      ),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(todos[index].title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(todo: todos[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTodo,
        child: Icon(Icons.add),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final Todo todo;

  DetailScreen({required this.todo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(todo.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(todo.description),
      ),
    );
  }
}
