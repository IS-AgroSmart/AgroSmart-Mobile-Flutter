import 'dart:io';

import 'package:flutter/material.dart';
import 'api.dart';
import 'create_account_successful_widget.dart';

class CreateAccountWidget extends StatelessWidget {
  static const routeName = "/createAccount";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear cuenta"),
      ),
      body: CreateAccountForm(),
    );
  }
}

class CreateAccountForm extends StatefulWidget {
  @override
  _CreateAccountFormState createState() => _CreateAccountFormState();
}

class _CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  String _username, _pass, _email,_organization,_name;
  String _errorMessage = "";

  String isNotEmptyValidator(message, String value) {
    return value.isEmpty ? message : null;
  }

  String usernameValidator(value) => isNotEmptyValidator('Escriba un nombre de usuario', value);

  String emailValidator(value) => isNotEmptyValidator("Escriba un email", value);

  String passwordValidator(value) => isNotEmptyValidator("Escriba una contraseña", value);

  String nameValidator(value) => isNotEmptyValidator("Escriba un nombre correcto", value);

  String organizationValidator(value) => isNotEmptyValidator("Escriba el nombre de su organización", value);

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
                  validator: usernameValidator,
                  decoration: InputDecoration(hintText: "Username"),
                  onSaved: (val) => _username = val.trim()),
              TextFormField(
                  validator: nameValidator,
                  decoration: InputDecoration(hintText: "Nombres"),
                  onSaved: (val) => _name = val.trim()),
              TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  decoration: InputDecoration(hintText: "E-mail"),
                  onSaved: (val) => _email = val.trim()),
              TextFormField(
                  obscureText: true,
                  validator: passwordValidator,
                  decoration: InputDecoration(hintText: "Contraseña"),
                  onSaved: (val) => _pass = val.trim()),
              TextFormField(
                  validator: organizationValidator,
                  decoration: InputDecoration(hintText: "Organizacion"),
                  onSaved: (val) => _organization = val.trim()),

              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    try {
                      var errorMessages = await Api.tryCreateAccount(_username, _pass, _email,_name,_organization);
                      setState(() => _errorMessage = errorMessages.join("\n"));
                      // If success == true, account creation was OK. Transition to Account Creation Successful screen
                      if (errorMessages.isEmpty)
                        Navigator.pushReplacementNamed(context, CreateAccountSuccessfulWidget.routeName);
                    } on SocketException catch (e) {
                      print(e);
                      setState(() => _errorMessage = "Error de conexión");
                    }
                  }
                },
                child: Text('Crear cuenta'),
              )
            ])));
  }
}
