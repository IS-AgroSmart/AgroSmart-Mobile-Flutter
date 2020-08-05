import 'dart:io';

import 'package:flutter/material.dart';
import 'api.dart';
import 'create_account_successful_widget.dart';

class ChangePassword extends StatelessWidget {
  static const routeName = "/changePassword";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ChangePassword"),
      ),
      body: ChangePasswordForm(),
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

  String passwordValidator(value) => isNotEmptyValidator("Escriba una contraseña válida", value);

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
                  onSaved: (val) => _pass = val.trim()),
              TextFormField(
                  obscureText: true,
                  validator: passwordValidator,
                  decoration: InputDecoration(hintText: "Repetir Contraseña Nueva"),
                  onSaved: (val) => _repeatedPass = val.trim()),
            ])));
  }
}