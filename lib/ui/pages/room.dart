import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sushi_room/models/room.dart';
import 'package:sushi_room/models/partecipant.dart';
import 'package:sushi_room/services/internal_api.dart';
import 'package:sushi_room/services/rooms_api.dart';
import 'package:sushi_room/ui/components/hero_dialog.dart';
import 'package:sushi_room/ui/pages/room/final_order.dart';
import 'package:sushi_room/ui/pages/room/order.dart';
import 'package:sushi_room/ui/pages/room/room_landing.dart';

class RoomPage extends StatefulWidget {
  final String roomId;
  const RoomPage({
    super.key,
    required this.roomId,
  });

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  RoomsAPI roomsAPI = RoomsAPI();
  InternalAPI internalAPI = Get.find<InternalAPI>();

  bool passwordNeeded = true;

  List<Partecipant> localUsers = [];
  int currentUser = 0;

  String roomName = 'Loading...';

  @override
  void initState() {
    checkPassword();
    super.initState();
  }

  @override
  void dispose() {
    if (!passwordNeeded) {
      for (var element in localUsers) {
        removeUser(widget.roomId, element.uid);
      }
    }

    super.dispose();
  }

  Future<void> checkPassword() async {
    Room room = await roomsAPI.getRoom(widget.roomId);
    setState(() {
      roomName = room.name;
      passwordNeeded = room.password != null && room.creator != FirebaseAuth.instance.currentUser!.uid;
    });

    if (passwordNeeded) {
      String password = '';
      bool showText = false;
      Get.dialog(
        StatefulBuilder(
          builder: (context, localSetState) => AlertDialog(
            title: const Text("Insert room password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: !showText,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Password',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    password = value;
                  },
                ),
                CheckboxListTile(
                  title: const Text("Show password"),
                  value: showText,
                  onChanged: (value) {
                    localSetState(() {
                      showText = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(
                    closeOverlays: true,
                  );
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  if (password == room.password) {
                    Get.back();
                    addCurrentUser(widget.roomId);
                    setState(() {
                      passwordNeeded = false;
                    });
                  } else {
                    if (!Get.isSnackbarOpen) {
                      Get.snackbar(
                        "Wrong password",
                        "Please try again",
                        snackPosition: SnackPosition.BOTTOM,
                        colorText: Theme.of(context).colorScheme.onError,
                        backgroundColor: Theme.of(context).colorScheme.error,
                      );
                    }
                  }
                },
                child: const Text("Confirm"),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } else {
      addCurrentUser(widget.roomId);
    }
  }

  removeUser(roomId, userId) async {
    Partecipant user = Partecipant(
      uid: userId,
      name: "",
    );

    await roomsAPI.removeUser(roomId, user);
  }

  addCurrentUser(roomId) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    String name = internalAPI.currentUserName;

    Partecipant user = Partecipant(
      uid: uid,
      name: name,
    );

    localUsers.add(user);
    await roomsAPI.addUser(roomId, user);
  }

  Widget customDialog() {
    return Hero(
      tag: 'a',
      child: StatefulBuilder(
        builder: (context, localSetState) => AlertDialog(
          title: const Text("Select user"),
          scrollable: true,
          content: Column(
            children: [
              SizedBox(
                width: 400,
                height: 150,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView(
                    children: [
                      for (var user in localUsers)
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : "",
                            ),
                          ),
                          title: user.name.isNotEmpty
                              ? Text(user.name)
                              : TextField(
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Name',
                                  ),
                                  onChanged: (text) {
                                    user.name = text;
                                  },
                                ),
                          onTap: user.name.isNotEmpty
                              ? () {
                                  Get.back();
                                  setState(() {
                                    currentUser = localUsers.indexOf(user);
                                  });
                                }
                              : null,
                          trailing: (user.uid != null && user.uid == FirebaseAuth.instance.currentUser?.uid)
                              ? null
                              : user.name.isEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        roomsAPI.addUser(widget.roomId, user);
                                        localSetState(() {});
                                      },
                                      icon: const Icon(Icons.check_outlined),
                                    )
                                  : IconButton(
                                      onPressed: () {
                                        if (user.name.isNotEmpty) removeUser(widget.roomId, user.uid);
                                        if (localUsers.indexOf(user) == currentUser) currentUser = 0;

                                        localSetState(() {
                                          localUsers.remove(user);
                                        });
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close_outlined),
                                    ),
                        ),
                    ],
                  ),
                ),
              ),
              FilledButton.tonal(
                onPressed: localUsers.any((element) => element.name.isEmpty)
                    ? null
                    : () {
                        Partecipant user = Partecipant(
                          name: "",
                        );

                        localSetState(() {
                          localUsers.add(user);
                        });
                      },
                child: const Text("Add User"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget circleUserAvatar() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          HeroDialogRoute(
            builder: (context) {
              return customDialog();
            },
          ),
        );
      },
      child: Hero(
        tag: 'a',
        child: CircleAvatar(
          child: Text(
            localUsers[currentUser].name.substring(0, 1).toUpperCase(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text("Leave room"),
                  content: const Text("Are you sure you want to leave this room?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      child: const Text("Confirm"),
                    ),
                  ],
                ),
              );
            },
          ),
          title: Text(roomName),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Room"),
              Tab(text: "Order"),
              Tab(text: "Final Order"),
            ],
          ),
          actions: !passwordNeeded
              ? [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: circleUserAvatar(),
                  ),
                ]
              : null,
        ),
        body: !passwordNeeded
            ? TabBarView(
                children: [
                  RoomLanding(
                    roomId: widget.roomId,
                  ),
                  OrderPage(
                    roomId: widget.roomId,
                    currentUser: localUsers[currentUser],
                  ),
                  FinalOrderPage(
                    roomId: widget.roomId,
                    currentUser: localUsers[currentUser],
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
