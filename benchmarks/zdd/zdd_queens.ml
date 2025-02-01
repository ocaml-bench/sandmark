(** A simple implementation of ZDDs (Reduced Ordered Zero-Suppressed Binary
    Decision Diagrams).

    Josh Berdine, based on:

    Shin-ichi Minato: Zero-Suppressed BDDs for Set Manipulation in
    Combinatorial Problems. DAC 1993: 272-277

    Shin-ichi Minato: Calculation of Unate Cube Set Algebra Using
    Zero-Suppressed BDDs. DAC 1994: 420–424

    Donald Ervin Knuth: The Art of Computer Programming. Volume 4a
    Combinatorial Algorithms Part 1. Addison-Wesley 2011. *)

include struct
  [@@@warning "-unused-value-declaration"]

  external ( = ) : int -> int -> bool = "%equal"
  external ( <> ) : int -> int -> bool = "%notequal"
  external ( < ) : int -> int -> bool = "%lessthan"
  external ( > ) : int -> int -> bool = "%greaterthan"
  external ( <= ) : int -> int -> bool = "%lessequal"
  external ( >= ) : int -> int -> bool = "%greaterequal"
  external compare : int -> int -> int = "%compare"
  external equal : int -> int -> bool = "%equal"

  let min x y = if x <= y then x else y
  let max x y = if x >= y then x else y
end

let memo_hc =
  match Sys.getenv_opt "MEMO_HC" with
  | None -> 2
  | Some s -> (
    match int_of_string s with
    | (0 | 1 | 2) as n -> n
    | _ | (exception Failure _) -> invalid_arg ("invalid MEMO_HC: " ^ s) )

let memo_op =
  match Sys.getenv_opt "MEMO_OP" with
  | None -> 2
  | Some s -> (
    match int_of_string s with
    | (0 | 1 | 2) as n -> n
    | _ | (exception Failure _) -> invalid_arg ("invalid MEMO_OP: " ^ s) )

let memo_scale =
  match Sys.getenv_opt "MEMO_SCALE" with
  | None -> 1
  | Some s -> (
    try int_of_string s
    with Failure _ -> invalid_arg ("invalid MEMO_SCALE: " ^ s) )

let scale size = size * memo_scale

(*
 * Core ZDD representation
 *)

type order = LT | EQ | GT

module Elt = struct
  type t = int * int

  let compare (c, r) (d, s) =
    match Int.compare c d with 0 -> Int.compare r s | n -> n

  let order x y =
    let i = compare x y in
    if i < 0 then LT else if i = 0 then EQ else GT

  let ( < ) x y = compare x y < 0
  let equal (c, r) (d, s) = Int.equal c d && Int.equal r s
  let hash = Hashtbl.hash
end

module T = struct
  type t =
    | Empty  (** the empty family: ∅ *)
    | Unit  (** the unit family: {∅} *)
    | Ite of {v: Elt.t; t: t; e: t; hash: int}
        (** a decision: {{v} ∪ p | p ∈ t} ∪ e, aka v⊔t ∪ e *)

  let equal : t -> t -> bool = if memo_hc = 0 then Stdlib.( = ) else ( == )
  let ( == ) = equal

  let hash = function
    | Empty -> Hashtbl.hash 0
    | Unit -> Hashtbl.hash 1
    | Ite {hash; _} -> hash
end

include T

module H = struct
  type t = T.t

  let equal p0 q0 =
    match (p0, q0) with
    | Ite p, Ite q -> p.e == q.e && p.t == q.t && Elt.equal p.v q.v
    | _ -> p0 == q0

  let hash = T.hash
end

(*
 * Inline fragment of Weak.Make so same code is used across OCaml versions
 *)

(* module WeakSet = Weak.Make (H) *)

module WeakSet : sig
  type data = H.t
  type t

  val create : int -> t
  val merge : t -> data -> data
  val stats : t -> int * int * int * int * int * int
