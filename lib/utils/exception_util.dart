import 'app_util.dart';

String extractErrorMessage(dynamic error) {
  final message = error.toString();
  if (message.contains('Unauthorized')) {
    return '이 기능에 대한 권한이 없습니다.';
  } else if (message.contains('NotFound')) {
    return '리소스를 찾을 수 없습니다.';
  } else if (message.contains('BadRequest')) {
    return '요청이 잘못되었습니다.';
  } else if (message.contains('Conflict')) {
    return '이미 있는 리소스입니다.';
  } else if (message.contains('InternalServerError')) {
    return '서버에서 에러가 발생했습니다.';
  } else if (message.contains('TimeoutException')) {
    return '응답시간이 초과되었습니다.';
  }
  if (isInDebugMode) {
    print(error);
    return message;
  }
  return '알 수 없는 에러가 발생했습니다.';
}
