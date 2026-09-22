abstract class HttpCancelToken {
  bool get isCancelled;

  void cancel([Object? reason]);

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled;
}