end = struct
  open Weak

  let additional_values = 2 (* CAML_EPHE_FIRST_KEY in weak.h *)

  type 'a weak_t = 'a t

  let weak_create = create
  let emptybucket = weak_create 0

  type data = H.t

  type t =
    { mutable table: data weak_t array
    ; mutable hashes: int array array
    ; mutable limit: int (* bucket size limit *)
    ; mutable oversize: int (* number of oversize buckets *)
    ; mutable rover: int (* for internal bookkeeping *) }

  let get_index t h = h land max_int mod Array.length t.table
  let limit = 7
  let over_limit = 2

  let create sz =
    let sz = if sz < 7 then 7 else sz in
    let sz =
      if sz > Sys.max_array_length then Sys.max_array_length else sz
    in
    { table= Array.make sz emptybucket
    ; hashes= Array.make sz [||]
    ; limit
    ; oversize= 0
    ; rover= 0 }

  let iter_weak f t =
    let rec iter_bucket i j b =
      if i >= length b then ()
      else
        match check b i with
        | true ->
            f b t.hashes.(j) i ;
            iter_bucket (i + 1) j b
        | false -> iter_bucket (i + 1) j b
    in
    Array.iteri (iter_bucket 0) t.table

  let rec count_bucket i b accu =
    if i >= length b then accu
    else count_bucket (i + 1) b (accu + if check b i then 1 else 0)

  let count t = Array.fold_right (count_bucket 0) t.table 0
  let next_sz n = min ((3 * n / 2) + 3) Sys.max_array_length
  let prev_sz n = (((n - 3) * 2) + 2) / 3

  let test_shrink_bucket t =
    let bucket = t.table.(t.rover) in
    let hbucket = t.hashes.(t.rover) in
    let len = length bucket in
    let prev_len = prev_sz len in
    let live = count_bucket 0 bucket 0 in
    if live <= prev_len then (
      let rec loop i j =
        if j >= prev_len then
          if check bucket i then loop (i + 1) j
          else if check bucket j then (
            blit bucket j bucket i 1 ;
            hbucket.(i) <- hbucket.(j) ;
            loop (i + 1) (j - 1) )
          else loop i (j - 1)
      in
      loop 0 (length bucket - 1) ;
      ( if prev_len = 0 then (
        t.table.(t.rover) <- emptybucket ;
        t.hashes.(t.rover) <- [||] )
      else
        let newbucket = weak_create prev_len in
        blit bucket 0 newbucket 0 prev_len ;
        t.table.(t.rover) <- newbucket ;
        t.hashes.(t.rover) <- Array.sub hbucket 0 prev_len ) ;
      if len > t.limit && prev_len <= t.limit then
        t.oversize <- t.oversize - 1 ) ;
    t.rover <- (t.rover + 1) mod Array.length t.table

  let rec resize t =
    let oldlen = Array.length t.table in
    let newlen = next_sz oldlen in
    if newlen > oldlen then (
      let newt = create newlen in
      let add_weak ob oh oi =
        let setter nb ni _ = blit ob oi nb ni 1 in
        let h = oh.(oi) in
        add_aux newt setter None h (get_index newt h)
      in
      iter_weak add_weak t ;
      t.table <- newt.table ;
      t.hashes <- newt.hashes ;
      t.limit <- newt.limit ;
      t.oversize <- newt.oversize ;
      t.rover <- t.rover mod Array.length newt.table )
    else (
      t.limit <- max_int ;
      (* maximum size already reached *)
      t.oversize <- 0 )

  and add_aux t setter d h index =
    let bucket = t.table.(index) in
    let hashes = t.hashes.(index) in
    let sz = length bucket in
    let i = ref 0 in
    while !i < sz && check bucket !i do
      incr i
    done ;
    if !i < sz then (
      setter bucket !i d ;
      hashes.(!i) <- h )
    else
      let newsz =
        min ((3 * sz / 2) + 3) (Sys.max_array_length - additional_values)
      in
      if newsz <= sz then failwith "Weak.Make: hash bucket cannot grow more" ;
      let newbucket = weak_create newsz in
      let newhashes = Array.make newsz 0 in
      blit bucket 0 newbucket 0 sz ;
      Array.blit hashes 0 newhashes 0 sz ;
      setter newbucket sz d ;
      newhashes.(sz) <- h ;
      t.table.(index) <- newbucket ;
      t.hashes.(index) <- newhashes ;
      if sz <= t.limit && newsz > t.limit then (
        t.oversize <- t.oversize + 1 ;
        for _i = 0 to over_limit do
          test_shrink_bucket t
        done ) ;
      if t.oversize > Array.length t.table / over_limit then resize t

  (* General auxiliary function for searching for a particular value
   * in a hash-set, and acting according to whether or not it's found *)

  let find_aux t d k_found k_notfound =
    let h = H.hash d in
    let index = get_index t h in
    let bucket = t.table.(index) in
    let hashes = t.hashes.(index) in
    let sz = length bucket in
    let found = ref None in
    let i = ref 0 in
    while !i < sz && Option.is_none !found do
      if h = hashes.(!i) then
        match get bucket !i with
        | Some v as opt -> if H.equal v d then found := opt else incr i
        | _ -> incr i
      else incr i
    done ;
    match !found with
    | Some v as opt -> k_found bucket !i opt v
    | None -> k_notfound h index

  let merge t d =
    find_aux t d
      (fun _b _i _o v -> v)
      (fun h i ->
        add_aux t set (Some d) h i ;
        d )

  let stats t =
    let len = Array.length t.table in
    let lens = Array.map length t.table in
    Array.sort compare lens ;
    let totlen = Array.fold_left ( + ) 0 lens in
    (len, count t, totlen, lens.(0), lens.(len / 2), lens.(len - 1))
end

(*
 * Unique table
 *)

let hashtbl_stats stats =
  let Hashtbl.
        { num_bindings= num
        ; num_buckets= len
        ; max_bucket_length= max_len
        ; bucket_histogram= histo } =
    stats
  in
  let sum_len = ref 0 in
  let min_len = ref 0 in
  let med_len = ref 0 in
  for i = 0 to max_len do
    if !min_len = 0 && histo.(i) > 0 then min_len := i ;
    sum_len := !sum_len + histo.(i) ;
    if !med_len = 0 && !sum_len >= num / 2 then med_len := i
  done ;
  (len, num, !sum_len, !min_len, !med_len, max_len)

let print_stats label (len, num, sum, min, med, max) =
  if num > 0 then
    Format.eprintf
      "%s length: %i entries: %i bucket lengths: sum: %i min: %i median: \
       %i max: %i@\n"
      label len num sum min med max

module type Unique = sig
  type t

  val create : int -> string -> t
  val merge : t -> T.t -> T.t
end

module NoUnique : Unique = struct
  type t = unit

  let create _ _ = ()
  let merge () p = p
end

module HashUnique : Unique = struct
  module Tbl = Hashtbl.Make (H)

  type t = T.t Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let merge tbl elt =
    match Tbl.find_opt tbl elt with
    | Some elt -> elt
    | None ->
        Tbl.add tbl elt elt ;
        elt
end

module WeakUnique : Unique = struct
  include WeakSet

  let create size label =
    let tbl = create (scale size) in
    at_exit (fun () -> print_stats label (stats tbl)) ;
    tbl
end

let unique : (module Unique) =
  match memo_hc with
  | 0 -> (module NoUnique)
  | 1 -> (module HashUnique)
  | 2 -> (module WeakUnique)
  | _ -> assert false

module Unique = (val unique)

let unique_set = Unique.create 2048 "unique set"

let unique v ~t ~e =
  if t == Empty then e
  else
    let hash = Hashtbl.hash (2, Elt.hash v, T.hash e, T.hash t) in
    let node = Ite {v; t; e; hash} in
    Unique.merge unique_set node

(*
 * Memoization tables for operations
 *)

module type MemoT = sig
  type 'a t

  val create : int -> string -> 'a t
  val find_or_add : 'a t -> T.t -> (T.t -> 'a) -> 'a
