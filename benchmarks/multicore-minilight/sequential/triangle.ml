(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




let tolerance_k = 1.0 /. 1024.0 ;;




(**
 * A simple, explicit/non-vertex-shared triangle.
 *
 * Includes geometry and quality.
 *
 * Adapts ray intersection code from:
 * 'Fast, Minimum Storage Ray-Triangle Intersection'
 * Moller, Trumbore;
 * Journal of Graphics Tools, v2 n1 p21, 1997.
 * http://www.acm.org/jgt/papers/MollerTrumbore97/
 *
 * @param inBuffer_i (Scanf.Scanning.scanbuf) to read from
 *
 * @invariants
 * - emitivity_m    >= 0
 * - reflectivity_m >= 0 and <= 1
 *)
class obj inBuffer_i =

(* construction ------------------------------------------------------------- *)
   (* read vectors in sequence:
      three vertexs, then reflectivity, then emitivity *)
   let vectors_c = let rec readVectors vs i = if i = 0 then vs else
      readVectors ((vRead inBuffer_i) :: vs) (i - 1) in readVectors [] 5 in
   let vertexs_m = [| List.nth vectors_c 4; List.nth vectors_c 3;
      List.nth vectors_c 2 |] in
   let edge0 = vertexs_m.(1) -| vertexs_m.(0) in
   let edge1 = vertexs_m.(2) -| vertexs_m.(1) in
   let edge3 = vertexs_m.(2) -| vertexs_m.(0) in
   let normal = lazy (vUnitize (vCross edge0 edge1)) in
   let tangent = lazy (vUnitize edge0) in
   let area = lazy (0.5 *. vLength (vCross edge0 edge1)) in

object (__)

(* fields ------------------------------------------------------------------- *)

   val reflectivity_m = vClamp vZero vOne     (List.nth vectors_c 1)
   val emitivity_m    = vClamp vZero vMaximum (List.nth vectors_c 0)


(* implementation ----------------------------------------------------------- *)


(* queries ------------------------------------------------------------------ *)
   (**
    * Axis-aligned bounding box of triangle.
    *
    * @return (2 Vector3f array) lower corner and upper corner
    *)
    method bound =

      let expand clamp nudge = vZip
         (* include tolerance *)
         (fun a b -> nudge b (((abs_float b) +. a) *. tolerance_k)) vOne
         (* fold to min or max *)
         (vZip clamp vertexs_m.(0) (vZip clamp vertexs_m.(1) vertexs_m.(2))) in

      [| expand min (-.);  expand max (+.) |]


   (**
    * Intersection point of ray with triangle.
    *
    * @param rayOrigin    (Vector3f.vT) ray origin
    * @param rayDirection (Vector3f.vT) ray direction unitized
    * @return float option  Some distance along ray if intersected
    *)
   method intersection rayOrigin rayDirection =

      (* begin calculating determinant -- also used to calculate U parameter *)
      let pvec = vCross rayDirection edge3 in
      let det  = vDot edge0 pvec in

      (* if determinant is near zero, ray lies in plane of triangle *)
      let epsilon = 0.000001 in
      if (det > -.epsilon) && (det < epsilon) then

         None
      else
         let inv_det = 1.0 /. det in

         (* calculate distance from vertex 0 to ray origin *)
         let tvec = rayOrigin -| vertexs_m.(0) in

         (* calculate U parameter and test bounds *)
         let u = (vDot tvec pvec) *. inv_det in
         if (u < 0.0) || (u > 1.0) then

            None
         else
            (* prepare to test V parameter *)
            let qvec = vCross tvec edge0 in

            (* calculate V parameter and test bounds *)
            let v = (vDot rayDirection qvec) *. inv_det in
            if (v < 0.0) || (u +. v > 1.0) then

               None
            else
               (* calculate t, ray intersects triangle *)
               let hitDistance = (vDot edge3 qvec) *. inv_det in

               (* only allow intersections in the forward ray direction *)
               if hitDistance >= 0. then Some hitDistance else None


   (**
    * Monte-carlo sample point on triangle.
    *
    * @param random (Random.State.t) random number generator
    * @return (Vector3f.vT) point on the triangle
    *)
   method samplePoint random =

      (* make barycentric coords *)
      let barycentrics = let rand () = Random.State.float random 1.0 in
         let sqr1, r2 = (sqrt (rand ()), rand ()) in
         vCreate 1.0 (1.0 -. sqr1) ((1.0 -. r2) *. sqr1) in

      (* make position by scaling edges by barycentrics *)
      vScaleFrame [| vertexs_m.(0); edge0; edge3 |] barycentrics


   method normal  = Lazy.force normal

   method tangent = Lazy.force tangent

   (* half area of parallelogram *)
   method area    = Lazy.force area


   method reflectivity = reflectivity_m

   method emitivity    = emitivity_m

end
