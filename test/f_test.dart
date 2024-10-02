import 'package:f/f.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('push/pop,popNum', () {
      final f = F()
        ..push(41)
        ..push(42);
      expect(f.pop(), 42);
      expect(f.popNum(), 41);
    });

    test('push/popN', () {
      final f = F()
        ..push(3)
        ..push(4)
        ..push(5);
      expect(f.popN(2), <Object>[4, 5]);
      expect(f.popN(0), <Object>[]);
      expect(f.popN(1), <Object>[3]);
    });
  });

  group('compile', () {
    List<Object> c(String input) => (F()..compile(input)).code;

    test('empty', () {
      expect(c(' '), <Object>[]);
    });
    test('comments', () {
      expect(c('a ; a comment'), <Object>['a']);
    });
    test('number literal', () {
      expect(c('42 -0.815'), ["'", 42, "'", -0.815]);
    });
    test('string literal', () {
      expect(c('"" "\\u{a}"'), ["'", "", "'", "\n"]);
    });
    test('quotation', () {
      expect(c('[]'), ["'", <Object>[]]);
      expect(c('[ 42 ]'), [
        "'",
        ["'", 42]
      ]);
    });
    test('words', () {
      expect(c('+ foo ..'), ['+', 'foo', '..']);
    });
    test('variables', () {
      expect(c('!foo @bar'), ["'", 'foo', '!', "'", 'bar', '@']);
    });
    test('define word', () {
      expect(c('[dup +] !twice'), [
        "'",
        ['dup', '+'],
        "'",
        'twice',
        '!'
      ]);
    });
  });

  group('run', () {
    Object run(String input) {
      final f = F();
      f.compile(input);
      while (f.step() != 0) {}
      return f.pop();
    }

    test('literal', () {
      expect(run('42'), 42);
    });

    test('arithmetic', () {
      expect(run('3 4 +'), 7);
      expect(run('3 4 -'), -1);
      expect(run('3 4 *'), 12);
      expect(run('3 4 /'), .75);
    });

    test('logic', () {
      expect(run('1 1 ='), 1);
      expect(run('2 1 ='), 0);
      expect(run('1 2 <'), 1);
      expect(run('2 1 <'), 0);
    });
    test('stack effects', () {
      expect(run('1 dup pop'), 1);
      expect(run('1 2 swp -'), 1);
      expect(run('1 2 3 rot'), 1);
    });

    test('conditional', () {
      expect(run('0 3 4 ?'), 4);
      expect(run('1 3 4 ?'), 3);
    });

    test('variables', () {
      expect(run('42 !a 0 @a'), 42);
    });

    test('if/when/unless', () {
      expect(run('1 [1][2] if'), 1);
      expect(run('0 [1][2] if'), 2);
      expect(run('3 1 [1 +] when'), 4);
      expect(run('3 0 [1 +] when'), 3);
      expect(run('3 1 [1 +] unless'), 3);
      expect(run('3 0 [1 +] unless'), 4);
    });

    test('while/until', () {
      expect(run('-1 [0] [] while'), -1);
      expect(run('0 !a [0] [@a 1 + !a] while @a'), 0);
      expect(run('0 !a [@a 2 <] [@a 1 + !a] while @a'), 2);
      expect(run('-1 [1] [] until'), -1);
      expect(run('0 !a [1] [@a 1 + !a] until @a'), 0);
      expect(run('0 !a [@a 2 =] [@a 1 + !a] until @a'), 2);
    });
  });
}
