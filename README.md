# F

A forth-like stack-based programming language that can be paused and resumed at
any time. It compiles strings with a "high level" syntax into operations that
can be interpreted by an _inner interpreter_. (The compiler could probably be
written in F itself, but it's not yet.)

The language uses reverse polish notation, so `3+4` is written as `3 4 +`. Words
are separated by whitespace or square brackets. Numbers and strings in double
quotes are automatically pushed to the stack as literals. Strings support the
usual _escape sequences_ like `\n` for newline. All other words are operations
that operate on the stack, that is `+` pops two numbers, adds them, and pushes
the result back to the stack. The `.` at the end prints the top value of the
stack (also called _tos_).

Words in `[ ]` form a so called _quotation_ that can be invoked using `i`. For
example, `[ 1 2 + ] i` pushes the quotation to the stack, and `i` removes and
invokes it, which in turn pushes `3` to the stack.

To read and write global variables, use `@name` (a so called _get word_) and
`!name` (_set word_). Actually, `@name` is just an abbreviation for `"name" @`
and `!name` for `"name" !`.

To define new words, use a quotation and assign it to a variable, for example
`[ 2 * ] !twice`. Words can be recursive.

Use `cond [..] [..] if` to conditionally execute code. Use `when` if there's no
"else" part. Use `unless` if there's no "then" part. The `if` is a shorthand for
using `?` to pick one of two values based on a condition combined with `i` to
invoke a block.

    if ( f qt q2 -- ) == ? i
    when ( f qt -- ) == [] if
    unless ( f qt -- ) == [] swp if

Use `cond body while` to execute code in a loop while a condition is true. Use
`until` to execute body until a condition is true. Use `loop` to execute a
single quotation that should return true or false.

Here's how to define `while`: It takes two quotations, one for the body and one
for the condition. It executes the body as long as the condition is true. Then
both quotations are removed from the stack.

    [ @x < 10 ] [ @x . @x 1 + !@ ] while

Here's the implementation (which requires the body not to modify the stack):

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
