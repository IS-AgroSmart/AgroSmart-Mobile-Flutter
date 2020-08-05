import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/models/user.dart';

import 'api.dart';

class Profile extends StatelessWidget {
  static const routeName = "/profile";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Perfil"),
      ),
      body: _ProfileDetailWidget(),
    );
  }
}

class _ProfileDetailWidget extends StatefulWidget {
  @override
  _ProfileDetailWidgetState createState() => _ProfileDetailWidgetState();
}

class _ProfileDetailWidgetState extends State<_ProfileDetailWidget> {


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery
            .of(context)
            .size
            .width,
      ),
    );
  }
}
