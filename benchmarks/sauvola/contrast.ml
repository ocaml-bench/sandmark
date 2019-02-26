(**
 * Contrast-Enhancement,
 *
 * contains functions to enhance contrast of scanned images
 *
 * Code should be compiled successfully under Debian Wheezy
 * with following line:
 *
 *   ocamlopt.opt -I +camlimages camlimages_core.cmxa unix.cmxa
 *      graphics.cmxa camlimages_graphics.cmxa
 *      camlimages_all.cmxa contrast.ml -o contrast
 *
 * It depends on: camlimages and standard ocaml library
 * (on Debian Wheezy: libcamlimages-ocaml-dev, libcamlimages-ocaml,
 * ocaml-native-compilers)
 *  
 * call the program with:
 *
 *   ./contrast foo.png bar
 *
 * (generates a lot of bar*.png files using different binarization methods)
 *
 * Code is distributed under the terms of the GNU General Public License 
 * (v2.0 or higher), described in file LICENSE.
 *                                                                    
 * (c) 2009-12 Andreas Romeyke
 * E-Mail: bench@andreas-romeyke.de
 *
 *)

open Images
open OImages
open Rgb24
open Info
open Color

type window_t = 
  {
    x0 : int;
    y0 : int;
    x1 : int;
    y1 : int;
  }


type img_statistics_t =
        {
                r_mean: float;
                g_mean: float;
                b_mean: float;
                r_stddev: float;
                g_stddev: float;
                b_stddev: float;
        }


(** decurrify a function expecting a tupel of values *)
 let uncurry f (x,y) = f x y


(** currify a function to a function expecting a tupel of values *)
let curry f x y = f (x,y)


(** creates a memoized version of given function f(x). Use it as following code:
  * let f x = (* your code here *) ()
  * let mem_f = memo f in
  * mem_f x
  *
  * HINT: do not use it in that way: memo f x
  * @return memoized function
  *)
let memo f = 
  let m= Hashtbl.create 1000 in
    fun x -> 
        try  
          Hashtbl.find m x
        with Not_found -> 
           if (Hashtbl.length m) > 1000 then Hashtbl.clear m; 
            let r = f x in 
              (Hashtbl.add m x r; r)
 

(** creates a memoized version of given function f(x;y). Use it as following code:
  * let f x y = (* your code here *) ()
  * let mem_f = memo2 f in
  * mem_f x y
  *
  * HINT: do not use it in that way: memo f x y
  * @return memoized function
  *)
let memo2 f =  curry ( memo ( uncurry f ) )



(** internal function to calc stddev using squared sum
  * @param qsum squared sum
  * @param sum sum
  * @param n n
  * @return stddev of image
  *)
let stddev qsum sum n =
  let mean = sum /. n in
  let prevariance = (qsum -. (sum *. mean)) /. (n -. 1.0) in
    assert(prevariance >= 0.0);
    sqrt prevariance


(* calc image statistics, mean and standard deviation of each RGB-channel
 * @param img image
 * @return stat type
 *)
let get_image_statistics img =
 (* calc sums *)
  let rsum = ref 0 in
  let gsum = ref 0 in
  let bsum = ref 0 in
  let rqsum = ref 0 in
  let gqsum = ref 0 in
  let bqsum = ref 0 in
    for i = 0 to img#width -1 do
      for j = 0 to img#height -1 do
        let v = img#get i j in
          rsum:=!rsum + v.r;
          gsum:=!gsum + v.g;
          bsum:=!bsum + v.b;
          rqsum:=!rqsum + (v.r * v.r);
          gqsum:=!gqsum + (v.g * v.g);
          bqsum:=!bqsum + (v.b * v.b);
      done
    done;
    let n = img#width * img#height in
    (* calc stddev *)
    (* calc mean *)
    (* calc median *)
    {
            r_stddev=stddev (float_of_int !rqsum) (float_of_int !rsum) (float_of_int n);
            g_stddev=stddev (float_of_int !gqsum) (float_of_int !gsum) (float_of_int n);
            b_stddev=stddev (float_of_int !bqsum) (float_of_int !bsum) (float_of_int n);
            r_mean= (float_of_int !rsum) /. (float_of_int n);
            g_mean= (float_of_int !gsum) /. (float_of_int n);
            b_mean= (float_of_int !bsum) /. (float_of_int n);
    }           


let constantR = 128.0 (* 256 pixel per chan -> 256/2=128 , used for sauvola *)

