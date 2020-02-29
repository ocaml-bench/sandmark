(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




(*open Basics*)




(**
 * Yes, it is the 3D vector!.
 *
 * ...mostly the usual sort of stuff.
 *
 * (array type implementation seemed same speed as record type implementation,
 * but array might be slightly smaller)
 *)

type vT = float array


(* construction / conversion ------------------------------------------------ *)
let vCreate    x y z = [| x; y; z |]
let vFromArray a     = [| a.(0); a.(1); a.(2) |]

(*let vToArray v = v*)


(* constants ---------------------------------------------------------------- *)
let vZero      = Array.make 3 0.0
(*let vHalf      = Array.make 3 0.5*)
let vOne       = Array.make 3 1.0
(*let vEpsilon   = Array.make 3 epsilon_float*)
(*let vAlmostOne = Array.make 3 (1.0 -. epsilon_float)*)
(*let vMinimum   = Array.make 3 ~-.max_float*)
let vMaximum   = Array.make 3 max_float
(*let vSmall     = Array.make 3 fp_small*)
(*let vLarge     = Array.make 3 fp_large*)
let vOneX      = [| 1.0; 0.0; 0.0 |]
let vOneY      = [| 0.0; 1.0; 0.0 |]
let vOneZ      = [| 0.0; 0.0; 1.0 |]


(* queries ------------------------------------------------------------------ *)
(* elements *)
(*let vX   v   = v.(0)*)
(*let vY   v   = v.(1)*)
(*let vZ   v   = v.(2)*)
(*let vGet v i = v.(i)*)

(* basic abstract operations *)
let vFold f v     = f (f v.(0) v.(1)) v.(2)
let vZip  f v0 v1 = [| f v0.(0) v1.(0); f v0.(1) v1.(1); f v0.(2) v1.(2) |]

(* vector3f -> float *)
(*let vSum      v =  v.(0) +. v.(1) +. v.(2)*)
(*let vAverage  v = (v.(0) +. v.(1) +. v.(2)) *. (1.0 /. 3.0)*)
(*let vSmallest v = min v.(0) (min v.(1) v.(2))*)
(*let vLargest  v = max v.(0) (max v.(1) v.(2))*)

(* vector3f vector3f -> vector3f *)
let ( +| ) v0 v1 = [| v0.(0) +. v1.(0); v0.(1) +. v1.(1); v0.(2) +. v1.(2) |]
let ( -| ) v0 v1 = [| v0.(0) -. v1.(0); v0.(1) -. v1.(1); v0.(2) -. v1.(2) |]
let ( *| ) v0 v1 = [| v0.(0) *. v1.(0); v0.(1) *. v1.(1); v0.(2) *. v1.(2) |]
let ( /| ) v0 v1 = [| v0.(0) /. v1.(0); v0.(1) /. v1.(1); v0.(2) /. v1.(2) |]
let ( *|.) v0 f1 = [| v0.(0) *. f1;     v0.(1) *. f1;     v0.(2) *. f1     |]
let ( /|.) v0 f1 = let f1 = (1.0 /. f1) in
   [| v0.(0) *. f1; v0.(1) *. f1; v0.(2) *. f1 |]

(* -> float *)
let vDot v0 v1 = (v0.(0) *. v1.(0)) +. (v0.(1) *. v1.(1)) +. (v0.(2) *. v1.(2))
let vLength v  = sqrt (vDot v v)
(*let vDistance v0 v1 = vLength (v0 -| v1)*)

(* vector3f -> vector3f *)
let (~-|) v = [| ~-.(v.(0)); ~-.(v.(1)); ~-.(v.(2)) |]
(*let vAbs  v = [| abs_float(v.(0)); abs_float(v.(1)); abs_float(v.(2)) |]*)
let vUnitize v    = if vLength v <> 0.0 then v /|. vLength v else vZero
let vCross   v0 v1 =
   [| (v0.(1) *. v1.(2)) -. (v0.(2) *. v1.(1));
      (v0.(2) *. v1.(0)) -. (v0.(0) *. v1.(2));
      (v0.(0) *. v1.(1)) -. (v0.(1) *. v1.(0)) |]

(* clamp *)
let vClamp   lower upper v = vZip min upper (vZip max lower v)
(*let vClamp01 v             = vClamp vZero vAlmostOne v*)

(* vector-logical sign *)
(*let vCompare v0 v1 = vZip (fun a b -> float (compare a b)) v0 v1*)
(*let vSign    v     = vCompare v vZero*)

(* vector-logical bool *)
(*let vTest f v0 v1 = vZip (fun a b -> bToF (f a b)) v0 v1*)
(*let ( =|)   v0 v1 = vTest ( =) v0 v1*)
(*let (<>|)   v0 v1 = vTest (<>) v0 v1*)
(*let ( <|)   v0 v1 = vTest ( <) v0 v1*)
(*let (<=|)   v0 v1 = vTest (<=) v0 v1*)
(*let ( >|)   v0 v1 = vTest ( >) v0 v1*)
(*let (>=|)   v0 v1 = vTest (>=) v0 v1*)

(* make a vector from a scaled basis *)
let vScaleFrame frame scale = (frame.(0) *|. scale.(0)) +|
   (frame.(1) *|. scale.(1)) +| (frame.(2) *|. scale.(2))


(* IO ----------------------------------------------------------------------- *)
let vRead inBuf =
   Scanf.bscanf inBuf " ( %f %f %f )" vCreate
(*let vWrite outBuf v =
   Printf.bprintf outBuf "(%g %g %g)" v.(0) v.(1) v.(2)*)
