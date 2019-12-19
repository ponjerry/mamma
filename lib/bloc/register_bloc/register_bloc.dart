import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:mamma/bloc/register_bloc/register_event.dart';
import 'package:mamma/bloc/register_bloc/register_state.dart';
import 'package:mamma/model/user.dart';
import 'package:mamma/repositories/user_repository.dart';
import 'package:meta/meta.dart';

// TODO(hyungsun): Currently, we support google registration only.
class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {  
  final UserRepository _userRepository;

  RegisterBloc({@required UserRepository userRepository})
      : assert(userRepository != null),
        _userRepository = userRepository;

  @override
  RegisterState get initialState => RegisterState.loading();

  @override
  Stream<RegisterState> mapEventToState(
    RegisterEvent event,
  ) async* {
    if (event is Registered) {
      yield* _mapRegisteredToState();
    }
  }

  Stream<RegisterState> _mapRegisteredToState() async* {
    yield RegisterState.loading();
    try {
      final firebaseUser = await _userRepository.getFirebaseUser();
      await _userRepository.createUser(User(firebaseUser.email, id: firebaseUser.uid));
      yield RegisterState.success();
    } catch (_) {
      yield RegisterState.failure();
    }
  }
}