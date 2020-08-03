import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'api.dart';

import 'drawer.dart';
import 'models/user.dart';

abstract class AbstractUersWidget extends StatefulWidget {
  static const routeName = "declare on child classes";
  static String textFilter = '';

  String routeNameFunc();
}

abstract class AbstractUsersState extends State<AbstractUersWidget> {
  Future<List<User>> Function() usersFutureCallable;
  Future<List<User>> usersFuture;
  StreamController<List<User>> _usersStream;
  List<User> users;
  String appTitle;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    usersFuture = usersFutureCallable();
    _usersStream = StreamController<List<User>>();
    _loadUsers();
    super.initState();
  }

  void _loadUsers() async {
    users = await usersFutureCallable();
    if (AbstractUersWidget.textFilter != '') {
      _usersStream.add(users
          .where((u) =>
              u.username.toLowerCase().indexOf(AbstractUersWidget.textFilter) >
                  -1 ||
              u.email.toLowerCase().indexOf(AbstractUersWidget.textFilter) > -1)
          .toList());
    } else {
      _usersStream.add(users);
    }
  }

  void showToast(message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text(appTitle),
        ),
        drawer: AppDrawer(),
        body: StreamBuilder<List<User>>(
          stream: _usersStream.stream,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Text(
                snapshot.error.toString(),
                style: TextStyle(color: Colors.red),
              );
            if (snapshot.hasData && snapshot.data.isNotEmpty) {
              return RefreshIndicator(
                  onRefresh: () async => _loadUsers(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final user = snapshot.data[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.white70, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        color: Colors.lightBlue[50],
                        margin: EdgeInsets.all(20.0),
                        shadowColor: Colors.amberAccent,
                        child: ListTile(
                          leading: Icon(
                            Icons.account_circle,
                            size: 60,
                          ),
                          title: Text('${user.username}\n\n'),
                          subtitle: Text("Email: " +
                              '${user.email}' +
                              "\n\n" +
                              "Descripción: El usuario aun no ha sido aceptado\n\n"),
                          trailing: Wrap(spacing: 0, children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.check_circle),
                              color: Colors.green,
                              tooltip: "Aceptar",
                              onPressed: () async => {_action(user, 'Aceptar')},
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel),
                              color: Colors.red,
                              tooltip: "Rechazar",
                              onPressed: () async =>
                                  {_action(user, 'Rechazar')},
                            ),
                            IconButton(
                              icon: Icon(Icons.block,
                                  color: Colors.red, semanticLabel: "Bloquear"),
                              tooltip: "bloquear",
                              onPressed: () async => {
                                _action(user, 'Bloquear'),
                              },
                            ),
                          ]),
                        ),
                      );
                    },
                  ));
            } else if (snapshot.hasData && snapshot.data.isEmpty)
              return RefreshIndicator(
                  onRefresh: () async => _loadUsers(),
                  child:
                      Center(child: Text("No hay ${appTitle.toLowerCase()}")));
            else
              return Center(child: CircularProgressIndicator());
          },
        ),
        bottomSheet: TextFormField(
          decoration: InputDecoration(
              hintText: "Ingrese la busqueda..",
              icon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () async => _loadUsers(),
              )),
          onSaved: (val) => AbstractUersWidget.textFilter = val.trim(),
        ));
  }

  Future<void> _action(User user, String action) async {
    var message = '';
    var type = '';
    if (action != 'Aceptar') {
      if (action == 'Bloquear') {
        message = 'Bloqueada';
      } else {
        message = "Eliminada";
      }
      type = 'DELETED';
      return AwesomeDialog(
        context: context,
        animType: AnimType.BOTTOMSLIDE,
        dialogType: DialogType.WARNING,
        title: '¿Realmente quiere ' + action + " la solicitud?",
        desc: 'La solicitud de ' + user.username + " va a ser " + message,
        btnCancelText: "Cancelar",
        btnCancelOnPress: () {},
        btnOkText: "Continuar",
        btnOkOnPress: () async => helper(user, type),
      ).show();
    } else {
      type = "ACTIVE";
      helper(user, type);
    }
    _loadUsers();
  }

  helper(User user, type) {
    showToast(Api.updateTypeUser(user.pk.toString(), type).toString());
  }
}
