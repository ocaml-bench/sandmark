let doc =
"
A minimal multicore OCaml implementation of an Evolutionary Algorithm.
Per Kristian Lehre <p.k.lehre@cs.bham.ac.uk>
May 6th, 2020
"
module T = Domainslib.Task
let my_key = Domain.DLS.new_key Random.State.make_self_init

type bitstring = bool array
type individual = { chromosome : bitstring; fitness : float }
type fitness_function = bitstring -> float
type population = individual array

let chromosome_length = Array.length
let population_size = Array.length

let chromosome { chromosome=x; fitness=_ } = x
let evaluate f x = { chromosome=x; fitness=(f x) }

let fittest x y =
  if x.fitness > y.fitness then x else y
let pop_fittest pop = Array.fold_left fittest pop.(0) pop

let random_bitstring n =
  let s = Domain.DLS.get my_key in
  Array.init n (fun _ -> Random.State.bool s)

let random_individual n f =
  evaluate f (random_bitstring n)

(* Onemax is a simple fitness function. *)
let add_bit x b = if b then x +. 1.0 else x
let onemax : fitness_function = Array.fold_left add_bit 0.0

(* Choose fittest out of k uniformly sampled individuals *)
let rec k_tournament k pop =
  let s = Domain.DLS.get my_key in
  let x = pop.(Random.State.int s (population_size pop)) in
  if k <= 1 then x
  else
    let y = k_tournament (k-1) pop in
    fittest x y

let xor a b = if a then not b else b

(* Naive Theta(n) implementation of mutation. *)
let mutate chi x =
  let s = Domain.DLS.get my_key in
  let flip_coin p = (Random.State.float s 1.0) < p in
  let n = chromosome_length x in
  let p = chi /. (float n) in
  Array.map (fun b -> xor b (flip_coin p)) x

(* Command line arguments *)

let num_domains = try int_of_string Sys.argv.(1) with _ -> 4

let runtime = 100000

let chi = 0.4

let lambda = try int_of_string Sys.argv.(3) with _ -> 1000

let k = 2

let n = try int_of_string Sys.argv.(2) with _ -> 1000

let multicore_init pool num_domains x0 n f =
  let a = Array.make n x0 in
  T.parallel_for
    pool ~start:0 ~finish:(n-1)
    ~body:(fun i -> a.(i) <- f ());
  a

let evolutionary_algorithm

    num_domains   (* Number of multicore domains *)
    runtime       (* Runtime budget  *)
    lambda        (* Population size *)
    k             (* Tournament size *)
    chi           (* Mutation rate   *)
    fitness       (* Fitness function *)
    n             (* Problem instance size n *)

  =

  let pool = T.setup_pool ~num_additional_domains:(num_domains - 1) in
  let adam = random_individual n fitness in
  let init_pop = multicore_init pool num_domains adam in
  let pop0 = init_pop lambda (fun _ -> random_individual n fitness) in


  let rec generation time pop =
    let next_pop =
      init_pop lambda
       (fun _ ->
             (k_tournament k pop)
          |> chromosome
          |> (mutate chi)
          |> (evaluate fitness))
    in
    if time * lambda > runtime then
      (T.teardown_pool pool;
       Printf.printf "fittest: %f, num_domains: %d\n"
         (pop_fittest next_pop).fitness num_domains)
    else
      generation (time+1) next_pop
  in generation 0 pop0

let ea () = evolutionary_algorithm num_domains runtime lambda k chi onemax n

let () =
  ea ()
