Demonstrate error messages embedding sexp and dyn data.

  $ ./main.exe sexp-and-dyn --color=never
  Error: Invalid configuration.
  (config (timeout 30) (retries 3))
  
  Error: Unexpected value.
  { name = "widget"; count = 42; tags = [ "alpha"; "beta" ] }
  
  Error: Multiple embedded values.
  (config (timeout 30) (retries 3))
  { name = "widget"; count = 42; tags = [ "alpha"; "beta" ] }
  Hint: Check the config file.
  [123]


