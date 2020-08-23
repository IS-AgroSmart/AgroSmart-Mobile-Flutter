import 'dart:async';
import 'package:flutter_app/create_block_widget.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'api.dart';

import 'drawer.dart';
import 'models/block.dart';

abstract class AbstractBlocks extends StatefulWidget {
  static const routeName = "declare on child classes";

  String routeNameFunc();
}

abstract class AbstractsBlocksState extends State<AbstractBlocks> {
  Future<List<Block>> Function() blocksFutureActive;
  Future<List<Block>> Function() blocksFutureCallableRequestsDeleted;

  static int index = 0;
  Future<List<Block>> blocksFuture;
  StreamController<List<Block>> _blocksStream;
  List<Block> blocks;
  String appTitle;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String textFilter = '';
  static int _selectedIndex = 0;
  double sizeIconBlock = 60;
  Color iconColorBlock;
  Color cardColor = Colors.lightBlue[50];
  Icon icon1;
  Icon icon2;
  Icon iconBlock;
  String textIcon1;
  String textIcon2;
  bool blockIconVisible = true,
      icon1Visible = true;
  bool selected1 = false;
  String description = '';

  @override
  void initState() {
    _blocksStream = StreamController<List<Block>>();
    _loadBlocks();
    super.initState();
  }

  void _loadBlocks() async {
    if (_selectedIndex == 0) {
      //for request deleted
      blocks = await blocksFutureActive();
      blockIconVisible = false;
      iconColorBlock = Colors.blue;

      icon1Visible = false;
      icon1 = Icon(Icons.check); // Won't be seen

      icon2 = Icon(Icons.delete_forever);
      textIcon2 = 'Eliminar';

      description = 'Descripción: Usuario Activo\n\n';
    } else {
      //for request deleted
      blocks = await blocksFutureCallableRequestsDeleted();
      blockIconVisible = false;
      iconColorBlock = Colors.red;

      icon1Visible = true;
      icon1 = Icon(Icons.restore);
      textIcon1 = 'Restaurar';

      icon2 = Icon(Icons.delete_forever);
      textIcon2 = 'EliminarPermanente';

      description =
      'Descripción: La solicitud del usuario esta eliminada eliga que acción tomar\n\n';
    }
    iconBlock = Icon(
      Icons.account_circle,
      size: sizeIconBlock,
      color: iconColorBlock,
    );
    if (textFilter.isNotEmpty) {
      _blocksStream.add(blocks
          .where((u) =>
      u.value != null? u.value.toLowerCase().indexOf(textFilter) > -1 :
      u.ip.toLowerCase().indexOf(textFilter) > -1 ||
          u.type.toLowerCase().indexOf(textFilter) > -1)
          .toList());
    } else {
      _blocksStream.add(blocks);
    }
  }

  void showToast(message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.blueGrey[200],
        textColor: Colors.white);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    textFilter = '';
    _blocksStream.add(null); //para hacer que la pagina se recarge
    _loadBlocks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(appTitle),
      ),
      drawer: AppDrawer(),
      floatingActionButton: Visibility(
        child: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, NewBlockWidget.routeName),
          child: Icon(Icons.add),
        ),
      ),
      body: StreamBuilder<List<Block>>(
        stream: _blocksStream.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Text(
              snapshot.error.toString(),
              style: TextStyle(color: Colors.red),
            );
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            var _context = context;
            return RefreshIndicator(
                onRefresh: () async => _loadBlocks(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: snapshot.data.length,
                  itemBuilder: (context, index) {
                    final block = snapshot.data[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.white70, width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: cardColor,
                      margin: EdgeInsets.all(20.0),
                      shadowColor: Colors.amberAccent,
                      child: ListTile(
                        leading: iconBlock,
                        title: Text('Si el '+'${block.type}'+ ' es igual a:'),
                        subtitle: Text('${block.type}'+": " +
                            '${null != block.value? block.value: block.ip}'),
                        trailing: Wrap(spacing: 0, children: <Widget>[
                          IconButton(
                            key: Key("icon2-user-${block.pk}"),
                            icon: icon2,
                            color: Colors.red,
                            tooltip: textIcon2,
                            onPressed: () async =>
                            {_action(block, textIcon2, _context)},
                          ),
                        ]),
                      ),
                    );
                  },
                ));
          } else if (snapshot.hasData && snapshot.data.isEmpty)
            return RefreshIndicator(
                onRefresh: () async => {_loadBlocks()},
                child: Center(child: Text("No hay ${appTitle.toLowerCase()}")));
          else
            return Center(child: CircularProgressIndicator());
        },
      ),
      bottomSheet: TextFormField(
        decoration: InputDecoration(
          hintText: "Ingrese la busqueda..",
          icon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () async => {_loadBlocks()},
          ),
          helperText: "Puede buscar por valor de criterio",
        ),
        onChanged: (val) => textFilter = val.trim(),
      ),
    );
  }

  Future<void> _action(Block block, String action, _context) async {
    var message = '';
    var type = '';

    if (action == 'EliminarPermanente') {
      message = 'eliminado de forma permamente';
      type = "eliminar";
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¿Realmente quiere ' + action + " el criterio?"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("El criterio será " +
                    message),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Sí'),
              textColor: Colors.red,
              onPressed: () async => helper(block, _context),
            ),
          ],
        );
      },
    );
  }

  helper(Block block, _context) async {
    Api.tryDeleteBlock(block)
          .then((value) => this.showToast(value))
          .catchError((error) =>
          Scaffold.of(_context).showSnackBar(
              SnackBar(content: Text('Error al eliminar criterio de bloqueo'))));
    _loadBlocks();
    Navigator.of(context).pop();
  }
}