end

module NoMemoT : MemoT = struct
  type 'a t = unit

  let create _ _ = ()
  let find_or_add () p k = k p
end

module HashMemoT : MemoT = struct
  module Tbl = Hashtbl.Make (T)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p k =
    match Tbl.find_opt tbl p with
    | Some r -> r
    | None ->
        let r = k p in
        Tbl.add tbl p r ;
        r
end

module EpheMemoT : MemoT = struct
  module Tbl = Ephemeron.K1.Make (T)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p k =
    match Tbl.find_opt tbl p with
    | Some r -> r
    | None ->
        let r = k p in
        Tbl.add tbl p r ;
        r
end

let memoT : (module MemoT) =
  match memo_op with
  | 0 -> (module NoMemoT)
  | 1 -> (module HashMemoT)
  | 2 -> (module EpheMemoT)
  | _ -> assert false

module MemoT = (val memoT)

module type MemoTT = sig
  type 'a t

  val create : int -> string -> 'a t
  val find_or_add : 'a t -> T.t -> T.t -> (T.t -> T.t -> 'a) -> 'a
end

module NoMemoTT : MemoTT = struct
  type 'a t = unit

  let create _ _ = ()
  let find_or_add () p q k = k p q
end

module HashMemoTT : MemoTT = struct
  module Tbl = Hashtbl.Make (struct
    type t = T.t * T.t

    let equal (p, q) (r, s) = p == r && q == s
    let hash = Hashtbl.hash
  end)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p q k =
    match Tbl.find_opt tbl (p, q) with
    | Some r -> r
    | None ->
        let r = k p q in
        Tbl.add tbl (p, q) r ;
        r
