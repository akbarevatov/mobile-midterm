import 'dart:math';

final Random _random = Random();
int _counter = 0;

String newId(String prefix) {
  _counter++;
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 20).toRadixString(36);
  return '$prefix-$time-$_counter$noise';
}
