import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamma/bloc/login_bloc/bloc.dart';
import 'package:mamma/bloc/register_bloc/bloc.dart';
import 'package:mamma/repositories/user_repository.dart';
import 'package:mamma/widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  final UserRepository _userRepository;

  LoginScreen({Key key, @required UserRepository userRepository})
      : assert(userRepository != null),
        _userRepository = userRepository,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: MultiBlocProvider(
        providers: <BlocProvider>[
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(userRepository: _userRepository),
          ),
          BlocProvider<RegisterBloc>(
            create: (context) => RegisterBloc(userRepository: _userRepository),
          )
        ],
        child: LoginForm(userRepository: _userRepository),
      ),
    );
  }
}
