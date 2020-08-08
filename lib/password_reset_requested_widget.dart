import 'package:flutter/material.dart';

class PasswordResetRequestedWidget extends StatelessWidget {
  static const routeName = "/password_reset/requested";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recuperar Contraseña"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: <Widget>[
              Text("Recuperación de contraseña solicitada", style: Theme.of(context).textTheme.headline6),
              Container(height: 10),
              Text(
                "Revise su email para recuperar la contraseña.",
              ),
              Container(height: 10),
              RaisedButton(
                child: Text("Continuar"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}