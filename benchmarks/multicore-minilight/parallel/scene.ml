(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * A grouping of the objects in the environment.
 *
 * Makes a sub-grouping of emitting objects.
 *
 * @param inBuffer_i    (Scanf.Scanning.scanbuf) to read from
 * @param eyePosition_i (Vector3f.vT) eye position
 *
 * @invariants
 * - triangles_m length <= 2^20
 * - emitters_m length  <= 2^20
 * - skyEmission_m      >= 0
 * - groundReflection_m >= 0 and <= 1
 *)
class obj inBuffer_i eyePosition_i =

(* constants ---------------------------------------------------------------- *)
   let maxTriangles_k = 0x100000 in


(* construction ------------------------------------------------------------- *)
   (* read default scene background *)
   let skyEmission_c      = vRead inBuffer_i in
   let groundReflection_c = vRead inBuffer_i in

   (* read triangles in sequence *)
   let triangles_c = let rec readTriangle ts i =
         try
            if i = 0 then
               ts else readTriangle ((new Triangle.obj inBuffer_i) :: ts) (i-1)
         (* EOF is not really exceptional here, but the code is simpler *)
         with
            | End_of_file -> ts in
      (* maximum of a 2^20 *)
      readTriangle [] maxTriangles_k in

   (* find emitting triangles *)
   let emitters_c =
      (* has non-zero emission and area *)
      let isEmitter t = (t#emitivity <> vZero) && (t#area > 0.0) in
      List.filter isEmitter triangles_c in


object (__)

(* fields ------------------------------------------------------------------- *)
   val triangles_m = Array.of_list triangles_c
   val emitters_m  = Array.of_list emitters_c
   val index_m     = SpatialIndex.create eyePosition_i triangles_c

   val skyEmission_m      = vClamp vZero vMaximum skyEmission_c
   val groundReflection_m = vClamp vZero vOne     groundReflection_c


(* queries ------------------------------------------------------------------ *)
   (**
    * Nearest intersection of ray with object.
    *
    * @param rayOrigin    (Vector3f.vT)  ray origin
    * @param rayDirection (Vector3f.vT)  ray direction unitized
    * @param lastHit      (Triangle.var) previous intersected object
    * @return (Triangle.var, Vector3f.vT) object|null hit, and hit position
    *)
   method intersection rayOrigin rayDirection lastHit =

      SpatialIndex.intersection index_m rayOrigin rayDirection lastHit


   (**
    * Monte-carlo sample point on monte-carlo selected emitting object.
    *
    * @param random (Random.State.t) random number generator
    * @return (Triangle.var, Vector3f.vT) object|null, and point on the
    * object
    *)
   method emitter random =

      if __#emittersCount > 0 then
         (* select emitter *)
         let emitter = emitters_m.(Random.State.int random __#emittersCount) in

         (* get position on triangle *)
         (Some emitter, emitter#samplePoint random)
      else
         (None, vZero)


   (**
    * Number of emitters in scene.
    *
    * @return (int) number of emitters
    *)
   method emittersCount = Array.length emitters_m


   (**
    * Default/'background' light of scene universe.
    *
    * @param eyeDirection (Vector3f.vT) direction to eye
    * @return (Vector3f.vT) emitted radiance
    *)
   method defaultEmission eyeDirection =

      (* sky for downward ray, ground for upward ray *)
      if (vDot eyeDirection vOneY) < 0.0 then
         skyEmission_m else skyEmission_m *| groundReflection_m

end
