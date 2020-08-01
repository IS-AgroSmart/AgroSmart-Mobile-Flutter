import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'api.dart';

class PasswordResetRequestedWidget extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recuperar Contraseña"),
      ),
      body: PassRequestForm(),
    );
  }
}

class PassRequestForm extends StatefulWidget {
  @override
  _PassRequestFormState createState() => _PassRequestFormState();
}

class _PassRequestFormState extends State<PassRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String _email;
  String _errorMessage = "";

  String isNotEmptyValidator(message, String value) {
    return value.isEmpty ? message : null;
  }

  String emailValidator(value) => isNotEmptyValidator("Requested", value);

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
                  keyboardType: TextInputType.emailAddress,
                  validator: emailValidator,
                  decoration: InputDecoration(hintText: "Requested"),
                  onSaved: (val) => _email = val.trim()),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    Navigator.pushReplacementNamed(context, LoginWidget.routeName);
        
                },
                child: Text('Aceptar'),
              )
            ])));
  }
}