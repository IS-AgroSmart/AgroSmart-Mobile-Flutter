import 'package:flutter/material.dart';
import 'package:flutter_app/admin_options.dart';
import 'package:flutter_app/completed_flights_widget.dart';
import 'package:flutter_app/helpers.dart';
import 'package:flutter_app/login_widget.dart';
import 'package:flutter_app/new_flight.dart';
import 'package:flutter_app/processing_flights_widget.dart';
import 'package:flutter_app/profile.dart';
import 'package:flutter_app/waiting_flights_widget.dart';
import 'package:prefs_config/prefs_config.dart';

import 'api.dart';
import 'deleted_flights_widget.dart';
import 'helpers.dart';
import 'package:flutter_app/user_requests.dart';

class AppDrawer extends Drawer {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(Helpers.loggedInUser.username),
            accountEmail: Text(Helpers.loggedInUser.email),
          ),
          if (["ACTIVE", "ADMIN"].contains(Helpers.loggedInUser.type))
            ListTile(
              title: Text("Crear nuevo vuelo"),
              leading: Icon(Icons.add_circle_outline),
              onTap: () => Navigator.pushReplacementNamed(
                  context, NewFlightWidget.routeName),
//            trailing: Icon(Icons.arrow_forward),
            ),
          Divider(),
          ListTile(
            title: Text("Vuelos completos"),
            leading: Icon(Icons.check_box),
            onTap: () => Navigator.pushReplacementNamed(
                context, CompletedFlightsWidget.routeName),
          ),
          ListTile(
            title: Text("Vuelos en procesamiento"),
            leading: Icon(Icons.autorenew),
            onTap: () => Navigator.pushReplacementNamed(
                context, ProcessingFlightsWidget.routeName),
          ),
          ListTile(
            title: Text("Vuelos pendientes"),
            leading: Icon(Icons.alarm),
            onTap: () => Navigator.pushReplacementNamed(
                context, WaitingFlightsWidget.routeName),
          ),
          ListTile(
            title: Text("Vuelos eliminados"),
            leading: Icon(Icons.delete),
            onTap: () => Navigator.pushReplacementNamed(
                context, DeletedFlightsWidget.routeName),
          ),
          Divider(),
          ListTile(
            title: Text("Configuración"),
            leading: Icon(Icons.settings),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PreferenceContainer(
                        preferences: _generatePrefs(),
                        title: "Configuración"))),
          ),
          Visibility(
            visible: Helpers.loggedInUser.isStaff ||
                Helpers.loggedInUser.type == 'ADMIN',
            child: ListTile(
              title: Text("Opciones Admin"),
              enabled: Helpers.loggedInUser.isStaff ||
                  Helpers.loggedInUser.type == 'ADMIN',
              leading: Icon(Icons.build),
              onTap: () => Navigator.pushReplacementNamed(
                  context, AdminOptionsWidget.routeName),
            ),
          ),
          ListTile(
            title: Text("Perfil"),
            leading: Icon(Icons.person),
            onTap: () =>
                Navigator.pushReplacementNamed(context, Profile.routeName),
          ),
          ListTile(
            title: Text("Cerrar sesión"),
            leading: Icon(Icons.close),
            onTap: () => Api.logOut().then((_) =>
                Navigator.pushNamedAndRemoveUntil(
                    context, LoginWidget.routeName, (r) => false)),
//            trailing: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  List<Pref> _generatePrefs() {
    return <Pref>[
      Pref(
          prefKey: "txt_plain",
          type: Pref.TYPE_TEXT,
          defVal: "foobar",
          min: 1,
          // Minimum length of text preference - 1 means cannot be empty.
          label: "Text Pref",
          description: "This is a Text Setting"),
      Pref(
          prefKey: "bol_switch",
          type: Pref.TYPE_BOOL,
          defVal: true,
          label: "Bool Switch Pref",
          format: Pref.FORMAT_BOOL_SWITCH,
          description: "This is a Bool Switch Setting"),
    ];
  }
}
