class CloudSyncTick {
  CloudSyncTick._();

  static void Function()? _flush;

  static void bind(void Function() flush) => _flush = flush;

  static void mark() => _flush?.call();
}
