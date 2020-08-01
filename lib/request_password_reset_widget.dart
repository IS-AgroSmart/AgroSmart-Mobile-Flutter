import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'package:flutter_app/password_reset_requested_widget.dart';
import 'api.dart';

class RequestPasswordResetWidget extends StatelessWidget {
  static const routeName = "/reset_password";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recuperar Contraseña"),
      ),
      body: ResetPassForm(),
    );
  }
}

class ResetPassForm extends StatefulWidget {
  @override
  _ResetPassFormState createState() => _ResetPassFormState();
}

class _ResetPassFormState extends State<ResetPassForm> {
  final _formKey = GlobalKey<FormState>();
  String _email;
  bool _errorMessage = false;

  String isNotEmptyValidator(message, String value) {
    return value.isEmpty ? message : null;
  }

  String emailValidator(value) =>
      isNotEmptyValidator("Escriba un email", value);

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: <Widget>[
              if (_errorMessage)
                Text(
                  "Error al solicitar reseteo de contraseña",
                  style: TextStyle(color: Colors.red),
                ),
              TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  decoration: InputDecoration(hintText: "E-mail"),
                  onSaved: (val) => _email = val.trim()),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    try {
                      var success = await Api.tryResetPassword(_email);
                      setState(() => _errorMessage = !success);
                      // If success == true, password reset request was OK. Transition to Password Reset Requested screen
                      if (success)
                        Navigator.pushReplacementNamed(
                            context, PasswordResetRequestedWidget.routeName);
                    } on SocketException catch (e) {
                      print(e);
                      setState(() => _errorMessage = true);
                    }
                  }
                },
                child: Text('Enviar'),
              )
            ])));
  }
}
