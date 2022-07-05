// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class Todo {
  Todo({required this.name, required this.checked});
  final String name;
  bool checked;

  Todo.fromMap(Map map)
      : name = map['name'],
        checked = map['checked'];

  Map toMap() {
    return {
      'name': name,
      'checked': checked,
    };
  }
}

class TodoItem extends StatelessWidget {
  TodoItem({
    required this.todo,
    required this.onTodoChanged,
    required this.onTodoDeleted,
  }) : super(key: ObjectKey(todo));

  final Todo todo;
  final Function onTodoDeleted;
  final Function onTodoChanged;

  TextStyle? _getTextStyle(bool checked) {
    if (!checked) return null;

    return const TextStyle(
      color: Colors.black54,
      decoration: TextDecoration.lineThrough,
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return ListTile(
  //     onTap: () {
  //       onTodoChanged(todo);
  //     },
  //     leading: CircleAvatar(
  //       child: Text(todo.name[0]),
  //     ),
  //     title: Text(todo.name, style: _getTextStyle(todo.checked)),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: const ValueKey(0),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {}),
        children: <Widget>[
          SlidableAction(
            onPressed: (BuildContext context) {
              onTodoDeleted(todo);
            },
            backgroundColor: const Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        onTap: () {
          onTodoChanged(todo);
        },
        leading: CircleAvatar(
          child: Text(todo.name[0]),
        ),
        title: Text(todo.name, style: _getTextStyle(todo.checked)),
      ),
    );
  }
}

class TodoList extends StatefulWidget {
  const TodoList({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _TodoListState createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  _TodoListState() {
    _init();
  }

  int _selectedIndex = 0;
  final TextEditingController _textFieldController = TextEditingController();
  List<Todo> _todos = <Todo>[];
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  late SharedPreferences sharedPreferences;

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = <Widget>[
      _todos.isNotEmpty
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: _todos.map((Todo todo) {
                return TodoItem(
                  todo: todo,
                  onTodoChanged: _handleTodoChange,
                  onTodoDeleted: _deleteTodoItem,
                );
              }).toList(),
            )
          : const Center(
              child: Text(
              'Nothing To Do',
              style: optionStyle,
            )),
      const Center(
          child: Text(
        'Hello you see the Tab Dashboard',
        style: optionStyle,
      )),
      const Center(
          child: Text(
        'Hello you see the Tab Settings',
        style: optionStyle,
      )),
    ];
    return Scaffold(
      appBar: AppBar(
          title: const Text('Todo List App'),
          backgroundColor: Colors.purple[600]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.purple[600],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[400],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Todo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      body: pages.elementAt(_selectedIndex),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _selectedIndex == 0 ? 1 : 0,
        child: FloatingActionButton(
            onPressed: () => _displayDialog(),
            tooltip: 'Add Item',
            child: const Icon(Icons.add)),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void saveData() {
    List<String> spList =
        _todos.map((item) => json.encode(item.toMap())).toList();
    sharedPreferences.setStringList('list', spList);
  }

  void _init() async {
    sharedPreferences = await SharedPreferences.getInstance();
    List<String> spList = sharedPreferences.getStringList('list') ?? [];
    setState(() {
      _todos = spList.map((item) => Todo.fromMap(json.decode(item))).toList();
    });
  }

  void _handleTodoChange(Todo todo) {
    setState(() {
      todo.checked = !todo.checked;
    });
    saveData();
  }

  _deleteTodoItem(Todo todo) {
    setState(() {
      _todos.remove(todo);
    });
    saveData();
  }

  void _addTodoItem(String name) {
    setState(() {
      _todos.add(Todo(name: name, checked: false));
    });
    _textFieldController.clear();
    saveData();
  }

  Future<void> _displayDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a new todo item'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(hintText: 'Type your new todo'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop();
                _addTodoItem(_textFieldController.text);
              },
            ),
          ],
        );
      },
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Todo list',
      home: TodoList(),
    );
  }
}

void main() {
  runApp(const TodoApp());
}
