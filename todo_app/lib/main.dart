import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// =====================
// MODEL
// =====================
class Task {
  final int? id;
  final String title;
  final String priority;
  final String dueDate;
  final bool isDone;

  Task({
    this.id,
    required this.title,
    required this.priority,
    required this.dueDate,
    this.isDone = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      priority: json['priority'],
      dueDate: json['due_date'],
      isDone: json['is_done'].toString() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "priority": priority,
      "due_date": dueDate,
      "is_done": isDone.toString(),
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? priority,
    String? dueDate,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}

// =====================
// API SERVICE
// =====================
class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api/tasks";

  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception("Failed to load tasks: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error adding task: $e");
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    if (task.id == null) return false;
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(task.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating task: $e");
      return false;
    }
  }

  Future<bool> deleteTask(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting task: $e");
      return false;
    }
  }
}

// =====================
// UI COMPONENTS
// =====================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Task>> _tasksFuture;
  List<Task> _tasks = [];
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'active', 'completed'

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _isLoading = true;
      _tasksFuture = _apiService.getTasks();
      _tasksFuture
          .then((tasks) {
            setState(() {
              _tasks = tasks;
              _isLoading = false;
            });
          })
          .catchError((error) {
            setState(() {
              _isLoading = false;
            });
            _showErrorSnackBar("Failed to load tasks: $error");
          });
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final updatedTask = task.copyWith(isDone: !task.isDone);
    final success = await _apiService.updateTask(updatedTask);

    if (success) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      });
      _showSuccessSnackBar(
        updatedTask.isDone
            ? "Task marked as completed"
            : "Task marked as active",
      );
    } else {
      _showErrorSnackBar("Failed to update task status");
    }
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) return;

    final success = await _apiService.deleteTask(task.id!);
    if (success) {
      setState(() {
        _tasks.removeWhere((t) => t.id == task.id);
      });
      _showSuccessSnackBar("Task deleted successfully");
    } else {
      _showErrorSnackBar("Failed to delete task");
    }
  }

  List<Task> _getFilteredTasks() {
    switch (_filter) {
      case 'active':
        return _tasks.where((task) => !task.isDone).toList();
      case 'completed':
        return _tasks.where((task) => task.isDone).toList();
      case 'all':
      default:
        return _tasks;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: 'Refresh Tasks',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter Tasks',
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All Tasks')),
                  const PopupMenuItem(
                    value: 'active',
                    child: Text('Active Tasks'),
                  ),
                  const PopupMenuItem(
                    value: 'completed',
                    child: Text('Completed Tasks'),
                  ),
                ],
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filteredTasks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _filter == 'all'
                          ? 'No tasks available'
                          : _filter == 'active'
                          ? 'No active tasks'
                          : 'No completed tasks',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Task'),
                      onPressed: () => _showAddEditTaskDialog(context),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: filteredTasks.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return _buildTaskItem(task);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditTaskDialog(context),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final formattedDate = _formatDueDate(task.dueDate);
    final DateTime dueDateTime = DateTime.parse(task.dueDate);
    final bool isOverdue = dueDateTime.isBefore(DateTime.now()) && !task.isDone;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _showAddEditTaskDialog(context, task: task),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _deleteTask(task),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getPriorityColor(task.priority).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Checkbox(
              value: task.isDone,
              onChanged: (_) => _toggleTaskStatus(task),
              shape: const CircleBorder(),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? Colors.grey : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getPriorityColor(task.priority),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey,
                        fontWeight:
                            isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 4),
                      const Text(
                        "OVERDUE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildTaskOptions(task),
                );
              },
            ),
            onTap: () => _toggleTaskStatus(task),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskOptions(Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(
              task.isDone ? 'Mark as incomplete' : 'Mark as complete',
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleTaskStatus(task);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit task'),
            onTap: () {
              Navigator.pop(context);
              _showAddEditTaskDialog(context, task: task);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete task',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
          ),
        ],
      ),
    );
  }

  String _formatDueDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y • HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _showAddEditTaskDialog(
    BuildContext context, {
    Task? task,
  }) async {
    final isEditing = task != null;
    final titleController = TextEditingController(
      text: isEditing ? task.title : '',
    );
    String priority = isEditing ? task.priority : 'medium';

    // Parse date and time if editing
    DateTime selectedDate =
        isEditing
            ? DateTime.parse(task.dueDate)
            : DateTime.now().add(const Duration(days: 1));

    TimeOfDay selectedTime =
        isEditing
            ? TimeOfDay(
              hour: DateTime.parse(task.dueDate).hour,
              minute: DateTime.parse(task.dueDate).minute,
            )
            : TimeOfDay.now();

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Edit Task' : 'Add New Task'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        minLines: 1,
                      ),
                      const SizedBox(height: 16),
                      const Text('Priority:'),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'low', label: Text('Low')),
                          ButtonSegment(value: 'medium', label: Text('Medium')),
                          ButtonSegment(value: 'high', label: Text('High')),
                        ],
                        selected: {priority},
                        onSelectionChanged: (Set<String> selection) {
                          setState(() {
                            priority = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(
                          DateFormat('EEEE, MMM d, y').format(selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Time'),
                        subtitle: Text(selectedTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedTime = pickedTime;
                              selectedDate = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a task title'),
                          ),
                        );
                        return;
                      }

                      final formattedDate = DateFormat(
                        'yyyy-MM-dd HH:mm:ss',
                      ).format(selectedDate);

                      final newTask =
                          isEditing
                              ? task.copyWith(
                                title: titleController.text.trim(),
                                priority: priority,
                                dueDate: formattedDate,
                              )
                              : Task(
                                title: titleController.text.trim(),
                                priority: priority,
                                dueDate: formattedDate,
                              );

                      Navigator.pop(context);

                      setState(() {
                        _isLoading = true;
                      });

                      bool success;
                      if (isEditing) {
                        success = await _apiService.updateTask(newTask);
                        if (success) {
                          setState(() {
                            final index = _tasks.indexWhere(
                              (t) => t.id == task.id,
                            );
                            if (index != -1) {
                              _tasks[index] = newTask;
                            }
                            _isLoading = false;
                          });
                          _showSuccessSnackBar('Task updated successfully');
                        } else {
                          setState(() {
                            _isLoading = false;
                          });
                          _showErrorSnackBar('Failed to update task');
                        }
                      } else {
                        success = await _apiService.addTask(newTask);
                        if (success) {
                          _refreshTasks();
                          _showSuccessSnackBar('Task added successfully');
                        } else {
                          setState(() {
                            _isLoading = false;
                          });
                          _showErrorSnackBar('Failed to add task');
                        }
                      }
                    },
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
