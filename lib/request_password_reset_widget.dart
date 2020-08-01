import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/create_account_widget.dart';
import 'api.dart';

class RequestPasswordResetWidget extends StatelessWidget {
  
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
  String _errorMessage = "";

  String isNotEmptyValidator(message, String value) {
    return value.isEmpty ? message : null;
  }

  String emailValidator(value) => isNotEmptyValidator("Escriba un email", value);

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
                  decoration: InputDecoration(hintText: "E-mail"),
                  onSaved: (val) => _email = val.trim()),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();

                    try {
                      var errorMessages = await Api.tryResetPassword(_email);
                      setState(() => _errorMessage = errorMessages.join("\n"));
                      // If success == true, account creation was OK. Transition to Account Creation Successful screen
                      if (errorMessages)
                        Navigator.pushReplacementNamed(context, PasswordResetRequestedWidget.routeName);
                    } on SocketException catch (e) {
                      print(e);
                      setState(() => _errorMessage = "Error de conexión");
                    }
                  }
                },
                child: Text('Enviar'),
              )
            ])));
  }
}
