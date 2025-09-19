Exercising some behavior of the Logs library for reference.

By default app, err, and warn messages are enabled.

  $ ./main.exe logs
  Hello app
  main.exe: [ERROR] Hello err
  main.exe: [WARNING] Hello warn
  [1]

  $ ./main.exe logs --no-error
  Hello app
  main.exe: [WARNING] Hello warn

All messages are enabled in debug mode.

  $ ./main.exe logs --verbosity=debug
  Hello app
  main.exe: [ERROR] Hello err
  main.exe: [WARNING] Hello warn
  main.exe: [INFO] Hello info
  main.exe: [DEBUG] Hello debug
  [1]

In app mode, the errors are silenced.

  $ ./main.exe logs --verbosity=app
  Hello app
  [1]

When in quiet mode, all outputs are silenced.

  $ ./main.exe logs --verbosity=quiet
  [1]

We note that the exit code is still [1] to account for the error, even though it
was not printed. This changed in `logs.0.9.0` - keeping as regression test.