end

module EpheMemoTT : MemoTT = struct
  module Tbl = Ephemeron.K2.Make (T) (T)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p q k =
    match Tbl.find_opt tbl (p, q) with
    | Some r -> r
    | None ->
        let r = k p q in
        Tbl.add tbl (p, q) r ;
        r
end

let memoTT : (module MemoTT) =
  match memo_op with
  | 0 -> (module NoMemoTT)
  | 1 -> (module HashMemoTT)
  | 2 -> (module EpheMemoTT)
  | _ -> assert false

module MemoTT = (val memoTT)

module type MemoIT = sig
  type 'a t

  val create : int -> string -> 'a t
  val find_or_add : 'a t -> int -> T.t -> (int -> T.t -> 'a) -> 'a
end

module NoMemoIT : MemoIT = struct
  type 'a t = unit

  let create _ _ = ()
  let find_or_add () n q k = k n q
end

module HashMemoIT : MemoIT = struct
  module Tbl = Hashtbl.Make (struct
    type t = int * T.t

    let equal (m, p) (n, q) = m = n && p == q
    let hash = Hashtbl.hash
  end)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p q k =
    match Tbl.find_opt tbl (p, q) with
    | Some r -> r
    | None ->
        let r = k p q in
        Tbl.add tbl (p, q) r ;
        r
end

module EpheMemoIT : MemoIT = struct
  module Tbl =
    Ephemeron.K2.Make
      (struct
        type t = int

        let equal m n = m = n
        let hash = Hashtbl.hash
      end)
      (T)

  type 'a t = 'a Tbl.t

  let create size label =
    let tbl = Tbl.create (scale size) in
    at_exit (fun () -> print_stats label (hashtbl_stats (Tbl.stats tbl))) ;
    tbl

  let find_or_add tbl p q k =
    match Tbl.find_opt tbl (p, q) with
    | Some r -> r
    | None ->
        let r = k p q in
        Tbl.add tbl (p, q) r ;
        r
end

let memoIT : (module MemoIT) =
  match memo_op with
  | 0 -> (module NoMemoIT)
  | 1 -> (module HashMemoIT)
  | 2 -> (module EpheMemoIT)
  | _ -> assert false

module MemoIT = (val memoIT)

(*
 * ZDD constructors and operations
 *)

