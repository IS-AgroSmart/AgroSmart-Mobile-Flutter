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
  Future<List<User>> Function() usersFutureActive;
  Future<List<User>> Function() usersFutureCallableRequestsDeleted;

  static int index = 0;
  Future<List<User>> usersFuture;
  StreamController<List<User>> _usersStream;
  List<User> users;
  String appTitle;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String textFilter = '';
  static int _selectedIndex = 0;
  double sizeIconUser = 60;
  Color iconColorUser;
  Color cardColor = Colors.lightBlue[50];
  Icon icon1;
  Icon icon2;
  Icon iconUser;
  String textIcon1;
  String textIcon2;
  bool iconVisible = true;
  bool selected1 = false;
  String description = '';

  @override
  void initState() {
    usersFuture = usersFutureCallable();
    _usersStream = StreamController<List<User>>();
    _loadUsers();
    super.initState();
  }

  void _loadUsers() async {
    if (_selectedIndex == 0) {
      //for request pending
      users = await usersFutureCallable();
      icon1 = Icon(Icons.check_circle);
      iconColorUser = Colors.black;
      iconVisible = true;
      textIcon1 = 'Aceptar';

      icon2 = Icon(Icons.cancel);
      textIcon2 = 'Rechazar';

      description = "Descripción: El usuario aun no ha sido aceptado\n\n";
    } else if (_selectedIndex == 1) {
      //for request deleted
      iconVisible = false;
      users = await usersFutureActive();
      iconColorUser = Colors.blue;

      icon2 = Icon(Icons.delete_forever);
      textIcon2 = 'Eliminar';

      description = 'Descripción: Usuario Activo\n\n';
    } else {
      //for request deleted
      iconVisible = false;
      users = await usersFutureCallableRequestsDeleted();
      icon1 = Icon(Icons.restore);
      iconColorUser = Colors.red;
      textIcon1 = 'Restaurar';

      icon2 = Icon(Icons.delete_forever);
      textIcon2 = 'Eliminar';

      description =
          'Descripción:La solicitud del usuario esta eliminada eliga que acción tomar\n\n';
    }
    iconUser = Icon(
      Icons.account_circle,
      size: sizeIconUser,
      color: iconColorUser,
    );
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

  void _onItemTapped(int index) {
    if (index == 0) {
      selected1 = false;
    } else {
      selected1 = true;
    }
    setState(() {
      _selectedIndex = index;
    });
    textFilter = '';
    _usersStream.add(null); //para hacer que la pagina se recarge
    _loadUsers();
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
                      color: cardColor,
                      margin: EdgeInsets.all(20.0),
                      shadowColor: Colors.amberAccent,
                      child: ListTile(
                        leading: iconUser,
                        title: Text('${user.username}'),
                        subtitle: Text("Email: " +
                            '${user.email}' +
                            "\nTipo: " +
                            '${user.type}' +
                            "\n" +
                            description),
                        trailing: Wrap(spacing: 0, children: <Widget>[
                          IconButton(
                            key: Key("icon1-user-${user.pk}"),
                            icon: icon1,
                            color: Colors.green,
                            tooltip: textIcon1,
                            onPressed: () async =>
                                {_action(user, textIcon1, _context)},
                          ),
                          IconButton(
                            key: Key("icon2-user-${user.pk}"),
                            icon: icon2,
                            color: Colors.red,
                            tooltip: textIcon2,
                            onPressed: () async =>
                                {_action(user, textIcon2, _context)},
                          ),
                          Visibility(
                            visible: iconVisible,
                            child: IconButton(
                              icon: Icon(Icons.block,
                                  color: Colors.red, semanticLabel: "Bloquear"),
                              tooltip: "Bloquear",
                              onPressed: () async => {
                                _action(user, 'Bloquear', _context),
                              },
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ));
          } else if (snapshot.hasData && snapshot.data.isEmpty)
            return RefreshIndicator(
                onRefresh: () async => {_loadUsers()},
                child: Center(child: Text("No hay ${appTitle.toLowerCase()}")));
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.blue[500],
        selectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(
            title: Text(
              "Solicitudes",
            ),
            icon: Icon(
              Icons.drafts,
            ),
          ),
          BottomNavigationBarItem(
            title: Text(
              "Activos",
            ),
            icon: Icon(
              Icons.account_box,
            ),
          ),
          BottomNavigationBarItem(
            title: Text(
              "Eliminados",
            ),
            icon: Icon(
              Icons.delete,
            ),
          ),
        ],
        onTap: _onItemTapped,
        selectedFontSize: 18,
      ),
    );
  }

  Future<void> _action(User user, String action, _context) async {
    var message = '';
    var type = '';
    if (action != 'Aceptar') {
      if (action == 'Bloquear') {
        message = 'Bloqueada';
      } else if (action == 'Rechazar') {
        message = "Rechazada";
      }
      type = 'DELETED';

      if (action == 'Restaurar') {
        message = 'restaurada y estará lista para ser aceptada';
        type = 'DEMO_USER';
      } else if (action == 'Eliminar') {
        message = 'eliminada de forma permamente';
        type = "eliminar";
      }

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
                      '"' +
                      user.username +
                      '"' +
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
    if (type == 'eliminar') {
      Api.deletedUser(user.pk.toString())
          .then((value) => this.showToast(value))
          .catchError((error) => Scaffold.of(_context).showSnackBar(
              SnackBar(content: Text('Error al eliminar usuario'))));
    } else {
      Api.updateTypeUser(user.pk.toString(), type)
          .then((value) => this.showToast(value))
          .catchError((error) => Scaffold.of(_context).showSnackBar(
              SnackBar(content: Text('Error al configurar usuario'))));
    }
    if (type != 'ACTIVE') {
      Navigator.of(context).pop();
    }
    _loadUsers();
  }
}
