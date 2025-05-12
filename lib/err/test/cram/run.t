Exercising the error handling from the command line.

  $ cat > file << EOF
  > Hello World
  > EOF

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 0 --length 5 \
  > --level=error
  File "file", line 1, characters 0-5:
  1 | Hello World
      ^^^^^
  Error: error message
  [123]

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=warning
  File "file", line 1, characters 6-11:
  1 | Hello World
            ^^^^^
  Warning: warning message

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=warning \
  > --warn-error
  File "file", line 1, characters 6-11:
  1 | Hello World
            ^^^^^
  Warning: warning message
  [123]

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=info

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=info \
  > --verbose
  File "file", line 1, characters 6-11:
  1 | Hello World
            ^^^^^
  Info: info message

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=debug \
  > --verbose

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 6 --length 5 \
  > --level=debug \
  > --verbosity=debug
  File "file", line 1, characters 6-11:
  1 | Hello World
            ^^^^^
  Debug: debug message

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 0 --length 5 \
  > --raise 2>&1 | head -n 1
  Internal Error: Failure("Raising an exception!")

Logs and Fmt options.

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 0 --length 5 \
  > --level=error \
  > --color=always
  File "file", line 1, characters 0-5:
  1 | Hello World
      ^^^^^
  Error: error message
  [123]

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 0 --length 5 \
  > --level=error \
  > --color=never
  File "file", line 1, characters 0-5:
  1 | Hello World
      ^^^^^
  Error: error message
  [123]

When the log level is 'quiet', even errors should not be shown.

  $ ./main.exe write --file file --line 1 --pos-bol 0 \
  > --pos-cnum 0 --length 5 \
  > --level=error \
  > --verbosity=quiet

The rendering part works as expected for emitted errors, however currently we
note a potential source of confusion: since errors are disabled due to the quiet
log level, they are not accounted for at all in the exit code.

We are keeping this as characterization here, however this may be subject to
change in future versions.
