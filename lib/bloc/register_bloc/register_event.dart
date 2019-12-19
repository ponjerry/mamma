import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class RegisterEvent extends Equatable {
  RegisterEvent() : super();
}

class Registered extends RegisterEvent {

  @override
  String toString() {
    return 'Registered';
  }

  @override
  List<Object> get props => null;
}
