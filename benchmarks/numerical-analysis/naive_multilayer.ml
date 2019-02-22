(** neuralNetwork.ml --- multilayer neural network for binary classification

    [MIT Lisence] Copyright (C) 2015 Akinori ABE
*)

open Format

(* ================================================================= *
 * Utility functions for array
 * ================================================================= *)


let init_matrix m n f = Array.init m (fun i -> Array.init n (f i))

let matrix_size a =
  let m = Array.length a in
  let n = if m = 0 then 0 else Array.length a.(0) in
  (m, n)

let map2 f x y = Array.mapi (fun i xi -> f xi y.(i)) x

let iter2 f x y =  Array.iteri (fun i xi -> f xi y.(i)) x
let iteri2 f x y = Array.iteri (fun i xi -> f i xi y.(i)) x

let fold_left2 f init x y =
  let acc = ref init in
  for i = 0 to Array.length x - 1 do acc := f !acc x.(i) y.(i) done;
  !acc

let map_sum f =  Array.fold_left (fun acc xi -> acc +. f xi) 0.0
let map2_sum f = fold_left2 (fun acc xi yi -> acc +. f xi yi) 0.0


(* ================================================================= *
 * BLAS-like functions for linear algebraic operations
 * ================================================================= *)

(** Dot product of two vectors *)
let dot = map2_sum ( *. )

(** Execute [y := alpha * x + y] where [alpha] is a scalar, [x] and [y] are
    vectors. *)
let axpy ~alpha x y =
  let n = Array.length x in
  for i = 0 to n - 1 do y.(i) <- alpha *. x.(i) +. y.(i) done

(** [gemv a x y] computes [a * x + y] where [a] is a matrix, and [x] and [y] are
    vectors. *)
let gemv a x y = map2 (fun ai yi -> dot ai x +. yi) a y

(** [gemv_t a x] computes [a^T * x] where [a] is a matrix and [x] is a vector.
*)
let gemv_t a x =
  let (_, n) = matrix_size a in
  let y = Array.make n 0.0 in
  iter2 (fun ai xi -> axpy ~alpha:xi ai y) a x;
  y

(** [ger x y] computes outer product [x y^T] of vectors [x] and [y]. *)
let ger x y = Array.map (fun xi -> Array.map (( *. ) xi) y) x

(* ================================================================= *
 * Multilayer neural network
 * ================================================================= *)

(** A layer in a multilayer neural network *)
type layer =
  {
    actv_f : float array -> float array; (** an activation function *)
    actv_f' : float array -> float array array; (** the derivative of [actv_f]*)
    weight : float array array; (** a weight matrix *)
    bias : float array; (** a bias vector *)
  }

(** Forward propagation *)
let forwardprop lyrs x0 =
  List.fold_left
    (fun xi lyr -> lyr.actv_f (gemv lyr.weight xi lyr.bias))
    x0 lyrs

(** An error function (cross-entropy) *)
let error y t = ~-. (map2_sum (fun ti yi -> ti *. log yi) t y)

(** The derivative of an error function *)
let error' = map2 (fun yi ti -> ~-. ti /. yi)

