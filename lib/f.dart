/// Stack-language interpreter.
///
/// Call [start] to push a list of operations to the runtime stack. Then run
/// [step] as long as it returns 1. If it returns 2, print the top of the stack.
/// If it returns 3, read a line of input and push it as an int. If it returns
/// 0, you are done.
///
/// Use [push] or [pop] to manipulate the stack.
///
/// Use [compile] to compile a string of code into a list of operations.
class F {
  final _r = <_R>[];
  final _data = <Object>[];
  final _vars = <String, Object>{
    'twice': ['dup', '+'],
    'nip': ['swp', 'pop'],
    'tuk': ['swp', 'ovr'],
    'while': [
      'ovr',
      'i',
      "'",
      ['dup', 'i', 'while'],
      "'",
      ['pop', 'pop'],
      '?',
      'i',
    ],
  };

  List<Object> get code => _r.last.code;

  void push(Object value) => _data.add(value);

  Object pop() => _data.removeLast();

  num popNum() => pop() as num;

  List<Object> popN(int n) {
    if (n <= 0) return [];
    if (n == 1) return [pop()];
    final list = _data.sublist(_data.length - n);
    _data.removeRange(_data.length - n, _data.length);
    return list;
  }

  void start(List<Object> code) => _r.add(_R(code));

  /// Executes one instruction. Then signals how to proceed.
  /// + 0 means that nothing is left to do.
  /// + 1 means that the caller should call again.
  /// + 2 means that the caller should print the top of the stack.
  /// + 3 means that the caller should read a line of input.
  int step() {
    Object? op;
    do {
      if (_r.isEmpty) return 0;
      op = _r.last.next();
      if (op == null) _r.removeLast();
    } while (op == null);
    switch (op) {
      case "'":
        push(_r.last.next() ?? (throw Exception('missing literal')));
      case '+':
        push(popNum() + popNum());
      case '-':
        push(-popNum() + popNum());
      case '*':
        push(popNum() * popNum());
      case '/':
        push((1 / popNum()) * popNum());
      case '=':
        push(pop() == pop() ? 1 : 0);
      case '<':
        push(popNum() > popNum() ? 1 : 0);
      case '@': // get var
        push(_vars[pop() as String] ?? (throw Exception('undefined variable: $op')));
      case '!': // set var
        _vars[pop() as String] = pop();
      case 'i': // invoke quotation
        start(_code(pop()));
      case '?': // f a b -> a|b
        final b = pop();
        final a = pop();
        final f = pop();
        push(f != 0 && f != false ? a : b);
      case 'dup': // a -> a a
        push(_data.last);
      case 'pop': // a ->
        pop();
      case 'swp': // a b -> b a
        final b = pop();
        final a = pop();
        push(b);
        push(a);
      case 'ovr': // a b -> a b a
        final b = pop();
        final a = pop();
        push(a);
        push(b);
        push(a);
      case 'rot': // a b c -> b c a
        final c = pop();
        final b = pop();
        final a = pop();
        push(b);
        push(c);
        push(a);
      case '.':
        return 2;
      case '??':
        return 3;
      default:
        start(_code(_vars[op] ?? (throw Exception('undefined word: $op'))));
    }
    return 1;
  }

  static List<Object> _code(Object value) {
    if (value is List<Object>) return value;
    throw Exception('not code: $value');
  }

  /// Parses [input] as a sequence of literals and operations, interpreting
  /// pushing literals, compiling quotations, compiling conditionals, and
  /// defining words.
  ///
  /// * 1  -> '1      (push literal numbers)
  /// * "1" -> '1     (push literal strings)
  /// * [1] -> '['1]  (push literal quotations, recursive)
  /// * !a -> 'a !    (expand set-variable macro)
  /// * @a -> 'a @    (expand get-variable macro)
  /// * +  -> +       (normal operations)
  void compile(String input) {
    void beginQuotation() => push(<Object>[]);

    void compile(Object value) => _code(_data.last).add(value);

    void compileLiteral(Object value) {
      compile("'");
      compile(value);
    }

    String endQuotation() {
      final code = _code(pop());
      final name = pop() as String;
      compileLiteral(code);
      return name;
    }

    beginQuotation();
    for (final w in _re.allMatches(input).map((m) => m[1]?.unescaped ?? m[0]!)) {
      if (w == '[') {
        push(w);
        beginQuotation();
      } else if (w == ']') {
        if (endQuotation() != '[') throw 'missing [';
      } else if (w.length > 1 && w.startsWith('"') && w.endsWith('"')) {
        compileLiteral(w.substring(1, w.length - 1));
      } else if (w.length > 1 && w.startsWith('!')) {
        compileLiteral(w.substring(1));
        compile('!');
      } else if (w.length > 1 && w.startsWith('@')) {
        compileLiteral(w.substring(1));
        compile('@');
      } else {
        final n = num.tryParse(w);
        if (n != null) {
          compileLiteral(n);
        } else {
          compile(w);
        }
      }
    }
    start(_code(pop()));
  }

  static final _re = RegExp(r'("(?:\\.|[^"])*")|[^\s[\]]+|\S');
}

extension on String {
  String get unescaped => replaceAllMapped(RegExp(r'\\(?:u\{([\da-f]{1,6})\}|u([\da-f]{4})|(.))'), (m) {
        final u = m[1] ?? m[2];
        if (u != null) return String.fromCharCode(int.parse(u, radix: 16));
        if (m[3] == 'n') return '\n';
        return m[3]!;
      });
}

/// A stack frame that can return the [next] operation.
class _R {
  _R(this.code);
  final List<Object> code;
  var pc = 0;

  Object? next() => pc < code.length ? code[pc++] : null;

  @override
  String toString() => '$code:$pc';
}
