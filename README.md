# F

A forth-like stack-based programming language that can be paused and resumed at
any time. It compiles strings with a "high level" syntax to operations that can
be interpreted by an inner interpreter. (The compiler could probably be written
in F itself, but it's not yet.)

It's a stack-based language with reverse polish notation, so `3+4` is written as
`3 4 +`. Words are separated by whitespace. Numbers and strings in double quotes
are automatically pushed to the stack. All other words are operations that
operate on the stack, that is `+` pops two numbers, adds them, and pushes the
result back to the stack. Words in `[ ]` are so called _quotations_ that can be
invoked using `i`. For example, `[ 1 2 + ] i` pushes the quotation to the stack,
and `i` invokes it, which pushes `3` to the stack.

To define new words, use `:name` and a quotation, for example `:twice [ 2 * ]`.

To read and write global variables, use `@name` and `!name`. Actually, the
`:name [...]` syntax is just an abbreviation for `[ ... ] !name` which is an
abbreviation for `[ ... ] "name" !`.

Use `@a > 0 if "a is positive" else "a is negative" then .` to conditionally
execute code. The `else` part is optional. The `.` at the end prints the top
value of the stack. `if` is based on the `?` operator which expects a boolean
and two quotations on the stack and picks one of them depending on the boolean.
So the above `if` is an abbreviation for

    @a > 0 [ "a is positive" ] [ "a is negative" ] ? i .

Here's how to define `while`: It takes two quotations, one for the body and one
for the condition. It executes the body as long as the condition is true. Then
both quotations are removed from the stack.

    [ @x . @x 1 + !@ ] [ @x < 10 ] while

Here's the implementation (which requires the body not to modify the stack):

    :while [
        dup     ; duplicate condition
        i       ; invoke it
        [       ; if true
            ovr     ; duplicate body
            i       ; invoke it (this should not modify the stack)
            while   ; recurse
        ]
        [       ; else
            pop     ; remove condition
            pop     ; remove body
        ] ? i
    ]