(** ∅ *)
let empty = Empty

(** {∅} *)
let unit = Unit

(** {{v}} *)
let elem v = unique v ~t:Unit ~e:Empty

(** [div1 f v] is [f/{{v}}], the quotient of division of family [f] by
    elementary family [{{v}}]. That is, [f/{{v}}] is the elements of [f]
    that contain [v], with [v] removed.

    Similarly, [rem1 f v] is [f%{{v}}] the remainder of division of family
    [f] by elementary family [{{v}}]. That is, [f%{{v}}] is the elements of
    [f] that do not contain [v].

    [div1] and [rem1] are the elementary special cases of general division
    [div] and remainder [rem]. Division and remainder satisfy the equation:
    [f = g⊔(f/g) ∪ (f%g)]. *)

let div1_tbl = MemoT.create 1 "div1 memo table"

(** [f/{{w}}], written [f/w], = [{ p-w | w ∈ p ∈ f }], or equivalently
    [{q | q ∪ {w} ∈ f and q ∩ {w} = ∅}] *)
let rec div1 f w =
  match f with
  | Empty ->
      (* ∅/w = ∅ *)
      Empty
  | Unit ->
      (* {∅}/w = ∅ *)
      Empty
  | Ite i -> (
    match Elt.order i.v w with
    | GT ->
        (* v > w => (v⊔t ∪ e)/w = ∅ *)
        Empty
    | EQ ->
        (* (w⊔t ∪ e)/w = t *)
        i.t
    | LT -> div1_memo f w )

and div1_memo f w =
  MemoT.find_or_add div1_tbl f
  @@ fun f ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* v < w => (v⊔t ∪ e)/w = v⊔(t/w) ∪ (e/w) *)
  unique f.v ~t:(div1 f.t w) ~e:(div1 f.e w)

let rem1_tbl = MemoT.create 1 "rem1 memo table"

(** [f%{{w}}], written [f%w], = [{ p | w ∉ p ∈ f }] *)
let rec rem1 f w =
  match f with
  | Empty ->
      (* ∅%w = ∅ *)
      Empty
  | Unit ->
      (* {∅}%w = {∅} *)
      Unit
  | Ite i -> (
    match Elt.order i.v w with
    | GT ->
        (* v > w => (v⊔t ∪ e)%w = (v⊔t ∪ e) *)
        f
    | EQ ->
        (* (w⊔t ∪ e)%w = e *)
        i.e
    | LT -> rem1_memo f w )

and rem1_memo f w =
  MemoT.find_or_add rem1_tbl f
  @@ fun f ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* v < w => (v⊔t ∪ e)%w = v⊔(t%w) ∪ (e%w) *)
  unique f.v ~t:(rem1 f.t w) ~e:(rem1 f.e w)

let union_tbl = MemoTT.create 65536 "union memo table"

(** [f ∪ g] = [{ p | p ∈ f or p ∈ g }] *)
let rec union f g =
  if f == g then (* f ∪ f = f *) f
  else if f == Empty then (* ∅ ∪ g = g *) g
  else if g == Empty then (* f ∪ ∅ = f *) f
  else union_memo f g

