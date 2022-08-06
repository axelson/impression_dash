# Used by "mix format"
[
  import_deps: [:typed_struct],
  plugins: [
    FreedomFormatter,
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],

  # Freedom Formatter options
  trailing_comma: true,
]
