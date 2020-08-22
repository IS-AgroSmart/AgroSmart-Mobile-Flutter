import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/users_widget.dart';
import 'drawer.dart';
import 'package:flutter_app/user_requests.dart';

class AdminOptionsWidget extends StatelessWidget {
  static const routeName = "/admin_options";

  String routeNameFunc() => AdminOptionsWidget.routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Opciones Admin"),
      ),
      body: _AdminOptionsDetailWidget(),
      drawer: AppDrawer(),
    );
  }
}

class _AdminOptionsDetailWidget extends StatefulWidget {
  @override
  _AdminOptionsDetailState createState() => _AdminOptionsDetailState();
}

class _AdminOptionsDetailState extends State<_AdminOptionsDetailWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
          RaisedButton(
            child: Text("Solicitudes"),
            onPressed: () async => Navigator.pushReplacementNamed(
                context, UserRequestsWidget.routeName),
          ),
          RaisedButton(
            child: Text("Usuarios"),
            onPressed: () async =>
                Navigator.pushReplacementNamed(context, UsersWidget.routeName),
          ),
        ]));
  }
}
