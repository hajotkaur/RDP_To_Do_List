import 'dart:ffi';
import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  //Create an empty list of maps which represent our tasks
  final List<Map<String, dynamic>> tasks = [];

  //Create a variable that captures the input of a text input
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  //Fetch tasks  from the db and also update the tasks list in memory
  Future<void> fetchTasks() async {
    final snapshots = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshots.docs.map(
          (doc) => {
            'id': doc.id,
            'name': doc['name'],
            'completed': doc.get('completed') ?? false,
          },
        ),
      );
    });
  }

  //function add new task to local state & firestore database
  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      //docRef gives us the insertion id from the document

      final docRef = await db.collection('tasks').add(newTask);

      //add the tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });
      nameController.clear();
    }
  }
   
   //update the completion status of the task in Firestore & locally
   Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index];
    await db
    .collection('tasks')
    .doc(task['id'])
    .update({'completed': completed});

    setState(() {
      tasks[index]['completed'] = completed;
    });
  }
  
  //delete the task from Firestore & locally
  Future<void> removeTasks(int index) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).delete();
    
    setState(() {
      tasks.removeAt(index);
    });
  }
} 
   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            Text(
              'RDP Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 340,
              child: TableCalendar(
                calendarFormat: CalendarFormat.month,
                focusedDay: DateTime.now(),
                firstDay: DateTime(2025),
                lastDay: DateTime(2026),
              ),
            ),
            Expanded(
              child: Container(
                child: buildAddTaskSection(nameController, addTask),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(),
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            maxLength: 32,
            controller: nameController,
            decoration: InputDecoration(
              labelText: ' Add Task',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(onPressed: addTask, child: Text('Add Task')),
      ],
    ),
  );
}

Widget buildTaskList(tasks) {
  return ListView.builder(
    physics: NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          task['completed'] ? Icons.check_box : Icons.check_circle_outlined
        ),
        title: Text(
          task['name'],
          style: TextStyle(
            decoration: task['completed'] ? TextDecoration.lineThrough : null,
            fontSize:22,
             ),
          ),
          trailing: Row(children: [
            Checkbox(),
            IconButton(),
           ],)
        );
    },
  );
}