(** Error backpropagation *)
let backprop lyrs x0 t =
  let rec calc_delta x = function
    | [] -> failwith "empty neural network"
    | [lyr] -> (* output layer *)
      let y = lyr.actv_f (gemv lyr.weight x lyr.bias) in
      let delta = gemv_t (lyr.actv_f' y) (error' y t) in
      (delta, [])
    | lyr :: ((uplyr :: _) as lyrs') -> (* hidden layer *)
      let y = lyr.actv_f (gemv lyr.weight x lyr.bias) in
      let (updelta, tl) = calc_delta y lyrs' in
      let delta = gemv_t (lyr.actv_f' y) (gemv_t uplyr.weight updelta) in
      (delta, (y, updelta) :: tl)
  in
  let (delta0, tl) = calc_delta x0 lyrs in
  (x0, delta0) :: tl

(** Update parameters in the given neural network according to the given input
    and target (stochastic gradient descent). *)
let train ~eta lyrs x0 t =
  let alpha = ~-. eta in
  let res = backprop lyrs x0 t in
  List.iter2
    (fun (x, delta) lyr ->
       let dw = ger delta x in
       let db = delta in
       iter2 (axpy ~alpha) dw lyr.weight;
       axpy ~alpha db lyr.bias)
    res lyrs

(* ================================================================= *
 * Gradient checking
 *
 * Gradient checking is a approach to verify whether implementation of
 * error backpropagation algorithm is correct, or not. See
 * http://ufldl.stanford.edu/wiki/index.php/Gradient_checking_and_advanced_optimization
 * for details.
 * ================================================================= *)

(** Compute the gradient of error function by naive numerical differentiation *)
let approx_gradient ?(epsilon = 1e-4) lyrs x0 t =
  let (lyr0, lyrs') = match lyrs with
    | [] -> failwith "empty neural network"
    | hd :: tl -> (hd, tl) in
  let lyr0_bias_eps i eps =
    let bias = Array.mapi (fun j bj -> if i=j then bj+.eps else bj) lyr0.bias in
    { lyr0 with bias }
  in
  let lyr0_weight_eps i j eps =
    let aux k l wkl = if i = k && j = l then wkl +. eps else wkl in
    let weight = Array.mapi (fun k -> Array.mapi (aux k)) lyr0.weight in
    { lyr0 with weight }
  in
  let calc_grad lyr0_eps =
    let calc_error lyr0' = error (forwardprop (lyr0' :: lyrs') x0) t in
    let e_p = calc_error (lyr0_eps (~+. epsilon)) in
    let e_n = calc_error (lyr0_eps (~-. epsilon)) in
    (e_p -. e_n) /. (2.0 *. epsilon)
  in
  let (m, n) = matrix_size lyr0.weight in
  let db = Array.init m (fun i -> calc_grad (lyr0_bias_eps i)) in
  let dw = init_matrix m n (fun i j -> calc_grad (lyr0_weight_eps i j)) in
  (db, dw)

let eq_significant_digits ?(epsilon = 1e-9) ?(digits = 1e-3) x y =
  let check_float z = match classify_float z with
    | FP_infinite -> false
    | FP_nan -> false
    | _ -> true
  in
  if not (check_float x && check_float y) then failwith "divergence";
  let abs_x = abs_float x in
  if abs_x < epsilon
  then abs_float y < epsilon (* true if both x and y are nealy zero *)
  else begin (* check significant digits *)
    let d = (x -. y) *. (0.1 ** (floor (log10 abs_x) +. 1.0)) in
    abs_float d < digits
  end

let check_gradient lyrs x0 t =
  let warn s x y =
    if not (eq_significant_digits x y)
    then eprintf "** %s is %.16g, but should be %.16g@." s x y
  in
  let (x, delta) = List.hd (backprop lyrs x0 t) in
  let dw = ger delta x in
  let db = delta in
  let (db', dw') = approx_gradient lyrs x0 t in
  iteri2 (fun i -> warn (sprintf "dE/db[%d]" i)) db db';
  iteri2 (fun i ->
      iteri2 (fun j ->
          warn (sprintf "dE/dw[%d,%d]" i j))) dw dw'

(* ================================================================= *
 * Activation functions
 * ================================================================= *)

(** The hyperbolic tangent *)
let actv_tanh = Array.map tanh

(** The derivative of the hyperbolic tangent *)
let actv_tanh' z =
  let n = Array.length z in
  init_matrix n n (fun i j -> if i=j then 1.0 -. z.(i) *. z.(i) else 0.0)

(** The softmax function (used at the output layer for classification) *)
let actv_softmax x =
  let y = Array.map exp x in
  let c = 1.0 /. map_sum (fun yi -> yi) y in
  Array.map (( *. ) c) y

(** The derivative of the softmax function *)
let actv_softmax' z =
  let n = Array.length z in
  init_matrix n n
    (fun i j -> if i = j then (1.0 -. z.(i)) *. z.(i) else ~-. (z.(i) *. z.(j)))

(** A linear function (used at the output layer for regression) *)
let actv_linear x = x

(** The derivative of a linear function *)
let actv_linear z =
  let n = Array.length z in
  init_matrix n n (fun i j -> if i = j then 1.0 else 0.0)

(* ================================================================= *
 * Main routine
 * ================================================================= *)

(** Return a layer of a neural network. *)
let make_layer actv_f actv_f' dim1 dim2 =
  let rand () = Random.float 2.0 -. 1.0 in
  { actv_f; actv_f';
    weight = init_matrix dim2 dim1 (fun _ _ -> rand ());
    bias = Array.init dim2 (fun _ -> rand ()); }

(** Evaluate an error *)
let evaluate lyrs samples =
  map_sum (fun (x, t) -> error (forwardprop lyrs x) t) samples

let main samples =
  let (input_dim, output_dim) =
    let (x, t) = samples.(0) in
    (Array.length x, Array.length t)
  in
  let hidden1_dim = 10 in
  let hidden2_dim = 5 in
  let nnet = [
    make_layer actv_tanh actv_tanh' input_dim hidden1_dim;
    make_layer actv_tanh actv_tanh' hidden1_dim hidden2_dim;
    make_layer actv_softmax actv_softmax' hidden2_dim output_dim; ] in
  for i = 1 to 1000 do
    Array.iter (fun (x, t) ->
        (* check_gradient nnet x t; *)
        train ~eta:0.01 nnet x t) samples;
    (* if i mod 100 = 0 *)
    (* then printf "Loop #%d: Error = %g@." i (evaluate nnet samples) *)
  done

let main () = main Naive_multilayer_dataset.samples

let () = main () |> ignore
