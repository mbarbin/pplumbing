(lang dune 3.17)

(name pplumbing)

(generate_opam_files)

(license MIT)

(authors "Mathieu Barbin")

(maintainers "Mathieu Barbin <opensource@mbarbin.org>")

(source
 (github mbarbin/pplumbing))

(documentation "https://mbarbin.github.io/pplumbing/")

(using mdx 0.4)

(implicit_transitive_deps false)

(package
 (name pplumbing)
 (synopsis "Utility libraries to use with [pp]")
 (depends
  (ocaml
   (>= 4.14))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (fmt
   (>= 0.9.0))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.7.0))
  (ordering
   (>= 3.17))
  (parsexp
   (>= v0.16))
  (pp
   (>= 2.0.0))
  (sexplib0
   (>= v0.16))
  (stdune
   (>= 3.17))))

(package
 (name pplumbing-tests)
 (synopsis "Tests for pplumbing")
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (and
    (>= v0.17)
    (< v0.18)))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (expect_test_helpers_core
   (and
    (>= v0.17)
    (< v0.18)))
  (fmt
   (>= 0.9.0))
  (fpath
   (>= 0.7.3))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.7.0))
  (mdx
   (>= 2.4))
  (ordering
   (>= 3.17))
  (parsexp
   (and
    (>= v0.17)
    (< v0.18)))
  (pp
   (>= 2.0.0))
  (pplumbing
   (= :version))
  (ppx_compare
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_enumerate
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_expect
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_hash
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_here
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)
    (< v0.18)))
  (ppx_let
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_conv
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_value
   (and
    (>= v0.17)
    (< v0.18)))
  (ppxlib
   (>= 0.33))
  (sexplib0
   (and
    (>= v0.17)
    (< v0.18)))
  (stdio
   (and
    (>= v0.17)
    (< v0.18)))
  (stdune
   (>= 3.17))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))

(package
 (name pplumbing-dev)
 (synopsis
  "Package to regroup dev targets for the pplumbing project, documentation, and more")
 (allow_empty) ; The package is attached to stanza in doc/ however dune doesn't see it.
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (and
    (>= v0.17)
    (< v0.18)))
  (bisect_ppx
   (and
    :with-dev-setup
    (>= 2.8.3)))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (expect_test_helpers_core
   (and
    (>= v0.17)
    (< v0.18)))
  (fmt
   (>= 0.9.0))
  (fpath
   (>= 0.7.3))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.7.0))
  (mdx
   (>= 2.4))
  (ordering
   (>= 3.17))
  (parsexp
   (and
    (>= v0.17)
    (< v0.18)))
  (pp
   (>= 2.0.0))
  (pplumbing
   (= :version))
  (pplumbing-tests
   (= :version))
  (ppx_compare
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_enumerate
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_expect
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_hash
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_here
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)
    (< v0.18)))
  (ppx_let
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_conv
   (and
    (>= v0.17)
    (< v0.18)))
  (ppx_sexp_value
   (and
    (>= v0.17)
    (< v0.18)))
  (ppxlib
   (>= 0.33))
  (sexplib0
   (and
    (>= v0.17)
    (< v0.18)))
  (stdio
   (and
    (>= v0.17)
    (< v0.18)))
  (stdune
   (>= 3.17))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))
