import 'package:flutter/material.dart';
import 'package:flutter_app/completed_flights_widget.dart';

class CreateAccountSuccessfulWidget extends StatelessWidget {
  static const routeName = "/createAccount/success";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenido"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: <Widget>[
              Text("¡Bienvenido a AgroSmart!", style: Theme.of(context).textTheme.headline6),
              Container(height: 10),
              Text(
                "Su cuenta se ha creado con éxito. Ahora puede ver un vuelo de demostración "
                "para evaluar las capacidades del programa.\n\nPara desbloquear todas las funcionalidades, "
                "póngase en contacto con FlySensor para negociar un contrato.",
              ),
              Container(height: 10),
              RaisedButton(
                child: Text("Continuar"),
                onPressed: () => Navigator.pushReplacementNamed(context, CompletedFlightsWidget.routeName),
              )
            ],
          ),
        ),
      ),
    );
  }
}
