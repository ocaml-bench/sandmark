(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * Surface point at a ray-object intersection.
 *
 * All direction parameters are away from surface.
 *
 * @param triangle_i (Triangle.obj) surface's object
 * @param position_i (Vector3f.vT)  position of point on surface
 *)
class obj triangle_i position_i =

   (* class constants *)
   let pi_k = 3.141592653589793238512809 in


object (__)

(* fields ------------------------------------------------------------------- *)
   val triangle_m = (triangle_i:Triangle.obj)

   val position_m = position_i


(* queries ------------------------------------------------------------------ *)
   (**
    * Emission from surface element to point.
    *
    * @param toPosition   (Vector3f.vT) point being illuminated
    * @param outDirection (Vector3f.vT) direction unitized from emitting point
    * @param isSolidAngle (bool)        use solid angle
    * @return (Vector3f.vT) emitted radiance
    *)
   method emission toPosition outDirection isSolidAngle =

      let distance2 = let ray = toPosition -| position_m in vDot ray ray
      and cosArea  = (vDot outDirection triangle_m#normal) *. triangle_m#area in

      (* clamp-out infinity *)
      let solidAngle = if isSolidAngle then
         cosArea /. (max 1e-6 distance2) else 1.0 in

      (* emit from front face of surface only *)
      if cosArea > 0.0 then triangle_m#emitivity *|. solidAngle else vZero


   (**
    * Light reflection from ray to ray by surface.
    *
    * @param inDirection  (Vector3f.vT) negative of inward ray direction
    * @param inRadiance   (Vector3f.vT) inward radiance
    * @param outDirection (Vector3f.vT) outward (eyeward) ray direction
    * @return (Vector3f.vT) reflected radiance
    *)
   method reflection inDirection inRadiance outDirection =

      let inDot  = vDot inDirection  triangle_m#normal
      and outDot = vDot outDirection triangle_m#normal in

      (* directions must be on same side of surface *)
      if ((compare 0.0 inDot) * (compare 0.0 outDot)) > 0 then
         (* ideal diffuse BRDF:
            radiance scaled by cosine, 1/pi, and reflectivity *)
         (inRadiance *| triangle_m#reflectivity) *|. (abs_float inDot /. pi_k)
      else
         vZero


   (**
    * Monte-carlo direction of reflection from surface.
    *
    * @param inDirection (Vector3f.vT)    eyeward ray direction
    * @param random      (Random.State.t) random number generator
    * @return (Vector3f.vT, Vector3f.vT) sceneward ray direction unitized, and
    * light scaling of interaction point
    *)
   method nextDirection inDirection random =

      let reflectivityMean = (vDot triangle_m#reflectivity vOne) /. 3.0 in

      (* russian-roulette for reflectance magnitude *)
      if (Random.State.float random 1.0) < reflectivityMean then
         let color = triangle_m#reflectivity /|. reflectivityMean in

         (* cosine-weighted importance sample hemisphere *)

         (* make coord frame coefficients (z in normal direction) *)
         let coefficients = let rand () = Random.State.float random 1.0 in
            let p2r1, sr2 = (pi_k *. 2.0 *. (rand ())), (sqrt (rand ())) in
            vCreate ((cos p2r1) *. sr2) ((sin p2r1) *. sr2)
            (sqrt (1.0 -. (sr2 *. sr2)))

         (* make coord frame *)
         and frame = let tangent = triangle_m#tangent
            and normal = let n = triangle_m#normal in
               (* enable reflection from either face of surface *)
               if (vDot n inDirection) >= 0.0 then n else ~-|n in
            [| tangent; vCross normal tangent; normal |] in

         (* make vector from frame times coefficients *)
         let outDirection = vScaleFrame frame coefficients in

         (outDirection, color)
      else
         (vZero, vZero)


   method hitObject = triangle_m

   method position  = position_m

end
