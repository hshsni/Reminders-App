import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:reminders/Pages/map_page.dart';
import 'package:reminders/Utils/MyDrawer.dart';

import '../Utils/Task.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSigningOut = false;
  String chosenDate = '', filter = 'all';
  late User _currentUser;
  double rating = 0;

  @override
  void initState() {
    _currentUser = widget.user;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference tasks = FirebaseFirestore.instance
        .collection('Users')
        .doc(_currentUser.uid)
        .collection('Tasks');

    final DocumentReference documentReference =
        FirebaseFirestore.instance.collection('Users').doc(_currentUser.uid);

    documentReference.set({'name': _currentUser.displayName});

    return Scaffold(
      drawer: MyDrawer(user: _currentUser),
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          GestureDetector(
            child: const Icon(Icons.filter_list),
            onTap: () async {
              DateTime? selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selectedDate == null) {
                setState(() {
                  filter = 'all';
                });
              } else {
                DateTime date = DateTime.parse(selectedDate.toString());
                var formattedDate = "${date.day}-${date.month}-${date.year}";

                setState(() {
                  filter = formattedDate;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            'NAME: ${_currentUser.displayName}',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          Text(
            'EMAIL: ${_currentUser.email}',
            style: Theme.of(context).textTheme.bodyText1,
          ),
          _isSigningOut
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isSigningOut = true;
                    });
                    await FirebaseAuth.instance.signOut();
                    setState(() {
                      _isSigningOut = false;
                    });
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
          StreamBuilder(
            builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
              if (streamSnapshot.hasData) {
                return Expanded(
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot documentSnapshot =
                            streamSnapshot.data!.docs[index];
                        if (filter == "all" ||
                            documentSnapshot["date"] == filter) {
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                ListTile(
                                  trailing: Container(
                                    height: 100,
                                    width: 120,
                                    child: Row(
                                      children: <Widget>[
                                        for (int i = 0;
                                            i < documentSnapshot['rating'];
                                            i++)
                                          const Center(
                                            child:  Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  // IconButton(
                                  //   icon: const Icon(Icons.star),
                                  //   onPressed: () {
                                  //     var docId = documentSnapshot.reference;
                                  //     taskRating(docId);
                                  //   },
                                  // ),
                                  title: Text(documentSnapshot['description'] +
                                      '  (' +
                                      documentSnapshot['rating'].toString() +
                                      '/5)'),
                                  subtitle: Text(documentSnapshot['date']),
                                ),
                                Center(
                                    child: TextButton(
                                        onPressed: () {
                                          var docId =
                                              documentSnapshot.reference;
                                          taskRating(docId);
                                        },
                                        child: const Text('Rate')))
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                      itemCount: streamSnapshot.data!.docs.length),
                );
              }
              return const Center(child: Text("No tasks for this date yet"));
            },
            stream: tasks.orderBy('date', descending: true).snapshots(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future taskRating(DocumentReference reference) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Rating'),
        content: RatingBar.builder(
            updateOnDrag: true,
            minRating: 1,
            itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
            onRatingUpdate: (rating) {
              setState(() {
                this.rating = rating;
              });
            }),
        actions: [
          TextButton(
              onPressed: () {
                reference.update({'rating': rating});
                rating = 0;
                if (!mounted) return;
                return Navigator.of(context).pop();
              },
              child: const Text('Submit'))
        ],
      ),
    );
  }

  Future openDialog(BuildContext context) {
    final descTextController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Add a task'),
                controller: descTextController,
              ),
              ElevatedButton(
                onPressed: () async {
                  DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (selectedDate == null) {
                    return;
                  } else {
                    DateTime date = DateTime.parse(selectedDate.toString());
                    var formattedDate =
                        "${date.day}-${date.month}-${date.year}";

                    setState(() {
                      chosenDate = formattedDate;
                    });
                  }
                },
                child: const Text('Select Date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // DateTime date = DateTime.parse(DateTime.now().toString());
              // var formattedDate = "${date.day}-${date.month}-${date.year}";
              final CollectionReference tasks = FirebaseFirestore.instance
                  .collection('Users')
                  .doc(_currentUser.uid)
                  .collection('Tasks');
              TaskClass newTask = TaskClass(
                  description: descTextController.text,
                  uid: _currentUser.uid,
                  date: chosenDate,
                  rating: rating);
              await tasks.doc().set(newTask.toJson());
              if (!mounted) return;
              // var docId = documentSnapshot.reference;
              // docId.update({'rating': rating});
              // rating = 0;
              return Navigator.of(context).pop();
            },
            child: const Text('Submit'),
          )
        ],
      ),
    );
  }
}
