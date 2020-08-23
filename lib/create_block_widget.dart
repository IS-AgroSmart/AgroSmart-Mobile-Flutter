import 'package:flutter/material.dart';
import 'api.dart';
import 'models/block.dart';
import 'package:flutter_app/blocks_widget.dart';

class NewBlockWidget extends StatelessWidget {
  static const routeName = "/blocks/new";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Criterio de Bloqueo"),
      ),
      body: NewBlockForm(),
    );
  }
}

class NewBlockForm extends StatefulWidget {
  @override
  NewBlockFormState createState() => NewBlockFormState();
}

class NewBlockFormState extends State<NewBlockForm> {
  final _formKey = GlobalKey<FormState>();
  String _value;
  Option option;
  bool _success = true;

  String isNotEmptyValidator(String message, String value) =>
      value.isEmpty ? message : null;

  String descriptionValidator(value) =>
      isNotEmptyValidator("Escriba un valor", value);

  String optionValidator(Option value) =>
      value == null ? "Seleccione un tipo" : null;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(children: <Widget>[
              if (!_success)
                Text(
                  "Error al crear criterio!",
                  style: TextStyle(color: Colors.red),
                ),

              DropdownButtonFormField<Option>(
                value: option,
                items: Option.values
                    .map((op) => DropdownMenuItem(
                  value: op,
                  child: Text(OptionHelper.description(op)),
                ))
                    .toList(),
                onChanged: (newValue) => setState(() => option = newValue),
                decoration: const InputDecoration(
                  hintText: 'Seleccione un tipo de criterio',
                  labelText: 'Criterio',
                ),
                validator: optionValidator,
              ),
              TextFormField(
                keyboardType: TextInputType.multiline,
                maxLines: 6,
                validator: descriptionValidator,
                decoration: InputDecoration(
                    hintText: "Valor",
                    labelText: "Valor del criterio"),
                onSaved: (val) => _value = val,
              ),
              RaisedButton(
                onPressed: () async {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    Block b;
                    if(option == Option.IP) {
                      b = Block(
                          ip: _value, value:'', type: OptionHelper.description(Option.IP));
                    } else {
                      b = Block(
                          ip: '', value: _value, type: OptionHelper.description(option));
                    }
                    var success = await Api.tryCreateBlock(b);
                    setState(() => _success = success);
                    if (_success)
                      Navigator.pushReplacementNamed(
                          context, BlocksWidget.routeName);
                  }
                },
                child: Text('Crear Criterio de Bloqueo'),
              ),
            ])));
  }
}
