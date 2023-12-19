import 'package:f/f.dart';
import 'package:test/test.dart';

void main() {
  test('push/pop', () {
    final f = F();
    f.push(42);
    expect(f.pop(), 42);
  });
  group('compile', () {
    List<Object> c(String input) => (F()..compile(input)).code;
    test('empty', () {
      expect(c(' '), <Object>[]);
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
      expect(c(':twice [dup +]'), [
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
    });

    test('logic', () {
      expect(run('1 2 <'), 1);
      expect(run('2 1 <'), 0);
    });

    test('conditional', () {
      expect(run('0 3 4 ?'), 4);
      expect(run('1 3 4 ?'), 3);
    });

    test('variables', () {
      expect(run('42 !a 0 @a'), 42);
    });

    test('while', () {
      expect(run('-1 [] [0] while'), -1);
      expect(run('0 !a [@a 1 + !a] [0] while @a'), 0);
      expect(run('0 !a [@a 1 + !a] [@a 2 <] while @a'), 2);
    });
  });
}
