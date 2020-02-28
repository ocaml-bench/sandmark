(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * Pixel sheet with simple tone-mapping and file formatting.
 *
 * Mutable.
 *
 * Uses PPM image format:
 * http://netpbm.sourceforge.net/doc/ppm.html
 *
 * Uses Ward simple tonemapper:
 * 'A Contrast Based Scalefactor For Luminance Display'
 * Ward;
 * Graphics Gems 4, AP 1994.
 *
 * @param inBuffer_i (Scanf.Scanning.scanbuf) to read from
 *
 * @invariants
 * - width_m  >= 1 and <= 10000
 * - height_m >= 1 and <= 10000
 * - pixels_m length = (width_m * height_m)
 *)
class obj inBuffer_i =

(* construction ------------------------------------------------------------- *)
   (* read width then height, with conditioning *)
   let width_c, height_c = Scanf.bscanf inBuffer_i " %u %u"
      (fun w h -> (max 1 (min w 10000), max 1 (min h 10000))) in


(* constants ---------------------------------------------------------------- *)
   (* format items *)
   let ppmId_k        = "P6"
   and minilightUri_k = "http://www.hxa7241.org/minilight/" in

   (* guess of average screen maximum brightness,
      ITU-R BT.709 standard RGB luminance weighting,
      ITU-R BT.709 standard gamma *)
   let displayLuminanceMax_k = 200.0
   and rgbLuminance_k        = vCreate 0.2126 0.7152 0.0722
   and gammaEncode_k         = 0.45 in


(* class methods ------------------------------------------------------------ *)
   (**
    * Calculate tone-mapping scaling factor.
    *
    * @param pixels  (vector3f.vT array) pixels
    * @param divider (float)             pixel scaling factor
    * @return (float) scaling factor
    *)
   let toneMapping pixels divider =

      (* calculate log mean luminance *)
      let logMeanLuminance =
         let sumOfLogs = let logSummer sum pixel =

            let y = (vDot pixel rgbLuminance_k) *. divider in
            sum +. (log10 (max 1e-4 y)) in

            Array.fold_left logSummer 0.0 pixels in

         10.0 ** (sumOfLogs /. (float (Array.length pixels))) in

      (* what do these mean again? (must check the tech paper...) *)
      let a = 1.219 +. ((displayLuminanceMax_k *. 0.25) ** 0.4)
      and b = 1.219 +. (logMeanLuminance                ** 0.4) in

      ((a /. b) ** 2.5) /. displayLuminanceMax_k in


object (__)

(* fields ------------------------------------------------------------------- *)
   val width_m  = width_c
   val height_m = height_c

   val pixels_m = Array.init (width_c * height_c) (fun _ -> vZero)


(* commands ----------------------------------------------------------------- *)
   (**
    * Accumulate (add, not just assign) a value to the image.
    *
    * @param x        (int)         x coord
    * @param y        (int)         y coord
    * @param radiance (Vector3f.vT) light value
    * @return ()
    *)
   method addToPixel x y radiance =

      if (x >= 0) && (x < width_m) && (y >= 0) && (y < height_m) then
         let index = x + ((height_m - 1 - y) * width_m) in
         pixels_m.(index) <- (pixels_m.(index) +| radiance)
      else
         ()


(* queries ------------------------------------------------------------------ *)
   method width  = width_m

   method height = height_m


   (**
    * Format the image.
    *
    * @param out       (out_channel) to receive the image
    * @param iteration (int)         number of accumulations made to the image
    * @return (out_channel) after receiving the image
    *)
   method formatted out iteration =

      let divider = 1.0 /. (float ((max 0 iteration) + 1)) in

      let tonemapScaling = toneMapping pixels_m divider in

      (* write ID and comment *)
      let () = Printf.fprintf out "%s\n# %s\n\n" ppmId_k minilightUri_k in

      (* write width, height, maxval *)
      let () = Printf.fprintf out "%u %u\n%u\n" width_m height_m 255 in

      (* write pixels *)
      let pixelWriter pixel =
         let channelWriter c =

            (* tonemap, gamma encode, quantize *)
            let mapped   = max 0.0 (min (c *. divider *. tonemapScaling) 1.0) in
            let gammaed  = mapped ** gammaEncode_k in
            let quantized = max 0.0 (min ((gammaed *. 255.0) +. 0.5) 255.0) in

            (* output as byte *)
            output_byte out (truncate quantized) in

         Array.iter channelWriter pixel in
      let () = Array.iter pixelWriter pixels_m in

      out

end
