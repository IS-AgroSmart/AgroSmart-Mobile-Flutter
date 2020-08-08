import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/profile.dart';
import 'api.dart';
import 'drawer.dart';
import 'create_account_successful_widget.dart';

class ChangePassword extends StatelessWidget {
  static const routeName = "/changePassword";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cambiar contraseña"),
      ),
      body: ChangePasswordForm(),
      drawer: AppDrawer(),
    );
  }
}

class ChangePasswordForm extends StatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  String  _pass, _repeatedPass;
  String _errorMessage = "";

  String isNotEmptyValidator(message, String value) {
    return value.isEmpty ? message : null;
  }

  String isDifferentPassword(message,String value){
    if( _pass == value){
      return null;
    }
    return message;
  }

  String passwordValidator(value) => isNotEmptyValidator("Escriba una contraseña válida", value);

  String repeatedPasswordValidator(value) => isDifferentPassword("Contraseñas no coinciden", value);

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: <Widget>[
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              TextFormField(
                  obscureText: true,
                  validator: passwordValidator,
                  decoration: InputDecoration(hintText: "Nueva Contraseña"),
                  onChanged: (val) => _pass = val.trim()),
              TextFormField(
                  obscureText: true,
                  validator:  repeatedPasswordValidator,
                  decoration: InputDecoration(hintText: "Repetir Contraseña Nueva"),
                  onChanged: (val) => _repeatedPass = val.trim()),
              Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    RaisedButton(
                        child: Text("Aceptar"),
                      onPressed: () async {
                        if (_formKey.currentState.validate()) {
                          _formKey.currentState.save();
                          try {
                              var errorMessages = await Api.tryChangePassword(_repeatedPass);
                              setState(() => _errorMessage = errorMessages.join("\n"));
                              //If success == true, account creation was OK. Transition to Account Creation Successful screen
                              if (errorMessages.isEmpty)
                                Navigator.pushReplacementNamed(context, Profile.routeName);
                          } on SocketException catch (e) {
                            print(e);
                            setState(() => _errorMessage = "Error de conexión");
                          }
                        }
                      },
                    ),
                    RaisedButton(
                        child: Text("Cancelar"),
                      onPressed: () async =>
                          Navigator.pushReplacementNamed(context, Profile.routeName),
                    ),
                  ]
              )
            ])));
  }
}