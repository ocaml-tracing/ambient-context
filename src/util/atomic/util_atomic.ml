(** Update loop *)
let update_cas (type res) (self : 'a Atomic.t) (f : 'a -> res * 'a) : res =
  let exception Ret of res in
  try
    while true do
      let old_val = Atomic.get self in
      let res, new_val = f old_val in
      if Atomic.compare_and_set self old_val new_val then
        raise_notrace (Ret res)
    done;
    assert false
  with Ret r -> r
