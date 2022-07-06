// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:getwidget/getwidget.dart';
import 'package:google_fonts/google_fonts.dart';

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
    if (!checked) {
      return const TextStyle(
        color: Colors.black,
        fontSize: 20,
      );
    }

    return const TextStyle(
      color: Colors.black,
      decoration: TextDecoration.lineThrough,
      fontSize: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: const ValueKey(0),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () => onTodoDeleted(todo)),
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
        leading: GFCheckbox(
          size: 25,
          type: GFCheckboxType.basic,
          activeBgColor: GFColors.DANGER,
          onChanged: (value) {
            onTodoChanged(todo);
          },
          value: todo.checked,
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

class _TodoListState extends State<TodoList> with TickerProviderStateMixin {
  final TextEditingController _textFieldController = TextEditingController();
  List<Todo> _todos = <Todo>[];
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);

  late SharedPreferences sharedPreferences;
  late TabController tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    _init();
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  generateList() {
    return Column(
      children: <Widget>[
        Text("Created task: ${_todos.length}"),
        Expanded(
          child: ListView.separated(
            itemCount: _todos.length,
            separatorBuilder: (_, __) => const Divider(),
            // padding: const EdgeInsets.symmetric(vertical: 5.0),
            itemBuilder: (context, index) {
              final todo = _todos[index];
              return TodoItem(
                todo: todo,
                onTodoChanged: _handleTodoChange,
                onTodoDeleted: _deleteTodoItem,
              );
            },
          ),
        )
      ],
    );
  }

  settingsMenu() {
    return SettingsList(
      sections: [
        SettingsSection(
          title: const Text('Common'),
          tiles: <SettingsTile>[
            SettingsTile.navigation(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              value: const Text('English'),
            ),
            SettingsTile.switchTile(
              onToggle: (value) {},
              initialValue: true,
              leading: const Icon(Icons.format_paint),
              title: const Text('Enable custom theme'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = <Widget>[
      _todos.isNotEmpty
          ? generateList()
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
      settingsMenu(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo List',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xffb388eb),
      ),
      bottomNavigationBar: GFTabBar(
        length: 3,
        tabBarHeight: 50,
        controller: tabController,
        indicatorColor: Colors.white,
        labelColor: Colors.white,
        tabBarColor: const Color(0xffb388eb),
        unselectedLabelColor: Colors.white.withOpacity(.60),
        tabs: const [
          Tab(
            icon: Icon(
              Icons.checklist_rounded,
              size: 20,
            ),
          ),
          Tab(
            icon: Icon(
              Icons.dashboard,
              size: 20,
            ),
          ),
          Tab(
            icon: Icon(
              Icons.settings,
              size: 20,
            ),
          ),
        ],
      ),
      body: GFTabBarView(controller: tabController, children: pages),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _currentIndex == 0 ? 1 : 0,
        child: FloatingActionButton(
            backgroundColor: Color(0xff8093f1),
            onPressed: () => _displayDialog(),
            tooltip: 'Add Item',
            child: const Icon(Icons.add)),
      ),
    );
  }

  void _handleTabSelection() {
    setState(() {
      _currentIndex = tabController.index;
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
    GFToast.showToast(
      'Task deleted!  ',
      context,
      toastPosition: GFToastPosition.BOTTOM,
      textStyle: const TextStyle(fontSize: 16, color: GFColors.DARK),
      backgroundColor: GFColors.LIGHT,
    );
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
                if (_textFieldController.text != "") {
                  _addTodoItem(_textFieldController.text);
                }
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
    return MaterialApp(
      title: 'Todo list',
      theme: ThemeData(textTheme: GoogleFonts.josefinSansTextTheme()),
      home: const TodoList(),
    );
  }
}

void main() {
  runApp(const TodoApp());
}
