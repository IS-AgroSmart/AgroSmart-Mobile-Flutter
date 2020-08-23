import '_abstract_blocks_widget.dart';
import 'api.dart';

class BlocksWidget extends AbstractBlocks {
  static final String routeName = "/blocks/";

  @override
  String routeNameFunc() => BlocksWidget.routeName;

  @override
  _BlockState createState() => _BlockState();
}

class _BlockState extends AbstractsBlocksState {
  final appTitle = "Criterios de Bloqueo";

  @override
  void initState() {
    blocksFutureActive = Api.fetchBlockRequest;
    super.initState();
  }
}
