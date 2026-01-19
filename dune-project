(lang dune 3.6)

(name ambient-context)
(generate_opam_files true)
(version 0.1.1)
(source
 (github ocaml-tracing/ambient-context))
(authors ELLIOTTCABLE)
(maintainers "ELLIOTTCABLE <opam@ell.io>")
(license MIT)

(package
 (name ambient-context)
 (synopsis
  "Abstraction over thread-local / continuation-local storage mechanisms for communication with transitive dependencies")
 (depends
  (ocaml
   (>= 4.08))
  (alcotest :with-test)
  (bisect_ppx :with-test)
  (odig :with-doc)
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat
   (and
    :with-dev-setup
    (>= 0.24)
    (< 0.25))))
 (depopts hmap))

(package
 (name ambient-context-lwt)
 (synopsis
  "Storage backend for ambient-context using Lwt's sequence-associated storage")
 (depends
  (ocaml
   (>= 4.08))
  (ambient-context
   (= :version))
  lwt
  (alcotest :with-test)
  (alcotest-lwt :with-test)
  (bisect_ppx :with-test)))

(package
 (name ambient-context-eio)
 (synopsis
  "Storage backend for ambient-context using Eio's continuation-local storage")
 (depends
  (ocaml
   (>= 5.0))
  (ambient-context
   (= :version))
  eio
  (alcotest :with-test)
  (alcotest-lwt :with-test)
  (bisect_ppx :with-test)))
