import 'dart:io';

import 'package:f/f.dart';

extension on F {
  void run(String input) {
    compile(input);
    while (true) {
      switch (step()) {
        case 0:
          return;
        case 1:
          break;
        case 2:
          stdout.write(pop());
        case 3:
          final line = stdin.readLineSync();
          if (line == null || line.isEmpty) return;
          push(int.parse(line));
      }
    }
  }
}

void main() {
  final f = F();
  // execute raw code
  f.start(["'", 3, "'", 4, '+', '.', "'", '\n', '.']);
  f.run('');

  // compile and run
  f.run('[ "\\n" . ] !cr');
  f.run('3 5 + . cr');
  f.run('3 4 swp . . cr');
  f.run('[dup 0 = [pop 1] [dup 1 - fac *] ? i] !fac\n13 fac . cr');
}
