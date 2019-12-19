import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class User extends Equatable {
  final String id;
  final String email;
  // TODO(hyungsun): Introduce more members.

  User(this.email, {String id}) : this.id = id;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) || other is User && other.id == id;
  }

  @override
  List<Object> get props => [id, email];

  Map<String, Object> toJson() {
    return {"id": id, "email": email};
  }

  static User fromJson(Map<String, Object> json) {
    return User(json["email"] as String, id: json["id"] as String);
  }

  static User fromSnapshot(DocumentSnapshot snap) {
    return User(snap.data['email'], id: snap.documentID);
  }

  Map<String, Object> toDocument() {
    return {"id": id, "email": email};
  }

  @override
  String toString() {
    return ''' User {
      id: $id,
      email: $email
    }''';
  }
}
