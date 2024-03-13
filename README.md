# F

A forth-like stack-based programming language that can be paused and resumed at any time. It compiles strings of "high level" syntax "low level" into operations that are executed by an _inner interpreter_. (The compiler could probably be written in F itself, but it isn't yet.)

The language uses reverse polish notation, so `3+4` is written as `3 4 +`. Words are separated by whitespace or square brackets. Numbers and strings in double are automatically pushed to the stack as literals. Strings support the usual _escape sequences_, such as `\n` for newline. All other words operate on the stack, i.e. `+` pops two numbers, adds them and pushes the result back to the stack. The `.` at the end prints the top value of the stack (also called _tos_).

Words in `[ ]` form a so called _quotation_, which can be invoked using `i`. For example, `[ 1 2 + ] i` pushes the quotation to the stack, and `i` removes and invokes it, which in turn pushes `3` to the stack.

To read and write global variables, use `@name` (a so called _get word_) and `!name` (a _set word_). Actually, `@name` is just an abbreviation for `"name" @` and `!name` is an abbreviation for `"name" !`.

To define new words, use a quotation and assign it to a variable, for example `[ 2 * ] !twice`. Words can be recursive, like `[ dup 0= [1] [1 - fac] if ] !fac`.

Use `cond [..] [..] if` to conditionally execute code. The `if` expects a boolean and two quotations on the stack and pops all of them, invoking the first or second quotations based on the boolean. Use `when` if there's no "else" part. That's a shorthand for `[] if`. Use `unless` if there's no "then" part. The `if` is a shorthand for using `?` to pick one of two values based on a condition combined with `i` to
invoke a block.

    if ( f qt qf -- ) == ? i
    when ( f qt -- ) == [] if
    unless ( f qf -- ) == [] swp if

Use `cond body while` to execute code in a loop while a condition is true. Use `until` to execute body until a condition is true. Use `loop` to execute a single quotation that should leave true or false on the stack.

Here's how to use `while`:

    [ @x < 10 ] [ @x . @x 1 + !@ ] while

Here's the implementation (which requires the body `qc` not to modify the stack):

    while (qc qb -- ) ==
        ovr     ; duplicate condition
        i       ; invoke it
        [       ; if true
            dup     ; duplicate body
            i       ; invoke it (this should not modify the stack)
            while   ; recurse
        ]
        [       ; else
            pop     ; remove condition
            pop     ; remove body
        ] ? i