and union_memo f g =
  MemoTT.find_or_add union_tbl f g
  @@ fun f g ->
  match (f, g) with
  | Ite i, Unit | Unit, Ite i ->
      (* (v⊔t ∪ e) ∪ {∅} = v⊔t ∪ (e ∪ {∅}) *)
      unique i.v ~t:i.t ~e:(union i.e Unit)
  | Ite i, Ite j -> (
    match Elt.order i.v j.v with
    | LT ->
        (* v < v' => (v⊔t ∪ e) ∪ (v'⊔t' ∪ e') = v⊔t ∪ (e ∪ (v'⊔t' ∪ e')) *)
        unique i.v ~t:i.t ~e:(union i.e g)
    | GT ->
        (* v > v' => (v⊔t ∪ e) ∪ (v'⊔t' ∪ e') = v'⊔t' ∪ ((v⊔t ∪ e) ∪ e') *)
        unique j.v ~t:j.t ~e:(union f j.e)
    | EQ ->
        (* (v⊔t ∪ e) ∪ (v⊔t' ∪ e') = v⊔(t ∪ t') ∪ (e ∪ e') *)
        unique i.v ~t:(union i.t j.t) ~e:(union i.e j.e) )
  | Empty, _ | _, Empty | Unit, Unit -> assert false

let join_tbl = MemoTT.create 16 "join memo table"

(** [f ⊔ g] = [{ p ∪ q | p ∈ f and q ∈ g }]. *)
let rec join f g =
  match (f, g) with
  | Empty, _ | _, Empty ->
      (* f ⊔ ∅ = ∅ *)
      Empty
  | Unit, f | f, Unit ->
      (* f ⊔ {∅} = f *)
      f
  | Ite i, Ite j -> (
    match Elt.order i.v j.v with
    | GT ->
        (* f ⊔ g = g ⊔ f *)
        join_memo g f
    | LT | EQ -> join_memo f g )

and join_memo f g =
  MemoTT.find_or_add join_tbl f g
  @@ fun f g ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* g = v⊔(g/v) ∪ g%v *)
  let g_t = div1 g f.v in
  let g_e = rem1 g f.v in
  (*= (v⊔t ∪ e) ⊔ (v⊔(g/v) ∪ g%v)
      = v⊔((t ⊔ g/v) ∪ (t ⊔ g%v) ∪ (e ⊔ g/v)) ∪ (e ⊔ g%v) *)
  let t = union (join f.t g_t) (union (join f.t g_e) (join f.e g_t)) in
  let e = join f.e g_e in
  unique f.v ~t ~e

let diff_tbl = MemoTT.create 512 "diff memo table"

(** [p ∖ q] = [{ c | c ∈ p ∧ c ∉ q }] *)
let rec diff p q =
  if p == q then (* p ∖ p = ∅ *) empty
  else if p == empty then (* ∅ ∖ _ = ∅ *) empty
  else if q == empty then (* p ∖ ∅ = p *) p
  else diff_memo p q

and diff_memo p q =
  MemoTT.find_or_add diff_tbl p q
  @@ fun p q ->
  match (p, q) with
  | Ite i, Unit ->
      (* (a*t ∨ e) ∖ {∅} = a*t ∨ (e ∖ {∅}) *)
      unique i.v ~t:i.t ~e:(diff i.e unit)
  | Unit, Ite j ->
      (* {∅} ∖ (a*t ∨ e) = {∅} ∖ e *)
      diff unit j.e
  | Ite i, Ite j -> (
    match Elt.order i.v j.v with
    | LT ->
        (* a < a' ⇒ (a*t ∨ e) ∖ (a'*t' ∨ e') = a*t ∨ (e ∖ (a'*t' ∨ e')) *)
        unique i.v ~t:i.t ~e:(diff i.e q)
    | EQ ->
        (* (a*t ∨ e) ∖ (a*t' ∨ e') = (a*(t ∖ t') ∨ (e ∖ e')) *)
        unique i.v ~t:(diff i.t j.t) ~e:(diff i.e j.e)
    | GT ->
        (* a > a' ⇒ (a*t ∨ e) ∖ (a'*t' ∨ e') = (a*t ∨ e) ∖ e' *)
        diff p j.e )
  | Empty, _ | _, Empty | Unit, Unit -> assert false

let restrict_tbl = MemoTT.create 8192 "restrict memo table"

(** [p Δ q] = [{ c | c ∈ p ∧ ∃d ∈ q. d ⊆ c }] *)
let rec restrict p q =
  if p == q then (* p Δ p = p *) p
  else if p == empty then (* ∅ Δ q = ∅ *) empty
  else if q == empty then (* p Δ ∅ = ∅ *) empty
  else if q == unit then (* p Δ {∅} = p *) p
  else restrict_memo p q

and restrict_memo p q =
  MemoTT.find_or_add restrict_tbl p q
  @@ fun p q ->
  match (p, q) with
  | Unit, Ite j ->
      (* {∅} Δ (a*t ∨ e) = {∅} Δ e *)
      restrict unit j.e
  | Ite i, Ite j -> (
    match Elt.order i.v j.v with
    | LT ->
        (* a < a' ⇒ (a*t ∨ e) Δ (a'*t' ∨ e') = a*(t Δ q) ∨ (e Δ q) *)
        unique i.v ~t:(restrict i.t q) ~e:(restrict i.e q)
    | EQ ->
        (* (a*t ∨ e) Δ (a*t' ∨ e') = a*(t Δ (t' ∪ e')) ∨ (e Δ e') *)
        unique i.v ~t:(restrict i.t (union j.t j.e)) ~e:(restrict i.e j.e)
    | GT ->
        (* a > a' ⇒ (a*t ∨ e) Δ (a'*t' ∨ e') = a*(t Δ e') ∨ (e Δ e') *)
        unique i.v ~t:(restrict i.t j.e) ~e:(restrict i.e j.e) )
  | Empty, _ | _, Empty | Unit, Unit | Ite _, Unit -> assert false

let bound_tbl = MemoIT.create 128 "bound memo table"

(** [bound n p] = [{c | c ∈ p ∧ |c| ≤ n}] *)
let rec bound n p =
  if p == empty then empty
  else if p == unit then unit
  else if n <= 0 then unit
  else bound_memo n p

and bound_memo n p =
  MemoIT.find_or_add bound_tbl n p
  @@ fun n p ->
  let[@warning "-partial-match"] (Ite p) = p in
  unique p.v ~t:(bound (n - 1) p.t) ~e:(bound n p.e)

let count_tbl = MemoT.create 2 "count memo table"

(** [count f] is the number of sets in the family [f] *)
let rec count f =
  match f with Empty -> 0 | Unit -> 1 | Ite _ -> count_memo f

and count_memo f =
  MemoT.find_or_add count_tbl f
  @@ fun f ->
  let[@warning "-partial-match"] (Ite f) = f in
  count f.t + count f.e

(*
 * Main
 *)

(* This encoding of the N-queens problem results in the diagrams growing and
   then shrinking as the computation proceeds. This is ok for benchmarking
   purposes, but note that Minato 1994 describes an alternate encoding that
   avoids this. *)
let main () =
  let n = int_of_string Sys.argv.(1) in
  let q c r = elem (c, r) in
  (* all placements of 0 to n² queens on n×n board *)
  let all =
    let a = ref unit in
    for i = 0 to n - 1 do
      for j = 0 to n - 1 do
        a := join !a (union unit (q i j))
      done
    done ;
    !a
  in
  (* all pairs of positions that attack each other *)
  let attacks =
    let a = ref empty in
    for i = 0 to n - 1 do
      for j = 0 to n - 1 do
        (* attacks down *)
        for k = i + 1 to n - 1 do
          a := union !a (join (q i j) (q k j))
        done ;
        (* attacks right *)
        for k = j + 1 to n - 1 do
          a := union !a (join (q i j) (q i k))
        done ;
        (* attacks down-right *)
        for k = 1 to min (n - i) (n - j) - 1 do
          a := union !a (join (q i j) (q (i + k) (j + k)))
        done ;
        (* attacks down-left *)
        for k = 1 to min (n - i) (j + 1) - 1 do
          a := union !a (join (q i j) (q (i + k) (j - k)))
        done
      done
    done ;
    !a
  in
  (* placements containing at least one attack *)
  let unsafe = restrict all attacks in
  (* placements not containing any attacks *)
  let safe = diff all unsafe in
  (* placements not containing any attacks but with too few queens *)
  let small = bound (n - 1) safe in
  (* safe placements that have enough queens *)
  let solution = diff safe small in
  (* output results *)
  let num_results = count solution in
  print_int n ;
  print_char ' ' ;
  print_int num_results ;
  print_newline ()

;;
main ()
