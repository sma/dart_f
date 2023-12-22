/// A simple stack-based language.
///
/// Call [start] to push a list of words to the runtime stack. Then call [step]
/// as long as it returns 1. If it returns 2, print the top of the stack. If it
/// returns 3, read a line of input and push it as an int. If it returns 0, you
/// are done. You can also call [run] or [runAsync] to run until you are done.
///
/// Use [push] or [pop] to manipulate the stack.
/// Use [popNum] to pop the top of the stack as a number.
///
/// Use [compile] to compile a string of code into a list of operations. Words
/// are separated by whitespace. Strings are enclosed in double quotes. Use `\\`
/// to escape characters. Quotations are enclosed in square brackets. Use `;` to
/// start a comment.
///
/// Use `f['name'] = F.impl((f) => ...);` to define a word using a Dart function.
/// Use `f['name'] = [...];` to define a word using a quotation (a Dart list of
/// objects). You can use `f['name'] = null` to undefine a word.
class F {
  final _r = <_R>[];
  final _data = <Object>[];
  final _vars = <String, Object>{
    't': impl((f) => f.push(true)),
    'f': impl((f) => f.push(false)),
    '?': impl((f) {
      final v2 = f.pop();
      final v1 = f.pop();
      final v0 = f.pop();
      f.push(v0 != 0 && v0 != false ? v1 : v2);
    }),
    '!': impl((f) => f[f.pop() as String] = f.pop()),
    '@': impl((f) => f.push(f[f.pop() as String] ?? (throw FException('undefined variable')))),
    '.': impl((f) => print(f.pop())),
    'i': impl((f) => f.start(_code(f.pop()))),
    'dup': impl((f) => f.push(f.tos)),
    'pop': impl((f) => f.pop()),
    '+': impl((f) => f.push(f.popNum() + f.popNum())),
    '-': impl((f) => f.push(-f.popNum() + f.popNum())),
    '*': impl((f) => f.push(-f.popNum() * f.popNum())),
    '/': impl((f) => f.push(1 / f.popNum() * f.popNum())),
    '=': impl((f) => f.push(f.pop() == f.pop())),
    '<': impl((f) => f.push(f.popNum() > f.popNum())),
  };

  /// Helps the type system infer the type of a function.
  static Object impl(void Function(F f) impl) => impl;

  /// Returns the top of the stack.
  Object get tos => _data.last;

  /// Pushes [value] to the stack.
  void push(Object value) => _data.add(value);

  /// Pops the top of the stack.
  Object pop() => _data.removeLast();

  /// Pops the top of the stack as a number.
  num popNum() => pop() as num;

  /// Returns the value of the variable [name] or `null` if it is not defined.
  Object? operator [](String name) => _vars[name];

  /// Sets variable [name] to [value]. Use `null` to remove a variable.
  void operator []=(String name, Object? value) {
    if (value == null) {
      _vars.remove(name);
    } else {
      _vars[name] = value;
    }
  }

  /// Runs until there is nothing left to do.
  void run([void Function(F f, int what)? callback]) {
    while (_r.isNotEmpty) {
      final what = step();
      callback?.call(this, what);
    }
  }

  /// Runs until there is nothing left to do.
  Future<void> runAsync(Future<void> Function(F f, int what) callback) async {
    while (_r.isNotEmpty) {
      await callback(this, step());
    }
  }

  /// Executes one instruction. Then signals how to proceed.
  /// + 0 means that nothing is left to do.
  /// + 1 means that the caller should call again.
  /// + 2 means that the caller should print the top of the stack.
  /// + 3 means that the caller should read a line of input.
  int step() {
    Object? word;
    do {
      if (_r.isEmpty) return 0;
      word = _r.last.next();
      if (word == null) _r.removeLast();
    } while (word == null);

    if (word is String) {
      if (word.length > 1 && word.startsWith('"')) {
        push(word.substring(1));
        return 1;
      }
      if (word.length > 1 && (word.startsWith('@') || word.startsWith('!'))) {
        push(word.substring(1));
        word = word.substring(0, 1);
      }
      final v = _vars[word];
      if (v != null) {
        if (v is List<Object>) {
          start(v);
          return 1;
        }
        if (v is void Function(F)) {
          v(this);
          return 1; // TODO: return different state
        }
        throw FException('uninvokable word $word');
      }
      final n = num.tryParse(word);
      if (n != null) {
        push(n);
      } else {
        throw FException('undefined word $word');
      }
    } else {
      push(word);
    }
    return 1;
  }

  /// Compiles [input] into a quotation and starts it.
  void compile(String input) {
    void c(Object w) => _code(tos).add(w);
    push(<Object>[]);
    final base = _data.length;
    for (final w in _re1.allMatches(input).map((m) => _unescape(m[1]) ?? m[0]!)) {
      if (w.startsWith(';')) continue;
      if (w == '[') {
        push(<Object>[]);
      } else if (w == ']') {
        if (_data.length == base) throw FException('missing [');
        c(pop());
      } else {
        c(num.tryParse(w) ?? w);
      }
    }
    if (_data.length != base) throw FException('missing ]');
    start(_code(pop()));
  }

  /// Starts a new quotation.
  void start(List<Object> code) => _r.add(_R(code));

  /// Replaces `\\` escapes in [s] and returns the result.
  static String? _unescape(String? s) {
    return s?.replaceAllMapped(_re2, (m) {
      final u = m[1] ?? m[2];
      if (u != null) return String.fromCharCode(int.parse(u, radix: 16));
      final e = m[3]!;
      if (e == 'n') return '\n';
      if (e == 'r') return '\r';
      if (e == 't') return '\t';
      return e;
    });
  }

  static final _re1 = RegExp(r';.*$|("(?:\\.|[^"])*)"|[^\s;"[\]]+|\S+', multiLine: true);
  static final _re2 = RegExp(r'\\(?:u\{([\da-fA-F]{1,6})\}|u([\da-fA-F]{4})|(.))');

  /// Casts [value] into a quotation.
  static List<Object> _code(Object value) {
    if (value is List<Object>) return value;
    throw FException('not code: $value');
  }
}

/// A stack frame that can return the [next] operation.
class _R {
  _R(this.code);
  final List<Object> code;
  var pc = 0;

  /// Returns the next operation or `null` if there are no more operations.
  Object? next() => pc < code.length ? code[pc++] : null;

  @override
  String toString() => '$code:$pc';
}

class FException implements Exception {
  FException(this.message);
  final String message;

  @override
  String toString() => message;
}

Future<void> main() async {
  final f = F();
  f.compile('[ 3 4 + ] i');
  print(f._r);
  f.run();
  print(f.pop());
  f.compile('[ dup 0 = [ pop 1 ] [ dup 1 - fac * ] ? i ] "fac" !');
  print(f._r);
  f.run();
  f.compile('10 fac .');
  f.run();
  f['.'] = F.impl((f) => print('#> ${f.pop()}'));
  f.start(['"Hallo, Welt', '.']);
  await f.runAsync((f, w) async {});
}
