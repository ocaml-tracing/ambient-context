open Alcotest
module Ctx = Ambient_context

let test_create_key () =
  let _k = Ctx.new_key () in
  ()

let test_set_then_get () =
  let k = Ctx.new_key () in
  Ctx.with_key_bound_to k "hello" @@ fun () ->
  let v = Ctx.get k in
  check (option string) "retrieve same string" v (Some "hello")

let test_set_then_unset () =
  let k = Ctx.new_key () in
  Ctx.with_key_bound_to k "hello" @@ fun () ->
  let v = Ctx.get k in
  check (option string) "retrieve same string" v (Some "hello");
  Ctx.with_key_unbound k @@ fun () ->
  let v = Ctx.get k in
  check (option string) "retrieve nothing" v None

let suite =
  [
    "can create keys", `Quick, test_create_key;
    "can set, and get, keys", `Quick, test_set_then_get;
    "can unset keys", `Quick, test_set_then_unset;
  ]
