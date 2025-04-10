import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

// create the HomePage screen using stateful widget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db =
      FirebaseFirestore.instance; //use instance for acessing Firestore database
  final TextEditingController nameController =
      TextEditingController(); //controller for capturing user input for task name
  final List<Map<String, dynamic>> tasks = []; //  list to store tasks locally

  @override
  void initState() {
    super.initState();
    fetchTasks(); // load tasks from Firestore when the widget initializes
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear(); //clear local task list before adding fetched tasks
      tasks.addAll(
        snapshot.docs.map(
          (doc) => {
            'id':
                doc.id, //document id used for updating or deleting tasks in Firestore
            'name': doc.get('name'), //Task name
            'completed': doc.get('completed') ?? false, //Task completion status
          },
        ),
      );
    });
  }

  //Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    final taskName =
        nameController.text.trim(); // Get input and trim whitespace

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(), //Timestamp for sorting tasks
      };

      //docRef gives us the insertion id of the task from the database
      final docRef = await db.collection('tasks').add(newTask);

      //Adding tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });
      nameController.clear(); //clear input field after adding task
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index];
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    setState(() {
      tasks[index]['completed'] = completed; //update local task status
    });
  }

  //Delete the task locally & in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index];

    await db
        .collection('tasks')
        .doc(task['id'])
        .delete(); //delete from firestore

    setState(() {
      tasks.removeAt(index); //remove locally
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Image.asset('assets/rdplogo.png', height: 80),
            ), //insert the logolink to image
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2025),
                    lastDay: DateTime(2026),
                  ),
                  //Build dyanamic list of tasks
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),
          //Add task button and section to input field
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(),
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32,
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Add Task',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          //Elevated button for adding tasks
          ElevatedButton(
            onPressed: addTask, //Call Add tasks when pressed
            child: Text('Add Task'),
          ),
        ],
      ),
    ),
  );
}

//Widget that displays the task item on the UI
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap:
        true, //Makes the listview that works inside Singlechild scrollview
    physics: const NeverScrollableScrollPhysics(), //prevent inner scroll
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      final isEven = index % 2 == 0; // Alternate colors for list items

      return Padding(
        padding: EdgeInsets.all(1.0),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor:
              isEven
                  ? Colors.blue
                  : Colors.green, // Alternate colors for list items
          leading: Icon(
            task['completed'] ? Icons.check_circle : Icons.circle_outlined,
          ),
          title: Text(
            task['name'],
            style: TextStyle(
              decoration: task['completed'] ? TextDecoration.lineThrough : null,
              fontSize: 22,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Checkbox to mark task as completed
              Checkbox(
                value: task['completed'],
                onChanged:
                    (value) => updateTask(
                      index,
                      value!,
                    ), //update task status when checkbox is toggled
              ),
              IconButton(
                icon: Icon(Icons.delete), //Delete button to remove task
                onPressed:
                    () =>
                        removeTasks(index), //remove task when button is pressed
              ),
            ],
          ),
        ),
      );
    },
  );
}
