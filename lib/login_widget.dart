import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'api.dart';

class LoginWidget extends StatelessWidget {
  static const routeName = "/login";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Iniciar sesión"),
      ),
      body: LoginForm(),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String _username, _pass;
  bool _success = true;

  String isNotEmptyValidator(message, String value) {
    if (value.isEmpty) {
      return message;
    }
    return null;
  }

  String usernameValidator(value) => isNotEmptyValidator('Escriba un nombre de usuario', value);

  String passwordValidator(value) => isNotEmptyValidator("Escriba una contraseña", value);

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: <Widget>[
              if (!_success)
                Text(
                  "Credenciales erróneas!",
                  style: TextStyle(color: Colors.red),
                ),
              TextFormField(
                  validator: usernameValidator,
                  decoration: InputDecoration(hintText: "Username"),
                  onSaved: (val) => _username = val.trim()),
              TextFormField(
                obscureText: true,
                validator: passwordValidator,
                decoration: InputDecoration(hintText: "Contraseña"),
                onSaved: (val) => _pass = val.trim(),
              ),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    var success = await Api.tryLogin(_username, _pass);
                    setState(() => _success = success);
                    // If success == true, login was OK. Transition to Flights screen
                    if (_success) Navigator.pushReplacementNamed(context, CompletedFlightsWidget.routeName);
                  }
                },
                child: Text('Iniciar sesión'),
              ),
              Container(height: 10),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, CreateAccountWidget.routeName),
                child: Text('Crear cuenta'),
              ),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, RequestPasswordResetWidget.routeName),
                child: Text('Olvidé mi contraseña'),
              ),
            ])));
  }
}
