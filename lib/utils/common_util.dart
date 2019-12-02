T ifValueOrNull<T>(bool condition, T value) => condition ? value : null;

R let<T, R>(T value, R Function(T) callback) =>
    value != null ? callback(value) : null;

/// Compare boolean in descending order (true will be leading from false)
int compareBool(bool lhs, bool rhs) {
  if (lhs == rhs) {
    return 0;
  }
  if (rhs) {
    return 1;
  }
  if (lhs) {
    return -1;
  }
  assert(false);
  return 0;
}
