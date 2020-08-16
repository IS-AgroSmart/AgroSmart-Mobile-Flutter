import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'api.dart';

import 'drawer.dart';
import 'models/user.dart';

abstract class AbstractUersWidget extends StatefulWidget {
  static const routeName = "declare on child classes";

  String routeNameFunc();
}

abstract class AbstractUsersState extends State<AbstractUersWidget> {
  Future<List<User>> Function() usersFutureCallable;
  Future<List<User>> usersFuture;
  StreamController<List<User>> _usersStream;
  List<User> users;
  String appTitle;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String textFilter = '';

  @override
  void initState() {
    usersFuture = usersFutureCallable();
    _usersStream = StreamController<List<User>>();
    _loadUsers();
    super.initState();
  }

  void _loadUsers() async {
    users = await usersFutureCallable();
    if (textFilter.isNotEmpty) {
      _usersStream.add(users
          .where((u) =>
              u.username.toLowerCase().indexOf(textFilter) > -1 ||
              u.email.toLowerCase().indexOf(textFilter) > -1)
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
        backgroundColor: Colors.blueGrey[200],
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
              var _context = context;
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
                          title: Text('${user.username}'),
                          subtitle: Text("Email: " +
                              '${user.email}' +
                              "\n\n" +
                              "Descripción: El usuario aun no ha sido aceptado\n\n"),
                          trailing: Wrap(spacing: 0, children: <Widget>[
                            IconButton(
                              key: Key("accept-icon-${user.pk}"),
                              icon: Icon(Icons.check_circle),
                              color: Colors.green,
                              tooltip: "Aceptar",
                              onPressed: () async =>
                                  {_action(user, 'Aceptar', _context)},
                            ),
                            IconButton(
                              key: Key("reject-icon-${user.pk}"),
                              icon: Icon(Icons.cancel),
                              color: Colors.red,
                              tooltip: "Rechazar",
                              onPressed: () async =>
                                  {_action(user, 'Rechazar', _context)},
                            ),
                            IconButton(
                              key: Key("block-icon-${user.pk}"),
                              icon: Icon(Icons.block,
                                  color: Colors.red, semanticLabel: "Bloquear"),
                              tooltip: "Bloquear",
                              onPressed: () async => {
                                _action(user, 'Bloquear', _context),
                              },
                            ),
                          ]),
                        ),
                      );
                    },
                  ));
            } else if (snapshot.hasData && snapshot.data.isEmpty)
              return RefreshIndicator(
                  onRefresh: () async => {_loadUsers()},
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
              onPressed: () async => {_loadUsers()},
            ),
            helperText: "Puede buscar por nombre de usuario o por correo",
          ),
          onChanged: (val) => textFilter = val.trim(),
        ));
  }

  Future<void> _action(User user, String action, _context) async {
    var message = '';
    var type = '';
    if (action != 'Aceptar') {
      if (action == 'Bloquear') {
        message = 'Bloqueada';
      } else {
        message = "Eliminada";
      }
      type = 'DELETED';
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('¿Realmente quiere ' + action + " la solicitud?"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('La solicitud de ' +
                      user.username +
                      " va a ser " +
                      message),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('No'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Sí'),
                textColor: Colors.red,
                onPressed: () async => helper(user, type, _context),
              ),
            ],
          );
        },
      );
    } else {
      type = "ACTIVE";
      helper(user, type, _context);
    }
  }

  helper(User user, type, _context) async {
    Api.updateTypeUser(user.pk.toString(), type)
        .then((value) => this.showToast(value))
        .catchError((error) => Scaffold.of(_context).showSnackBar(
            SnackBar(content: Text('Error al configurar usuario'))));
    _loadUsers();
  }
}