(* 15x15 is based on paper of Sezgin and Sankur,
 * "Survey over image thresholding techniques and quantitative performance evaluation",
 * but the algorithm only works correctly if window is covering two characters,
 * therefore 30x30 is used for scanned images with 300 dpi
 *)
let window_size=(30,30) 

(** internal_function, needed to calc window "on the fly" *)
let wrect width height wd_width wd_height x y =
  let x0=let t = x-wd_width/2 in if t < 0 then 0 else t in
  let y0=let t = y-wd_height/2 in if t < 0 then 0 else t in
  let x1=let t = x+wd_width/2 in if t > width -1 then width -1 else t in
  let y1=let t = y+wd_height/2 in if t > height -1 then height -1 else t in
    { x0=x0; y0=y0; x1=x1; y1=y1; }


(** adaptive contrast spreading
 * @param img source image
 * @return target image
 *)
let adaptive_contrast_spreading img =
  let (wd_w, wd_h)=window_size in
    assert(img#width > wd_w);
    assert(img#height > wd_h);
    let img' = new OImages.rgb24 img#width img#height in
      for y = 0 to img#height -1 do
        for x = 0 to img#width -1 do
        Printf.printf "\t\racs: %i%% done" (100*y/img#height); flush stdout;
          let wrect = wrect img#width img#height wd_w wd_h x y in
          let window = img#sub wrect.x0 wrect.y0 (wrect.x1-wrect.x0) (wrect.y1-wrect.y0) in
          let stats = get_image_statistics window in
          let normed v mean stddev =
            let v' = float_of_int v in
            let lower_bound = mean -. (3.0 *. stddev) in
            let upper_bound = mean +. (3.0 *. stddev) in
            let normed_v' = 
              255.0*.(v' -. lower_bound)
              /.
              (upper_bound -. lower_bound)
            in
              if normed_v' > 127.0 then 255 else 0
          in
          let color = img#get x y in
          let r' = normed color.r stats.r_mean stats.r_stddev in
          let g' = normed color.g stats.g_mean stats.g_stddev in
          let b' = normed color.b stats.b_mean stats.b_stddev in
          let (c:Color.rgb) = {r=r';g=g';b=b'} in
          img'#set x y c
        done
      done;
      Printf.printf "\nDone\n"; flush stdout;
      img'


(** global contrast maximization based on idea of Niblack,
  * -0.2 is an experimental value from original,
  * see W.Niblack, An Introduction to
  * Image Processing, pp115-116, Prentice Hall, Englewood Cliffs, NJ (1986)
  * @param img original image
  * @return binarized image
  *)
let niblack_global_contrast_maximization img =
  let stats = get_image_statistics img in
  let threshold mean stddev = mean -. (0.2 *. stddev) in
  let r_threshold = threshold stats.r_mean stats.r_stddev in
  let g_threshold = threshold stats.g_mean stats.g_stddev in
  let b_threshold = threshold stats.b_mean stats.b_stddev in
    (*
    Printf.printf "niblack-mean:%f %f %f\n" stats.r_mean stats.g_mean stats.b_mean; flush stdout;
    Printf.printf "niblack-stddev:%f %f %f\n" stats.r_stddev stats.g_stddev stats.b_stddev; flush stdout;
    Printf.printf "niblack-threshold:%f %f %f\n" r_threshold g_threshold b_threshold; flush stdout;
    *)
    let img' = new OImages.rgb24 img#width img#height in
      for h = 0 to img#height -1 do
        for w = 0 to img#width -1 do
          let color = img#get w h in
          let r' = if (float_of_int color.r) > r_threshold then 255 else 0 in
          let g' = if (float_of_int color.g) > g_threshold then 255 else 0 in
          let b' = if (float_of_int color.b) > b_threshold then 255 else 0 in
          let (c:Color.rgb) = {r=r';g=g';b=b'} in
            img'#set w h c
        done
      done;
      img'


(** local adaptive contrast maximization based on idea of Niblack,
  * -0.2 is an experimental value from original,
  * see W.Niblack, An Introduction to
  * Image Processing, pp115-116, Prentice Hall, Englewood Cliffs, NJ (1986)
  *
  * @param img original image
  * @return binarized image
  *)
let niblack_local_contrast_maximization img =
  let (wd_w, wd_h)=window_size in
    assert(img#width > wd_w);
    assert(img#height > wd_h);
    let img' = new OImages.rgb24 img#width img#height in
      for y = 0 to img#height -1 do
        Printf.printf "\t\rniblack: %i%% done" (100*y/img#height); flush stdout;
        for x = 0 to img#width -1 do
          let wrect = wrect img#width img#height wd_w wd_h x y in
          assert( wrect.x0 >= 0);
          assert( wrect.y0 >= 0);
          assert( wrect.x1 < img#width);
          assert( wrect.y1 < img#height);
          let window = img#sub wrect.x0 wrect.y0 (wrect.x1-wrect.x0) (wrect.y1-wrect.y0) in
          let stats = get_image_statistics window in
          let threshold mean stddev = mean -. (0.2 *. stddev) in
          let r_threshold = threshold stats.r_mean stats.r_stddev in
          let g_threshold = threshold stats.g_mean stats.g_stddev in
          let b_threshold = threshold stats.b_mean stats.b_stddev in
          let color = img#get x y in
          let r' = if (float_of_int color.r) > r_threshold then 255 else 0 in
          let g' = if (float_of_int color.g) > g_threshold then 255 else 0 in
          let b' = if (float_of_int color.b) > b_threshold then 255 else 0 in
          let (c:Color.rgb) = {r=r';g=g';b=b'} in
            img'#set x y c
        done
      done;
      Printf.printf "\nDone\n"; flush stdout;
      img'


(**
  * calculate mean and variance of all brightness values of pixels in window at
  * given coordinate. Use optimized variant if x' = and y' = y+1 by using cached
  * sums
  * @param img given image
  * @param x x-coordinate
  * @param y y-coordinate
  * @param cache cache to hold cached sums and some conditions
  * @return tupel of mean and variance
  *)
let get_window_values img x y cache =
  let (cached_sum, cached_qsum, cached_n, last_x, last_y) = cache in
  let (wd_w, wd_h)=window_size in
  assert(img#width > wd_w);
  assert(img#height > wd_h);
  let window = wrect img#width img#height wd_w wd_h x y in
  let qsum = ref 0 in
  let sum = ref 0 in
  let n = ref 0 in
  let optimized_values_update () =
    qsum:= !cached_qsum;
    sum:= !cached_sum;
    n:= !cached_n;
    for y' = window.y0 to window.y1 do
      let l  = img#get (window.x0-1) y' |> Color.brightness in
      let l' = img#get window.x1    y' |> Color.brightness in
        qsum := !qsum + (l'*l') - (l*l);
        sum := !sum + (l') - (l);
    done
  in
  let standard_values_update () =
    for y' = window.y0 to window.y1 do
      for x' = window.x0 to window.x1 do
        let l = img#get x' y' |> Color.brightness in
          qsum := !qsum + (l*l);
          sum := !sum  + (l);
      done
    done;
    n:= (1 + window.y1 - window.y0) * 
    (1 + window.x1 - window.x0);
  in
    if 
      (window.x0 > 0) &&
      (window.x1 < img#width) &&
      (!cached_n > 0) &&
      ((!last_y) = y) &&
      ((!last_x +1 ) = x)
    then
    (* special optimized variant *) optimized_values_update ()
      else (* standard variant *) standard_values_update ();
      cached_sum := !sum;
      cached_qsum := !qsum;
      cached_n := !n;
      last_x := x;
      last_y := y;
      (* now calc mean and variance *) 
      let mean = !sum / !n in
      let variance = (
        (
          !qsum - 
          (!sum * mean)
        )
        / (!n - 1)
      ) 
      in
        (mean, variance)


(** local adaptive contrast maximization based on idea of Niblack,
  * -0.2 is an experimental value from original,
  * see W.Niblack, An Introduction to
  * Image Processing, pp115-116, Prentice Hall, Englewood Cliffs, NJ (1986)
  *
  * @param img original image
  * @return binarized image
  *)
let niblack_local_monochromize img =
  let cache = (ref 0, ref 0, ref 0, ref 0, ref 0) in
  let threshold mean variance = (float_of_int mean) -. (0.2 *. sqrt (float_of_int variance)) in
  let mem_threshold = memo2 threshold in
    let img' = new OImages.rgb24 img#width img#height in
      for y = 0 to img#height -1 do
        Printf.printf "\t\rniblack: %i%% done" (100*y/img#height); flush stdout;
        for x = 0 to img#width -1 do
          let (mean, variance) = get_window_values img x y cache in
          let l_threshold = mem_threshold mean variance in
          let color = img#get x y in
          let l = Color.brightness color in
          let v = if (float_of_int l) > l_threshold then 255 else 0 in
          let c = {r=v; g=v; b=v;} in
            img'#set x y c 
        done
      done;
      Printf.printf "\nDone\n"; flush stdout;
      img'


(** global contrast maximization based on idea of Sauvola,
  * the algorithm is one of the best as compared in Sezgin and Sankur, Survey over
  * image thresholding techniques and quantitive performance evaluation, Journal
  * of Electronic Imaging 13(1), 146-165 (January 2004)
  *
  * @param img original image
  * @return binarized image
  *)
let sauvola_global_contrast_maximization img =
        let stats = get_image_statistics img in
  let threshold mean stddev = mean +. (
    1.0 +. (0.6 *. (stddev /. constantR -. 1.0))
  ) in
  let r_threshold = threshold stats.r_mean stats.r_stddev in
  let g_threshold = threshold stats.g_mean stats.g_stddev in
  let b_threshold = threshold stats.b_mean stats.b_stddev in
    Printf.printf "sauvola-mean:%f %f %f\n" stats.r_mean stats.g_mean stats.b_mean; flush stdout;
    Printf.printf "sauvola-stddev:%f %f %f\n" stats.r_stddev stats.g_stddev stats.b_stddev; flush stdout;
    Printf.printf "sauvola-threshold:%f %f %f\n" r_threshold g_threshold b_threshold; flush stdout;
    let img' = new OImages.rgb24 img#width img#height in
      for h = 0 to img#height -1 do
        for w = 0 to img#width -1 do
          let color = img#get w h in
          let r' = if (float_of_int color.r) > r_threshold then 255 else 0 in
          let g' = if (float_of_int color.g) > g_threshold then 255 else 0 in
          let b' = if (float_of_int color.b) > b_threshold then 255 else 0 in
          let c = {r=r'; g=g'; b=b'} in
            img'#set w h c
        done
      done;
      img'


(** see sauvola_global_contrast_maximization, but only monochromize *)
let sauvola_global_monochromize img =
        let stats = get_image_statistics img in
        let threshold mean stddev = mean +. (
                1.0 +. (0.6 *. (stddev /. constantR -. 1.0))
                ) 
        in
        let r_threshold = threshold stats.r_mean stats.r_stddev in
        let g_threshold = threshold stats.g_mean stats.g_stddev in
        let b_threshold = threshold stats.b_mean stats.b_stddev in
        let img' = new OImages.rgb24 img#width img#height in
        for h = 0 to img#height -1 do
                for w = 0 to img#width -1 do
                        let color = img#get w h in
                        let v = 
                                if ( 
                                        ((float_of_int color.r) > r_threshold) ||
                                        ((float_of_int color.g) > g_threshold) ||
                                        ((float_of_int color.b) > b_threshold)
                                        ) then 255 else 0 in
                        let c = {r=v; g=v; b=v;} in
                        img'#set w h c
                done
        done;
      img'



(** local adaptive contrast maximization based on Sauvola,
  * the algorithm is one of the best as compared in Sezgin and Sankur, Survey over
  * image thresholding techniques and quantitive performance evaluation, Journal
  * of Electronic Imaging 13(1), 146-165 (January 2004)
  *
  * @param img original image
  * @return binarized image
  *)
let sauvola_local_contrast_maximization img =
  let img' = new OImages.rgb24 img#width img#height in
  let (wd_w, wd_h)=window_size in
  let threshold mean stddev = mean *. (
    1.0 -. (0.35 *. (1.0 -. stddev /. constantR))
  ) 
  in
  let mem_threshold = memo2 threshold in
    for y = 0 to img#height -1 do
      Printf.printf "\t\rsauvola: %i%% done" (100*y/img#height); flush stdout;
      for x = 0 to img#width -1 do
        let color = img#get x y in
        if ((Color.brightness color > 200)) then img'#set x y {r=255; g=255; b=255;}
          else
            begin
              let wrect = wrect img#width img#height wd_w wd_h x y in
              let window = img#sub wrect.x0 wrect.y0 (wrect.x1-wrect.x0) (wrect.y1-wrect.y0) in
              let stats = get_image_statistics window in
              let r_threshold = mem_threshold stats.r_mean stats.r_stddev in
              let g_threshold = mem_threshold stats.g_mean stats.g_stddev in
              let b_threshold = mem_threshold stats.b_mean stats.b_stddev in
              let r' = if (float_of_int color.r) > r_threshold then 255 else 0 in
              let g' = if (float_of_int color.g) > g_threshold then 255 else 0 in
              let b' = if (float_of_int color.b) > b_threshold then 255 else 0 in
              let c = {r=r'; g=g'; b=b';} in
                img'#set x y c
            end
      done
    done;
    Printf.printf "\nDone\n"; flush stdout;
    img'


(** local adaptive contrast maximization based on Sauvola,
  * the algorithm is one of the best as compared in Sezgin and Sankur, Survey over
  * image thresholding techniques and quantitive performance evaluation, Journal
  * of Electronic Imaging 13(1), 146-165 (January 2004)
  *
  * @param img original image
  * @return binarized image
  *)
let sauvola_local_monochromize img =
  let cache = (ref 0, ref 0, ref 0, ref 0, ref 0) in
  let img' = new OImages.rgb24 img#width img#height in
    let threshold mean variance = 
      (float_of_int mean) *. (
          1.0 -. (0.35 *. (1.0 -. (sqrt (float_of_int variance)) /. constantR))
        )
    in
    let mem_threshold = memo2 threshold in
      for y = 0 to img#height -1 do
        Printf.printf "\t\rsauvola: %i%% done" (100*y/img#height); flush stdout;
        for x = 0 to img#width -1 do
          let c = img#get x y in
          let l = Color.brightness c in
            (* if lightness > 200 set white *)
          if (l > 200) then img'#set x y {r=255; g=255; b=255;}
            else
              begin
                let (mean, variance) = get_window_values img x y cache in
                               let l_threshold = mem_threshold mean variance in
                               let v = if (float_of_int l) > l_threshold then
                                       255 else 0 
                               in
                  img'#set x y {r=v; g=v; b=v;} 
              end
        done
      done;
      Printf.printf "\nDone\n"; flush stdout;
      img'


(** helper to save new image 
 * @param outfile name of outfile image
 * @param img image to save
 *)
let save_image_as outfile img = 
        img#save outfile None []


(** helper tp load image
 * @param infile name of infile image
 * @return image
 *)
let load infile = OImages.rgb24 (OImages.load infile [])

(** main routine *)
let _ =
        try
                let infile = Sys.argv.(1) in
                let outfile_prefix = Sys.argv.(2) in
                let img = load infile in
                let dims = Printf.sprintf " %ix%i" img#width img#height in
                Printf.printf "dims: %s\n" dims;
                let start0 = Unix.gettimeofday () in
                save_image_as (outfile_prefix^"__adaptive_contrast_spreading.ppm") (img |> adaptive_contrast_spreading);
                let start1 = Unix.gettimeofday () in
                Printf.printf "%f s adaptive contrast spreading\n" (start1 -. start0);
                save_image_as (outfile_prefix^"__niblack_global_gray.ppm") (img |> niblack_global_contrast_maximization);
                let start2 = Unix.gettimeofday () in
                Printf.printf "%f s niblack global gray\n" (start2 -. start1);
                 save_image_as (outfile_prefix^"__niblack_local_gray.ppm") (img |> niblack_local_contrast_maximization);
                let start3 = Unix.gettimeofday () in
                Printf.printf "%f s niblack local gray\n" (start3 -. start2);
                save_image_as (outfile_prefix^"__niblack_local_monochrome.ppm") (img |> niblack_local_monochromize);
                let start4 = Unix.gettimeofday () in
                Printf.printf "%f s niblack local mono\n" (start4 -. start3);
                save_image_as (outfile_prefix^"__sauvola_global_gray.ppm") (img |> sauvola_global_contrast_maximization); 
                let start5 = Unix.gettimeofday () in
                Printf.printf "%f s sauvola global gray\n" (start5 -. start4);
                save_image_as (outfile_prefix^"__sauvola_global_monochrome.ppm") (img |> sauvola_global_monochromize);
                let start6 = Unix.gettimeofday () in
                Printf.printf "%f s sauvola global mono\n" (start6 -. start5);
                save_image_as (outfile_prefix^"__sauvola_local_gray.ppm") (img |> sauvola_local_contrast_maximization);
                let start7 = Unix.gettimeofday () in
                Printf.printf "%f s sauvola local gray\n" (start7 -. start6);
                save_image_as (outfile_prefix^"__sauvola_local_monochrome.ppm") (img |> sauvola_local_monochromize);
                let start8 = Unix.gettimeofday () in
                Printf.printf "%f s sauvola local mono\n" (start8 -. start7);
        with
        | Stack_overflow -> Printf.printf "A stackoverflow occured, please increase stacksize with 'ulimit -s 65535'\n";
        | Invalid_argument s -> Printf.printf "\n%s\n" s

let () =
  try
    let fn = Sys.getenv "OCAML_GC_STATS" in
    let oc = open_out fn in
    Gc.print_stat oc
  with _ -> ()
