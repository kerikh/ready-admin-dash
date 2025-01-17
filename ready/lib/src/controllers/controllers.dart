library controllers;

import 'dart:async';

import 'package:ready/ready.dart';

export './state/ready_list_state.dart';

part 'loading_handler.dart';
part 'ready_list_controller.dart';
part 'ready_list_controller_copies.dart';

class ReadyListResponse<T> {
  factory ReadyListResponse.success({
    required Iterable<T> items,
    required int total,
  }) = _Success<T>;

  factory ReadyListResponse.cancel() = _Cancel;
  factory ReadyListResponse.error(String message) = _Error;
}

class _Success<T> implements ReadyListResponse<T> {
  final Iterable<T> items;
  final int total;

  _Success({
    required this.items,
    required this.total,
  });
}

class _Cancel<T> implements ReadyListResponse<T> {}

class _Error<T> implements ReadyListResponse<T> {
  final String error;

  _Error(this.error);
}
