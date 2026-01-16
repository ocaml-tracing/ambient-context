open Alcotest
open Lwt.Syntax
module Ctx = Ambient_context

let show_option o = Option.value ~default:"<none>" o

let test_set_storage_provider _ () =
  Ctx.set_current_storage Ambient_context_lwt.storage;
  Ctx.set_current_storage Ctx.default_storage;
  Lwt.return ()

let test_sequenced_storage _ () =
  Ctx.set_current_storage Ambient_context_lwt.storage;
  let k = Ctx.new_key () in

  let setter_sequence_1 =
    (* The set has to happen inside a Lwt context; *)
    let* () = Lwt.return () in
    (* inside which we set the value immediately ... *)
    Printf.printf "[1] set value to 'foo'\n%!";
    Ctx.with_key_bound_to k "foo" @@ fun () ->
    let* () = Lwt_unix.sleep 3. in

    (* ... then, after three seconds, we get the value *inside* the sequence. *)
    let v = Ctx.get k in
    Printf.printf "[1] got value '%s'\n%!" (show_option v);
    Lwt.return
    @@ check' (option string) ~msg:"first value retained" ~actual:v
         ~expected:(Some "foo")
  in

  let setter_sequence_2 =
    (* Now, the same again, but with 1/1 seconds, resp. *)
    let* () = Lwt_unix.sleep 1. in
    Printf.printf "[2] set value to 'bar'\n%!";
    Ctx.with_key_bound_to k "bar" @@ fun () ->
    let* () = Lwt_unix.sleep 1. in

    let v = Ctx.get k in
    Printf.printf "[2] got value '%s'\n%!" (show_option v);
    Lwt.return
    @@ check' (option string) ~msg:"second value retained" ~actual:v
         ~expected:(Some "bar")
  in
  let* (), () = Lwt.both setter_sequence_1 setter_sequence_2 in
  Lwt.return ()

let suite =
  Alcotest_lwt.
    [
      test_case "can set storage provider" `Quick test_set_storage_provider;
      test_case "test sequenced storage" `Slow test_sequenced_storage;
    ]

let () = Lwt_main.run @@ Alcotest_lwt.run "Unix" [ "Lwt", suite ]
