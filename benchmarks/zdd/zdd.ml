(** A simple implementation of ZDDs
    (Reduced Ordered Zero-Suppressed Binary Decision Diagrams).

    Josh Berdine, based on:

    Shin-ichi Minato:
    Zero-Suppressed BDDs for Set Manipulation in Combinatorial Problems.
    DAC 1993: 272-277

    Donald Ervin Knuth: The Art of Computer Programming.
    Volume 4a Combinatorial Algorithms Part 1. Addison-Wesley 2011.
 *)

module Elt = struct
  type t = int * char

  let hash = Hashtbl.hash
end

module T = struct
  type t =
    | Empty  (** the empty family: ∅ *)
    | Unit  (** the unit family: {∅} *)
    | Ite of {v: Elt.t; t: t; e: t; hash: int}
        (** a decision: {{v} ∪ p | p ∈ t} ∪ e, aka v⊔t ∪ e *)

  let equal : t -> t -> bool = ( == )

  let hash = function
    | Empty -> Hashtbl.hash 0
    | Unit -> Hashtbl.hash 1
    | Ite {hash; _} -> hash
end

include T

module WeakSet = Weak.Make (struct
  type t = T.t

  let equal p0 q0 =
    match (p0, q0) with
    | Ite p, Ite q -> p.e == q.e && p.t == q.t && p.v = q.v
    | _ -> p0 == q0

  let hash = T.hash
end)

let unique_set = WeakSet.create 1024

let unique v ~t ~e =
  if t = Empty then e
  else
    let hash = Hashtbl.hash (2, Elt.hash v, T.hash e, T.hash t) in
    let node = Ite {v; t; e; hash} in
    WeakSet.merge unique_set node

module Memo1 = struct
  module Tbl = Ephemeron.K1.Make (T)

  let create = Tbl.create

  let find_or_add tbl p k =
    match Tbl.find_opt tbl p with
    | Some r -> r
    | None ->
        let r = k () in
        Tbl.add tbl p r ;
        r
end

module Memo2 = struct
  module Tbl = Ephemeron.K2.Make (T) (T)

  let create = Tbl.create

  let find_or_add tbl p q k =
    match Tbl.find_opt tbl (p, q) with
    | Some r -> r
    | None ->
        let r = k () in
        Tbl.add tbl (p, q) r ;
        r
end

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

let div1_tbl = Memo1.create 1024

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
  | Ite i when i.v > w ->
      (* v > w => (v⊔t ∪ e)/w = ∅ *)
      Empty
  | Ite i when i.v = w ->
      (* (w⊔t ∪ e)/w = t *)
      i.t
  | Ite _ -> div1_memo f w

and div1_memo f w =
  Memo1.find_or_add div1_tbl f
  @@ fun () ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* v < w => (v⊔t ∪ e)/w = v⊔(t/w) ∪ (e/w) *)
  unique f.v ~t:(div1 f.t w) ~e:(div1 f.e w)

let rem1_tbl = Memo1.create 1024

(** [f%{{w}}], written [f%w], = [{ p | w ∉ p ∈ f }] *)
let rec rem1 f w =
  match f with
  | Empty ->
      (* ∅%w = ∅ *)
      Empty
  | Unit ->
      (* {∅}%w = {∅} *)
      Unit
  | Ite i when i.v > w ->
      (* v > w => (v⊔t ∪ e)%w = (v⊔t ∪ e) *)
      f
  | Ite i when i.v = w ->
      (* (w⊔t ∪ e)%w = e *)
      i.e
  | Ite _ -> rem1_memo f w

and rem1_memo f w =
  Memo1.find_or_add rem1_tbl f
  @@ fun () ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* v < w => (v⊔t ∪ e)%w = v⊔(t%w) ∪ (e%w) *)
  unique f.v ~t:(rem1 f.t w) ~e:(rem1 f.e w)

let union_tbl = Memo2.create 1024

(** [f ∪ g] = [{ p | p ∈ f or p ∈ g }] *)
let rec union f g =
  if f = g then (* f ∪ f = f *) f
  else if f = Empty then (* ∅ ∪ g = g *) g
  else if g = Empty then (* f ∪ ∅ = f *) f
  else union_memo f g

