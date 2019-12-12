import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamma/bloc/mamma_bloc_delegate.dart';
import 'package:mamma/enums/route_type.dart';
import 'package:mamma/pages/auth_login_page.dart';
import 'package:mamma/pages/splash_page.dart';
import 'package:mamma/pages/voice_check_page.dart';
import 'package:mamma/repositories/user_repository.dart';

import 'bloc/authentication_bloc/bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BlocSupervisor.delegate = MammaBlocDelegate();
  final UserRepository userRepository = UserRepository();
  runApp(
    BlocProvider(
      create: (context) => AuthenticationBloc(userRepository: userRepository)..add(AppStarted()),
      child: MammaApp(userRepository: userRepository),
    ),
  );
}

class MammaApp extends StatelessWidget {
  final UserRepository _userRepository;

  MammaApp({Key key, @required UserRepository userRepository})
      : assert(userRepository != null),
        _userRepository = userRepository,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: <RouteType, WidgetBuilder>{
        RouteType.splashPage: (context) => const SplashPage(),
        RouteType.voiceCheckPage: (context) => const VoiceCheckPage(),
      }.map((routeType, page) => MapEntry(toRouteName(routeType), page)),
      home: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context,  state) {
          if (state is Uninitialized) {
            return const SplashPage();
          }

          if (state is Unauthenticated) {
            return LoginScreen(userRepository: _userRepository);
          }

          if (state is Authenticated) {
            return const VoiceCheckPage();
          }
        },
      ),
    );
  }
}
