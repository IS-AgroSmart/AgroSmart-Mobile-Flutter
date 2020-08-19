import '_abstract_users_widget.dart';
import 'api.dart';

class UserRequestsWidget extends AbstractUersWidget {
  static final String routeName = "/user/";

  @override
  String routeNameFunc() => UserRequestsWidget.routeName;

  @override
  _CompletedUsersState createState() => _CompletedUsersState();
}

class _CompletedUsersState extends AbstractUsersState {
  final appTitle = "Solicitudes de Usuarios";

  @override
  void initState() {
    usersFutureCallable = Api.fetchUsersRequest;
    usersFutureActive = Api.fetchUsersActive;
    usersFutureCallableRequestsDeleted = Api.fetchUsersRequestDeleted;
    super.initState();
  }
}
