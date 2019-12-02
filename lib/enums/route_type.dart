enum RouteType {
  splashPage,
  voiceCheckPage,
}

final Map<RouteType, String> _routeNameMap = Map.fromEntries(
  RouteType.values.map((routeType) {
    final routeName = routeType.toString().split('.').last;
    return MapEntry(routeType, routeName);
  }),
);

String toRouteName(RouteType routeType) => _routeNameMap[routeType];
