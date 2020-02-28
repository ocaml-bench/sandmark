(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




(**
 * Control module and entry point.
 *
 * Handles command-line UI, and runs the main progressive-refinement render
 * loop.
 *
 * Supply a model file pathname as the command-line argument. Or -? for help.
 *)




(* user messages ------------------------------------------------------------ *)
let title     = "MiniLight 1.5.2 OCaml"
and copyright = "Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241."
and uri       = "http://www.hxa7241.org/minilight/"
and date      = "2008-02-17"

let bannerMessage = "\n  " ^ title ^ "\n  " ^ copyright ^ "\n  " ^ uri ^ "\n"

let helpMessage   = "\n\
   ----------------------------------------------------------------------\n  \
     " ^ title ^ "\n\n  " ^ copyright ^ "\n  " ^ uri ^ "\n\n  " ^ date ^ "\n\
   ----------------------------------------------------------------------\n\
   \n\
   MiniLight is a minimal global illumination renderer.\n\
   \n\
   usage:\n  \
     minilight modelFilePathName\n\
   \n\
   The model text file format is: \n  \
     #MiniLight\n\
   \n  \
     iterations\n\
   \n  \
     imagewidth imageheight\n\
   \n  \
     viewposition viewdirection viewangle\n\
   \n  \
     skyemission groundreflection\n  \
     vertex0 vertex1 vertex2 reflectivity emitivity\n  \
     vertex0 vertex1 vertex2 reflectivity emitivity\n  \
     ...\n\
   \n\
   -- where iterations and image values are ints, viewangle is a float,\n\
   and all other values are three parenthised floats. The file must end\n\
   with a newline. Eg.:\n  \
     #MiniLight\n\
   \n  \
     100\n\
   \n  \
     200 150\n\
   \n  \
     (0 0.75 -2) (0 0 1) 45\n\
   \n  \
     (3626 5572 5802) (0.1 0.09 0.07)\n  \
     (0 0 0) (0 1 0) (1 1 0)  (0.7 0.7 0.7) (0 0 0)\n\
   \n"




(* setup ctrl-c interrupt handling ------------------------------------------ *)
let () = Sys.catch_break true


let saveImage imageFilePathname image frameNo =

   (* open file, write, close *)
   let imageFile = open_out_bin imageFilePathname in
   let _ = image#formatted imageFile (frameNo - 1) in
   close_out imageFile ;;


let modelFormatId = "#MiniLight" ;;
let savePeriod    = 180.0 ;;




(* entry point -------------------------------------------------------------- *)
try

   (* check if help message needed *)
   if ((Array.length Sys.argv) <= 1) ||
      (Sys.argv.(1) = "-?") || (Sys.argv.(1) = "--help") then

      print_string helpMessage

   (* execute *)
   else
      let () = print_endline bannerMessage in

      (* get file names *)
      let modelFilePathname = Sys.argv.(1) in
      let imageFilePathname = modelFilePathname ^ ".ppm" in

      (* open model file *)
      let modelFile = Scanf.Scanning.from_file modelFilePathname in

      (* check model file format identifier at start of first line *)
      if Scanf.bscanf modelFile "%s" ((=) modelFormatId)
         then () else failwith "invalid model file" ;

      (* read frame iterations (before any other reading) *)
      let iterations = Scanf.bscanf modelFile " %u" (max 1) in

      (* create top-level rendering objects with model file, in this order
         (image is mutable) *)
      let image  = new Image.obj  modelFile in
      let camera = new Camera.obj modelFile in
      let scene  = new Scene.obj  modelFile camera#eyePoint in

      (* make deterministic *)
      let random = Random.State.make [|1|] in
      (*let random = Random.State.make_self_init in*)

      (* (must now be imperative so relevant data can be caught with ctrl-c) *)
      let lastTime = ref ~-.181.0
      and frameNo  = ref 0 in
      try
         (* do progressive refinement render loop *)
         while frameNo := !frameNo + 1 ; !frameNo <= iterations do

            (* render a frame *)
            let _ = camera#frame scene image random in

            (* save image every three minutes, and at start and end *)
            if (savePeriod < ((Sys.time ()) -. !lastTime)) ||
               (!frameNo = iterations) then begin
               lastTime := (Sys.time ()) ;
               saveImage imageFilePathname image !frameNo
            end else
               () ;

            (* display latest frame number *)
            let backspaces = String.make ((if !frameNo > 1 then
               truncate(log10 (float (!frameNo - 1))) else -1) + 12) '\b' in
            Printf.printf "%siteration: %u%!" backspaces !frameNo

         done ;

         print_string "\nfinished\n"

      with
      (* handle ctrl-c interrupt *)
      | Sys.Break ->
         let () = saveImage imageFilePathname image !frameNo in
         print_string "\ninterrupted\n"

with e ->
   let () = print_string "*** execution failed:  " in
   raise e
