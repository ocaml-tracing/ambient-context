module type TLS = sig
  type 'a t

  val create : unit -> 'a t

  val get_exn : 'a t -> 'a

  val set : 'a t -> 'a -> unit
end

module TLS_atomic_map : TLS = struct
  module A = Ambient_context_atomic.Atomic

  type key = int

  let[@inline] get_key_ () : key = Thread.id (Thread.self ())

  module Key_map_ = Map.Make (struct
    type t = key

    let compare : t -> t -> int = compare
  end)

  type 'a t = 'a ref Key_map_.t A.t

  let create () : _ t = A.make Key_map_.empty

  let[@inline] get_exn (self : _ t) =
    let m = A.get self in
    let key = get_key_ () in
    !(Key_map_.find key m)

  let set_ref_ self key (r : _ ref) : unit =
    while
      let m = A.get self in
      let m' = Key_map_.add key r m in
      not (A.compare_and_set self m m')
    do
      Thread.yield ()
    done

  (* get or associate a reference to [key], and return it.
   Also return a function to remove the reference if we just created it. *)
  let get_or_create_ref_ (self : _ t) key ~v : _ ref * _ option =
    try
      let r = Key_map_.find key (A.get self) in
      let old = !r in
      r := v;
      r, Some old
    with Not_found ->
      let r = ref v in
      set_ref_ self key r;
      r, None

  let set (self : _ t) v : unit =
    let key = get_key_ () in
    let _, _ = get_or_create_ref_ self key ~v in
    ()
end

module Tls_lib : TLS = struct
  include Thread_local_storage
end

module B = Benchmark

open struct
  let run_on_domains f =
    let doms =
      Array.init (Domain.recommended_domain_count ()) (fun _i -> Domain.spawn f)
    in
    Array.iter Domain.join doms
end

module Bench_single_key = struct
  let mk (module Tls : TLS) (n : int) =
    let key : int Tls.t = Tls.create () in
    fun () ->
      run_on_domains @@ fun () ->
      for i = 1 to n do
        Tls.set key i;
        for _j = 1 to 3 do
          ignore (Sys.opaque_identity (Tls.get_exn key) : int)
        done
      done

  let bench : B.Tree.t =
    let open B.Tree in
    "single"
    @>> with_int
          (fun n ->
            Printf.sprintf "%d" n
            @> lazy
                 (B.throughputN 5
                    [
                      "map", mk (module TLS_atomic_map) n, ();
                      "tls", mk (module Tls_lib) n, ();
                    ]))
          [ 100; 1_000; 100_000 ]
end

module Bench_multi_key = struct
  let mk (module Tls : TLS) (n_keys : int) (n : int) =
    let keys : int Tls.t array = Array.init n_keys (fun _ -> Tls.create ()) in
    fun () ->
      run_on_domains @@ fun () ->
      for i = 1 to n do
        for k_idx = 0 to n_keys - 1 do
          let key = keys.(k_idx) in
          Tls.set key i;
          for _j = 1 to 3 do
            ignore (Sys.opaque_identity (Tls.get_exn key) : int)
          done
        done
      done

  let bench : B.Tree.t =
    let open B.Tree in
    "multi"
    @>> with_int
          (fun n_keys ->
            Printf.sprintf "%d_keys" n_keys
            @>> with_int
                  (fun n ->
                    Printf.sprintf "%d" n
                    @> lazy
                         (B.throughputN 5
                            [
                              "map", mk (module TLS_atomic_map) n_keys n, ();
                              "tls", mk (module Tls_lib) n_keys n, ();
                            ]))
                  [ 100; 1_000; 100_000 ])
          [ 2; 5; 10; 50 ]
end

let () =
  let open B.Tree in
  register ("tls" @>>> [ Bench_single_key.bench; Bench_multi_key.bench ]);
  B.Tree.run_global ()
