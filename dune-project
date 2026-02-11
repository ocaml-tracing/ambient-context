(lang dune 3.0)

(name ambient-context)

(generate_opam_files true)

(version 0.2)

(source
 (github ocaml-tracing/ocaml-ambient-context))

(authors ELLIOTTCABLE "c-cube")

(maintainers "ELLIOTTCABLE <opam@ell.io>" "c-cube")

(license MIT)

(package
 (name ambient-context)
 (synopsis
  "Abstraction over thread-local / continuation-local storage mechanisms for communication with transitive dependencies")
 (depends
  (ocaml
   (>= 4.08))
  hmap
  (alcotest :with-test)
  (bisect_ppx :with-test)
  (odig :with-doc)
  (ocaml-lsp-server :with-dev-setup)
  (benchmark :with-dev-setup)
  (ocamlformat
   (and
    :with-dev-setup
    (>= 0.27)
    (< 0.28))))
 (conflicts
  (thread-local-storage
   (< 0.2)))
 (depopts thread-local-storage))

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
