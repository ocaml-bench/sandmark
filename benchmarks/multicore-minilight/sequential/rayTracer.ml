(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * Ray tracer for general light transport.
 *
 * Traces a path with emitter sampling each step: A single chain of ray-steps
 * advances from the eye into the scene with one sampling of emitters at each
 * node.
 *
 * @param scene_i (Scene.obj) collection of objects
 *)
class obj scene_i =


object (__)

(* fields ------------------------------------------------------------------- *)
   val scene_m = scene_i


(* implementation ----------------------------------------------------------- *)
   (**
    * Radiance from an emitter sample.
    *
    * @param rayDirection (Vector3f.vT)      previous ray direction unitized
    * @param surfacePoint (SurfacePoint.obj) surface point receiving emission
    * @param random       (Random.State.t)   random number generator
    * @return (Vector3f.vT) light value in radiance
    *)
   method private emitterSample rayDirection surfacePoint random =

      (* single emitter sample, ideal diffuse BRDF:
         reflected = (emitivity * solidangle) * (emitterscount) *
         (cos(emitdirection) / pi * reflectivity)
         -- SurfacePoint does the first and last parts (in separate methods) *)

      (* check an emitter was found *)
      match scene_m#emitter random with

      | (Some emitter, emitterPosition) ->

         (* make direction to emit point *)
         let emitDirection = vUnitize
            (emitterPosition -| surfacePoint#position) in

         (* send shadow ray; if unshadowed, get inward emission value *)
         let emissionIn = match scene_m#intersection surfacePoint#position
                                  emitDirection (Some surfacePoint#hitObject) with
             Some (hitObject, _) when hitObject != emitter -> vZero
           | _ -> (new SurfacePoint.obj emitter emitterPosition)#emission
                    surfacePoint#position ~-|emitDirection true in

         (* get amount reflected by surface *)
         surfacePoint#reflection emitDirection
            (emissionIn *|. (float scene_m#emittersCount)) ~-|rayDirection

      | (None, _) ->

         vZero


(* queries ------------------------------------------------------------------ *)
   (**
    * Returned radiance from a trace.
    *
    * @param rayOrigin    (Vector3f.vT)    ray start point
    * @param rayDirection (Vector3f.vT)    ray direction unitized
    * @param lastHit      (Triangle.var)   previous intersected object
    * @param random       (Random.State.t) random number generator
    * @return (Vector3f.vT) light value in radiance
    *)
   method radiance rayOrigin rayDirection ?lastHit random =

      (* intersect ray with scene *)
      match scene_m#intersection rayOrigin rayDirection lastHit with

      | Some (triangle, hitPosition) ->

         (* make SurfacePoint of intersection *)
         let surfacePoint = new SurfacePoint.obj triangle hitPosition in

         (* local emission only for first-hit *)
         let localEmission = if lastHit = None then
            surfacePoint#emission rayOrigin ~-|rayDirection false else vZero

         (* emitter sample *)
         and illumination = __#emitterSample rayDirection surfacePoint random

         (* recursive reflection:
            single hemisphere sample, ideal diffuse BRDF:
            reflected = (inradiance * pi) * (cos(in) / pi * color) * reflectance
            -- reflectance magnitude is 'scaled' by the russian roulette, cos is
            importance sampled (both done by SurfacePoint), and the pi and 1/pi
            cancel out *)
         and reflection = let nextDirection, color =
            surfacePoint#nextDirection ~-|rayDirection random in
            (* check surface bounces ray *)
            if nextDirection <> vZero then
               (* recurse *)
               color *| (__#radiance surfacePoint#position nextDirection
                  ~lastHit:surfacePoint#hitObject random)
            else
               vZero in

         (* total radiance returned *)
         reflection +| illumination +| localEmission

      | None ->

         (* no hit: default/background scene emission *)
         scene_m#defaultEmission ~-|rayDirection

end