and union_memo f g =
  Memo2.find_or_add union_tbl f g
  @@ fun () ->
  match (f, g) with
  | Ite i, Unit | Unit, Ite i ->
      (* (v⊔t ∪ e) ∪ {∅} = v⊔t ∪ (e ∪ {∅}) *)
      unique i.v ~t:i.t ~e:(union i.e Unit)
  | Ite i, Ite j when i.v < j.v ->
      (* v < v' => (v⊔t ∪ e) ∪ (v'⊔t' ∪ e') = v⊔t ∪ (e ∪ (v'⊔t' ∪ e')) *)
      unique i.v ~t:i.t ~e:(union i.e g)
  | Ite i, Ite j when i.v > j.v ->
      (* v > v' => (v⊔t ∪ e) ∪ (v'⊔t' ∪ e') = v'⊔t' ∪ ((v⊔t ∪ e) ∪ e') *)
      unique j.v ~t:j.t ~e:(union f j.e)
  | Ite i, Ite j ->
      (* (v⊔t ∪ e) ∪ (v⊔t' ∪ e') = v⊔(t ∪ t') ∪ (e ∪ e') *)
      unique i.v ~t:(union i.t j.t) ~e:(union i.e j.e)
  | Empty, _ | _, Empty | Unit, Unit -> assert false

let inter_tbl = Memo2.create 1024

(** [f ∩ g] = [{ p | p ∈ f and p ∈ g }] *)
let rec inter f g =
  if f = g then (* f ∩ f = f *) f
  else if f = Empty then (* ∅ ∩ _ = ∅ *) Empty
  else if g = Empty then (* _ ∩ ∅ = ∅ *) Empty
  else inter_memo f g

and inter_memo f g =
  Memo2.find_or_add inter_tbl f g
  @@ fun () ->
  match (f, g) with
  | Ite i, Unit | Unit, Ite i ->
      (* (v⊔t ∪ e) ∩ {∅} = e ∩ {∅} *)
      inter i.e Unit
  | Ite i, Ite j when i.v < j.v ->
      (* v < v' => (v⊔t ∪ e) ∩ (v'⊔t' ∪ e') = e ∩ (v'⊔t' ∪ e') *)
      inter i.e g
  | Ite i, Ite j when i.v > j.v ->
      (* v > v' => (v⊔t ∪ e) ∩ (v'⊔t' ∪ e') = (v⊔t ∪ e) ∩ e' *)
      inter f j.e
  | Ite i, Ite j ->
      (* (v⊔t ∪ e) ∩ (v⊔t' ∪ e') = v⊔(t ∩ t') ∪ (e ∩ e') *)
      unique i.v ~t:(inter i.t j.t) ~e:(inter i.e j.e)
  | Empty, _ | _, Empty | Unit, Unit -> assert false

let join_tbl = Memo2.create 1024

(** [f ⊔ g] = [{ p ∪ q | p ∈ f and q ∈ g }]. *)
let rec join f g =
  match (f, g) with
  | Empty, _ | _, Empty ->
      (* f ⊔ ∅ = ∅ *)
      Empty
  | Unit, f | f, Unit ->
      (* f ⊔ {∅} = f *)
      f
  | Ite i, Ite j when i.v > j.v ->
      (* f ⊔ g = g ⊔ f *)
      join_memo g f
  | Ite _, Ite _ -> join_memo f g

and join_memo f g =
  Memo2.find_or_add join_tbl f g
  @@ fun () ->
  let[@warning "-partial-match"] (Ite f) = f in
  (* g = v⊔(g/v) ∪ g%v *)
  let g_t = div1 g f.v in
  let g_e = rem1 g f.v in
  (*= (v⊔t ∪ e) ⊔ (v⊔(g/v) ∪ g%v)
      = v⊔((t ⊔ g/v) ∪ (t ⊔ g%v) ∪ (e ⊔ g/v)) ∪ (e ⊔ g%v) *)
  let t = union (join f.t g_t) (union (join f.t g_e) (join f.e g_t)) in
  let e = join f.e g_e in
  unique f.v ~t ~e

let div_tbl = Memo2.create 1024

(** [f/g] = [{p | p ∪ q ∈ f and p ∩ q = ∅ for all q ∈ g}] or equivalently
    [⋂{ f/{q} | q ∈ g }], only defined if [g != ∅] *)
let rec div f g =
  match (f, g) with
  | _, _ when f = g ->
      (* f / f = {∅} *)
      Unit
  | _, Unit ->
      (* f / {∅} = f *)
      f
  | Empty, _ ->
      (* ∅ / g = ∅ *)
      Empty
  | Unit, _ ->
      (* {∅} / g = ∅ *)
      Empty
  | Ite _, Ite _ -> div_memo f g
  | _, Empty -> invalid_arg "div f ∅ undefined"

and div_memo f g =
  Memo2.find_or_add div_tbl f g
  @@ fun () ->
  (*= for f = v(f/v) ∪ f%v
        let t' = f/v and e' = f%v
      ∴ (vt' ∪ e') / (vt ∪ e)
      = ⋂{ (vt' ∪ e') / c | c ∈ vt ∪ e }
      = ⋂( { (vt' ∪ e') / c | c ∈ vt} ∪ { (vt' ∪ e') / c | c ∈ e} )
      = ⋂( { vt' / c | c ∈ vt} ∪ { e' / c | c ∈ e} )
      = ⋂( { t' / c | c ∈ t} ∪ { e' / c | c ∈ e} )
      = ⋂{ t' / c | c ∈ t } ∩ ⋂{ e' / c | c ∈ e}
      = (t' / t)            , if e = ∅
        (t' / t) ∩ (e' / e) , otherwise (t != ∅ by ZDD invariant) *)
  let[@warning "-partial-match"] (Ite g) = g in
  let f_t = div1 f g.v in
  let r = div f_t g.t in
  if r = Empty || g.e = Empty then r
  else
    let f_e = rem1 f g.v in
    inter r (div f_e g.e)

let count_tbl = Memo1.create 1024

(** [count f] is the number of sets in the family [f] *)
let rec count f =
  match f with Empty -> 0 | Unit -> 1 | Ite _ -> count_memo f

and count_memo f =
  Memo1.find_or_add count_tbl f
  @@ fun () ->
  let[@warning "-partial-match"] (Ite f) = f in
  count f.t + count f.e

let of_word word =
  String.fold_left
    (fun (i, s) c -> (i + 1, join s (elem (i, c))))
    (0, unit) word
  |> snd

let add_word w f = union (of_word w) f

let print_stats () =
  let len, num, sum, min, med, max = WeakSet.stats unique_set in
  Printf.printf
    "Unique table length: %i entries: %i bucket lengths: sum: %i min: %i \
     median: %i max: %i\n"
    len num sum min med max

let main () =
  let file = Sys.argv.(1) in
  let dict = Array.fold_right add_word (Arg.read_arg file) empty in
  let query = join (elem (1, 'e')) (elem (3, 'k')) in
  let selection = join query (div dict query) in
  let num_results = count selection in
  print_stats () ;
  print_int num_results ;
  print_newline ()

;;
main ()
