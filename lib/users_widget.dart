import '_abstract_users_widget.dart';
import 'api.dart';

class UsersWidget extends AbstractUsers {
  static final String routeName = "/users/";

  @override
  String routeNameFunc() => UsersWidget.routeName;

  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends AbstractsUsersState {
  final appTitle = "Usuarios";

  @override
  void initState() {
    usersFutureActive = Api.fetchUsersActive;
    usersFutureCallableRequestsDeleted = Api.fetchUsersRequestDeleted;
    super.initState();
  }
}
