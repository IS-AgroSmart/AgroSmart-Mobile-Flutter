
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/change_password.dart';
import 'drawer.dart';
import 'package:flutter_app/helpers.dart';

class Profile extends StatelessWidget {
  static const routeName = "/profile";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil"),
      ),
      body: _ProfileDetailWidget(),
        drawer: AppDrawer(),
    );
  }
}

class _ProfileDetailWidget extends StatefulWidget {
  @override
  _ProfileDetailWidgetState createState() => _ProfileDetailWidgetState();
}

class _ProfileDetailWidgetState extends State<_ProfileDetailWidget> {


  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment:
        MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text("Nombre: " + Helpers.loggedInUser.name  ,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),),
          Text("Usuario: "+ Helpers.loggedInUser.username,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),),
          Text("Organización: " + Helpers.loggedInUser.organization,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20.0),),
          Text("Correo Electronico: " + Helpers.loggedInUser.email,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),),
          Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text("Contraseña:   ****",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20.0),),
                RaisedButton(
                  child: Text("Cambiar"),
                  onPressed: () async =>
                      Navigator.pushReplacementNamed(context, ChangePassword.routeName),
                ),
              ]
          )

    ]);
  }
}
