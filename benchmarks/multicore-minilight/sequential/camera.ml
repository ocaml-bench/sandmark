(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * A View with rasterization capability.
 *
 * @param inBuffer_i (Scanf.Scanning.scanbuf) to read from
 *
 * @invariants
 * - viewAngle_m is >= 10 and <= 160 degrees in radians
 * - viewDirection_m is unitized
 * - right_m is unitized
 * - up_m is unitized
 * - above three form a coordinate frame
 *)
class obj inBuffer_i =

(* construction ------------------------------------------------------------- *)
   (* read view position *)
   let viewPosition_c = vRead inBuffer_i in

   (* read and condition view direction *)
   let viewDirection_c = let vd = vUnitize (vRead inBuffer_i) in
      if vd <> vZero then vd else vOneZ in

   (* read and condition view angle *)
   let viewAngle_c = Scanf.bscanf inBuffer_i " %f" (fun v ->
      (max 10.0 (min v 160.0)) *. (3.141592653589793238512809 /. 180.0)) in

   (* make other directions of frame *)
   let right_c, up_c =
      let right = vUnitize (vCross vOneY viewDirection_c) in
      if right <> vZero then
         (right, vUnitize (vCross viewDirection_c right))
      else
         let up = if viewDirection_c.(1) < 0.0 then vOneZ else ~-|vOneZ in
         (vUnitize (vCross up viewDirection_c), up) in


object (__)

(* fields ------------------------------------------------------------------- *)
   val viewPosition_m  = viewPosition_c
   val viewAngle_m     = viewAngle_c

   (* view frame *)
   val viewDirection_m = viewDirection_c
   val right_m         = right_c
   val up_m            = up_c


(* queries ------------------------------------------------------------------ *)
   method eyePoint = viewPosition_m


   (**
    * Accumulate a frame to the image.
    *
    * @param scene  (Scene.obj)      scene to render
    * @param image  (Image.obj)      image to add to
    * @param random (Random.State.t) random number generator
    * @return (Image.obj) modified image
    *)
   method frame (scene:Scene.obj) (image:Image.obj) random =

      let rayTracer = new RayTracer.obj scene

      and width, height = (float image#width, float image#height) in

      (* do image sampling pixel loop *)
      let () = for y = image#height - 1 downto 0 do
         for x = image#width - 1 downto 0 do

            (* make sample ray direction, stratified by pixels *)
            let sampleDirection =

               (* make image plane displacement vector coefficients *)
               let xF, yF = let rand () = Random.State.float random 1.0 in
                  ( (((float x) +. (rand ())) *. 2.0 /. width ) -. 1.0,
                    (((float y) +. (rand ())) *. 2.0 /. height) -. 1.0 ) in

               (* make image plane offset vector *)
               let offset = (right_m *|. xF) +|
                  (up_m *|. (yF *. (height /. width))) in

               vUnitize (viewDirection_m +|
                  (offset *|. (tan (viewAngle_m *. 0.5)))) in

            (* get radiance from RayTracer *)
            let radiance =
               rayTracer#radiance viewPosition_m sampleDirection random in

            (* add radiance to pixel *)
            image#addToPixel x y radiance

         done
      done in

      image

end
