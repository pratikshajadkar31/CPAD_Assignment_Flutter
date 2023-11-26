import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'cFn0zIvlvrijeJ2E2aJSPGU2LQ846Fg9bxrMxrNy';
  final keyClientKey = 'PiHCZeeyCMYUoz21OJNcEK1equgI0BEAi0ylRQje';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(home: Task()));
}

class Task extends StatefulWidget {
  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  //bool showTaskFields = false;
  bool showCompletedTasks = false;
  Future<void> updateTaskStatus(String id, bool status) async {
    var task = ParseObject('Task')
      ..objectId = id
      ..set('status', status);
    await task.save();
  }
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd,\nyyyy\nhh:mm');
    final originalDateFormat = DateFormat('MMM dd, yyyy hh:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text("To-do list App"),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
         // if (showTaskFields)

        //  if (showTaskFields)
          Container(
            padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 0.0),
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.purpleAccent,
                    minimumSize: Size(150, 40),
                  ),
                  onPressed: () => _showAddTaskBottomSheet(context),
                  child: Text("Add Task"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    minimumSize: Size(242, 40),
                  ),
                  onPressed: () => _showFilterDialog(context),
                  child: Text("Filter Tasks"),
                ),
              ],

            ),
          ),
        //  if (showTaskFields)
          Expanded(
            child: FutureBuilder<List<ParseObject>>(
              future: getTask(),
              builder: (context, snapshot) {

                // Filter tasks based on status
                List<ParseObject> tasks = snapshot.data ?? [];
                if (showCompletedTasks) {
                  tasks = tasks.where((task) => task.get<bool>('status') == true).toList();
                } else {
                  tasks = tasks.where((task) => task.get<bool>('status') == false).toList();
                }


                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
                        ),
                      ),
                    );
                  default:
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error..."),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Center(
                        child: Text("No Data..."),
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.only(top: 10.0),
                        itemCount: tasks.length,
                        //itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          //*************************************
                          //Get Parse Object Values
                          final varTask = snapshot.data![index];
                          final varTitle = varTask.get<String>('name')!;
                          final varContent = varTask.get<String>('description')!;
                          final varStatus = varTask.get<bool>('status')!;
                          final varDate = dateFormat.format(varTask.get<DateTime>('updatedAt')!);
                          final varOriginalDate = originalDateFormat.format(varTask.get<DateTime>('updatedAt')!);
                          //*************************************

                          return ListTile(
                            title: Text(varTitle),
                            subtitle: Text(varContent),
                            isThreeLine: true,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetails(varTitle, varContent, varOriginalDate, varStatus),
                              ),
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: varStatus,
                                  activeColor: Colors.deepPurple,
                                  onChanged: (value) async {
                                    await updateTask(varTask.objectId!, value!);

                                    setState(() {
                                      // Refresh UI
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.done,
                                    color: Colors.green,
                                  ),
                                  onPressed: () async {
                                    await updateTaskStatus(varTask.objectId!, true); // Set status to "Completed"
                                    setState(() {
                                      // Refresh UI
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.pending_actions,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    await updateTaskStatus(varTask.objectId!, false); // Set status to "Pending"


                                    setState(() {
                                      //Refresh UI
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                  ),
                                  onPressed: () async {
                                    await deleteTask(varTask.objectId!);
                                    setState(() {
                                      final snackBar = SnackBar(
                                        content: Text("Task Deleted Successfully!"),
                                        duration: Duration(seconds: 2),
                                      );
                                      ScaffoldMessenger.of(context)
                                        ..removeCurrentSnackBar()
                                        ..showSnackBar(snackBar);
                                    });
                                  },
                                )
                              ],
                            ),
                          );
                        },
                      );
                    }
                }
              },
            ),
          ),
        ],
      ),

    );
  }

  Future<void> saveTaskToParse(String title, String content) async {
    final task = ParseObject('Task')
      ..set('name', title)
      ..set('description', content)
      ..set('status', false);
    await task.save();
  }

  Future<List<ParseObject>> getTask() async {
    QueryBuilder<ParseObject> queryTask = QueryBuilder<ParseObject>(ParseObject('Task'));
    final ParseResponse apiResponse = await queryTask.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> updateTask(String id, bool status) async {
    var task = ParseObject('Task')
      ..objectId = id
      ..set('status', status);
    await task.save();
  }

  Future<void> deleteTask(String id) async {
    var task = ParseObject('Task')..objectId = id;
    await task.delete();
  }

  void _showAddTaskBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                "Add Task",
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Task Title",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Task Content",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await saveTaskToParse(titleController.text, contentController.text);
                  setState(() {
                    titleController.clear();
                    contentController.clear();
                  });
                },
                child: Text("Save Task"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter Tasks"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // Handle completed tasks filter
                  setState(() {
                    showCompletedTasks = true;
                  });
                  Navigator.pop(context);
                },
                child: Text("Completed Tasks"),
              ),
              ElevatedButton(
                onPressed: () {
                  // Handle pending tasks filter
                  setState(() {
                    showCompletedTasks = false;
                  });
                  Navigator.pop(context);
                },
                child: Text("Pending Tasks"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TaskDetails extends StatefulWidget {
  final String varTitle;
  final String varContent;
  final String varOriginalDate;
  final bool varStatus;

  TaskDetails(this.varTitle, this.varContent, this.varOriginalDate, this.varStatus);

  @override
  _TaskDetailsState createState() => _TaskDetailsState(varTitle, varContent, varOriginalDate, varStatus);
}

class _TaskDetailsState extends State<TaskDetails> {
  final String varTitle;
  final String varContent;
  final String varOriginalDate;
  final bool varStatus;

  _TaskDetailsState(this.varTitle, this.varContent, this.varOriginalDate, this.varStatus);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Task Details"),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 18.0),
        child: Column(
          children: <Widget>[
            Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 18.0),
                  child: Text(
                    varTitle,
                    style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1.0),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 18.0),
                  width: 500,
                  child: Text(varContent),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 18.0),
                  width: 500,
                  child: Text(
                    varOriginalDate,
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(18.0, 8.0, 18.0, 18.0),
                  width: 500,
                  child: Text(
                    varStatus ? "Status: DONE" : "Status: Pending",
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
