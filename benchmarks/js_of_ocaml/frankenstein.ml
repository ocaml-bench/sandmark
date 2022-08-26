  type t =
    { red : float
    ; green : float
    ; blue : float
    }

  let make r g b = { red = r; green = g; blue = b }

  (*
  let print ch c =
    let r = truncate (c.red *. 255.) in
    let g = truncate (c.green *. 255.) in
    let b = truncate (c.blue *. 255.) in
    Format.fprintf ch "rgb(%d,%d,%d)" r g b
*)

  let limit c =
    { red =
        (let red = c.red in
         if red <= 0. then 0. else if red > 1.0 then 1.0 else red)
    ; green =
        (let green = c.green in
         if green <= 0. then 0. else if green > 1.0 then 1.0 else green)
    ; blue =
        (let blue = c.blue in
         if blue <= 0. then 0. else if blue > 1.0 then 1.0 else blue)
    }

  let add c1 c2 =
    { red = c1.red +. c2.red; green = c1.green +. c2.green; blue = c1.blue +. c2.blue }

  let add_scalar c1 s =
    limit { red = c1.red +. s; green = c1.green +. s; blue = c1.blue +. s }


  let multiply c1 c2 =
    { red = c1.red *. c2.red; green = c1.green *. c2.green; blue = c1.blue *. c2.blue }

  let multiply_scalar c1 s =
    { red = c1.red *. s; green = c1.green *. s; blue = c1.blue *. s }


  let blend c1 c2 w = add (multiply_scalar c1 (1. -. w)) (multiply_scalar c2 w)

  let brightness c =
    let r = truncate (c.red *. 255.) in
    let g = truncate (c.green *. 255.) in
    let b = truncate (c.blue *. 255.) in
    ((r * 77) + (g * 150) + (b * 29)) lsr 8
end

module Vector = struct
  type t =
    { x : float
    ; mutable y : float
    ; z : float
    }

  let make x y z = { x; y; z }

  (*
  let print ch v = Format.fprintf ch "%f %f %f" v.x v.y v.z
*)

  let magnitude v = sqrt ((v.x *. v.x) +. (v.y *. v.y) +. (v.z *. v.z))

  let normalize v =
    let m = magnitude v in
    { x = v.x /. m; y = v.y /. m; z = v.z /. m }

  let cross v w =
    { x = (v.y *. w.z) -. (v.z *. w.y)
    ; y = (v.z *. w.x) -. (v.x *. w.z)
    ; z = (v.x *. w.y) -. (v.y *. w.x)
    }

  let dot v w = (v.x *. w.x) +. (v.y *. w.y) +. (v.z *. w.z)

  let add v w = { x = v.x +. w.x; y = v.y +. w.y; z = v.z +. w.z }

  let subtract v w = { x = v.x -. w.x; y = v.y -. w.y; z = v.z -. w.z }

  let multiply_scalar v w = { x = v.x *. w; y = v.y *. w; z = v.z *. w }
end

module Light = struct
  type t =
    { position : Vector.t
    ; color : Color.t
    ; intensity : float
    }

  let make p c i = { position = p; color = c; intensity = i }
end

module Ray = struct
  type t =
    { position : Vector.t
    ; direction : Vector.t
    }

  let make p d = { position = p; direction = d }
end

module Intersection_info = struct
  type 'a t =
    { shape : 'a
    ; distance : float
    ; position : Vector.t
    ; normal : Vector.t
    ; color : Color.t
    }
end

module Camera = struct
  type t =
    { position : Vector.t
    ; look_at : Vector.t
    ; equator : Vector.t
    ; up : Vector.t
    ; screen : Vector.t
    }

  let make pos look_at up =
    { position = pos
    ; look_at
    ; up
    ; equator = Vector.cross (Vector.normalize look_at) up
    ; screen = Vector.add pos look_at
    }

  let get_ray c vx vy =
    let pos =
      Vector.subtract
        c.screen
        (Vector.subtract
           (Vector.multiply_scalar c.equator vx)
           (Vector.multiply_scalar c.up vy))
    in
    pos.Vector.y <- pos.Vector.y *. -1.;
    let dir = Vector.subtract pos c.position in
    Ray.make pos (Vector.normalize dir)
end

module Background = struct
  type t =
    { color : Color.t
    ; ambience : float
    }

  let make c a = { color = c; ambience = a }
end

module Material = struct
  type t =
    { reflection : float
    ; transparency : float
    ; gloss : float
    ; has_texture : bool
    ; get_color : float -> float -> Color.t
    }

  let wrap_up t =
    let t = mod_float t 2.0 in
    if t < -1. then t +. 2.0 else if t >= 1. then t -. 2.0 else t

  let solid color reflection transparency gloss =
    { reflection
    ; transparency
    ; gloss
    ; has_texture = false
    ; get_color = (fun _ _ -> color)
    }

  let chessboard color_even color_odd reflection transparency gloss density =
    { reflection
    ; transparency
    ; gloss
    ; has_texture = true
    ; get_color =
        (fun u v ->
          let t = wrap_up (u *. density) *. wrap_up (v *. density) in
          if t < 0. then color_even else color_odd)
    }
end

module Shape = struct
  type shape =
    | Sphere of Vector.t * float
    | Plane of Vector.t * float

  type t =
    { shape : shape
    ; material : Material.t
    }

  let make shape material = { shape; material }

  let dummy =
    make
      (Sphere (Vector.make 0. 0. 0., 0.))
      (Material.solid (Color.make 0. 0. 0.) 0. 0. 0.)

  let position s =
    match s.shape with
    | Sphere (p, _) -> p
    | Plane (p, _) -> p

  let intersect s ray =
    match s.shape with
    | Sphere (position, radius) ->
        let dst = Vector.subtract ray.Ray.position position in
        let b = Vector.dot dst ray.Ray.direction in
        let c = Vector.dot dst dst -. (radius *. radius) in
        let d = (b *. b) -. c in
        if d > 0.
        then
          let dist = -.b -. sqrt d in
          let pos =
            Vector.add ray.Ray.position (Vector.multiply_scalar ray.Ray.direction dist)
          in
          Some
            { Intersection_info.shape = s
            ; distance = dist
            ; position = pos
            ; normal = Vector.normalize (Vector.subtract pos position)
            ; color = s.material.Material.get_color 0. 0.
            }
        else None
    | Plane (position, d) ->
        let vd = Vector.dot position ray.Ray.direction in
        if vd = 0.
        then None
        else
          let t = -.(Vector.dot position ray.Ray.position +. d) /. vd in
          if t <= 0.
          then None
          else
            let pos =
              Vector.add ray.Ray.position (Vector.multiply_scalar ray.Ray.direction t)
            in
            Some
              { Intersection_info.shape = s
              ; distance = t
              ; position = pos
              ; normal = position
              ; color =
                  (if s.material.Material.has_texture
                  then
                    let vu =
                      Vector.make
                        position.Vector.y
                        position.Vector.z
                        (-.position.Vector.x)
                    in
                    let vv = Vector.cross vu position in
                    let u = Vector.dot pos vu in
                    let v = Vector.dot pos vv in
                    s.material.Material.get_color u v
                  else s.material.Material.get_color 0. 0.)
              }
end

module Scene = struct
  type t =
    { camera : Camera.t
    ; shapes : Shape.t array
    ; lights : Light.t array
    ; background : Background.t
    }

  let make c s l b = { camera = c; shapes = s; lights = l; background = b }
end

module Engine = struct
  type t =
    { pixel_width : int
    ; pixel_height : int
    ; canvas_width : int
    ; canvas_height : int
    ; render_diffuse : bool
    ; render_shadows : bool
    ; render_highlights : bool
    ; render_reflections : bool
    ; ray_depth : int
    }

  let check_number = ref 0

  let get_reflection_ray p n v =
    let c1 = -.Vector.dot n v in
    let r1 = Vector.add (Vector.multiply_scalar n (2. *. c1)) v in
    Ray.make p r1

  let rec ray_trace options info ray scene depth =
    let old_color =
      Color.multiply_scalar
        info.Intersection_info.color
        scene.Scene.background.Background.ambience
    in
    let color = ref old_color in
    let shininess =
      10. ** (info.Intersection_info.shape.Shape.material.Material.gloss +. 1.)
    in
    let lights = scene.Scene.lights in
    for i = 0 to Array.length lights - 1 do
      let light = lights.(i) in
      let v =
        Vector.normalize
          (Vector.subtract light.Light.position info.Intersection_info.position)
      in
      (if options.render_diffuse
      then
        let l = Vector.dot v info.Intersection_info.normal in
        if l > 0.
        then
          color :=
            Color.add
              !color
              (Color.multiply
                 info.Intersection_info.color
                 (Color.multiply_scalar light.Light.color l)));
      (if depth <= options.ray_depth
      then
        if options.render_reflections
           && info.Intersection_info.shape.Shape.material.Material.reflection > 0.
        then
          let reflection_ray =
            get_reflection_ray
              info.Intersection_info.position
              info.Intersection_info.normal
              ray.Ray.direction
          in
          let col =
            match test_intersection reflection_ray scene info.Intersection_info.shape with
            | Some ({ Intersection_info.distance = d; _ } as info) when d > 0. ->
                ray_trace options info reflection_ray scene (depth + 1)
            | _ -> scene.Scene.background.Background.color
          in
          color :=
            Color.blend
              !color
              col
              info.Intersection_info.shape.Shape.material.Material.reflection);
      let shadow_info = ref None in
      if options.render_shadows
      then (
        let shadow_ray = Ray.make info.Intersection_info.position v in
        shadow_info := test_intersection shadow_ray scene info.Intersection_info.shape;
        match !shadow_info with
        | Some info ->
            (*XXX This looks wrong! *)
            let va = Color.multiply_scalar !color 0.5 in
            let db =
              0.5
              *. (info.Intersection_info.shape.Shape.material.Material.transparency ** 0.5)
            in
            color := Color.add_scalar va db
        | None -> ());
      if options.render_highlights
         && !shadow_info <> None
         && info.Intersection_info.shape.Shape.material.Material.gloss > 0.
      then
        (*XXX This looks wrong! *)
        let shape_position = Shape.position info.Intersection_info.shape in
        let lv = Vector.normalize (Vector.subtract shape_position light.Light.position) in
        let e =
          Vector.normalize
            (Vector.subtract scene.Scene.camera.Camera.position shape_position)
        in
        let h = Vector.normalize (Vector.subtract e lv) in
        let gloss_weight =
          max (Vector.dot info.Intersection_info.normal h) 0. ** shininess
        in
        color := Color.add (Color.multiply_scalar light.Light.color gloss_weight) !color
    done;
    Color.limit !color

  and test_intersection ray scene exclude =
    let best = ref None in
    let dist = ref 2000. in
    let shapes = scene.Scene.shapes in
    for i = 0 to Array.length shapes - 1 do
      let shape = shapes.(i) in
      if shape != exclude
      then
        match Shape.intersect shape ray with
        | Some { Intersection_info.distance = d; _ } as v when d >= 0. && d < !dist ->
            best := v;
            dist := d
        | _ -> ()
    done;
    !best

  let get_pixel_color options ray scene =
    match test_intersection ray scene Shape.dummy with
    | Some info -> ray_trace options info ray scene 0
    | None -> scene.Scene.background.Background.color

  let set_pixel _options x y color =
    if x == y then check_number := !check_number + Color.brightness color;
    ( (*
    let pxw = options.pixel_width in
    let pxh = options.pixel_height in
    Format.eprintf "%d %d %d %d %d %a@." (x * pxw) (y * pxh) pxw pxh !check_number Color.print color;
*) )

  let render_scene options scene _canvas =
    check_number := 0;
    (*XXX canvas *)
    let canvas_height = options.canvas_height in
    let canvas_width = options.canvas_width in
    for y = 0 to canvas_height - 1 do
      for x = 0 to canvas_width - 1 do
        let yp = (float y /. float canvas_height *. 2.) -. 1. in
        let xp = (float x /. float canvas_width *. 2.) -. 1. in
        let ray = Camera.get_ray scene.Scene.camera xp yp in
        let color = get_pixel_color options ray scene in
        set_pixel options x y color
      done
    done;
    assert (!check_number = 2321)

  let make
      canvas_width
      canvas_height
      pixel_width
      pixel_height
      render_diffuse
      render_shadows
      render_highlights
      render_reflections
      ray_depth =
    { canvas_width = canvas_width / pixel_width
    ; canvas_height = canvas_height / pixel_height
    ; pixel_width
    ; pixel_height
    ; render_diffuse
    ; render_shadows
    ; render_highlights
    ; render_reflections
    ; ray_depth
    }
end

let render_scene () =
  let camera =
    Camera.make
      (Vector.make 0. 0. (-15.))
      (Vector.make (-0.2) 0. 5.)
      (Vector.make 0. 1. 0.)
  in
  let background = Background.make (Color.make 0.5 0.5 0.5) 0.4 in
  let sphere =
    Shape.make
      (Shape.Sphere (Vector.make (-1.5) 1.5 2., 1.5))
      (Material.solid (Color.make 0. 0.5 0.5) 0.3 0. 2.)
  in
  let sphere1 =
    Shape.make
      (Shape.Sphere (Vector.make 1. 0.25 1., 0.5))
      (Material.solid (Color.make 0.9 0.9 0.9) 0.1 0. 1.5)
  in
  let plane =
    Shape.make
      (Shape.Plane (Vector.normalize (Vector.make 0.1 0.9 (-0.5)), 1.2))
      (Material.chessboard (Color.make 1. 1. 1.) (Color.make 0. 0. 0.) 0.2 0. 1.0 0.7)
  in
  let light = Light.make (Vector.make 5. 10. (-1.)) (Color.make 0.8 0.8 0.8) 10. in
  let light1 = Light.make (Vector.make (-3.) 5. (-15.)) (Color.make 0.8 0.8 0.8) 100. in
  let scene =
    Scene.make camera [| plane; sphere; sphere1 |] [| light; light1 |] background
  in
  let image_width = 100 in
  let image_height = 100 in
  let pixel_size = 5, 5 in
  let render_diffuse = true in
  let render_shadows = true in
  let render_highlights = true in
  let render_reflections = true in
  let ray_depth = 2 in
  let engine =
    Engine.make
      image_width
      image_height
      (fst pixel_size)
      (snd pixel_size)
      render_diffuse
      render_shadows
      render_highlights
      render_reflections
      ray_depth
  in
  Engine.render_scene engine scene None


let _ =
  for _ = 1 to 1024 * 64 do
    render_scene ()
  done
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: boyer.ml 7017 2005-08-12 09:22:04Z xleroy $ *)

(* Manipulations over terms *)

type term =
  | Var of int
  | Prop of head * term list

and head =
  { name : string
  ; mutable props : (term * term) list
  }

let lemmas = ref ([] : head list)

(* Replacement for property lists *)

let get name =
  let rec get_rec = function
    | hd1 :: hdl -> if hd1.name = name then hd1 else get_rec hdl
    | [] ->
        let entry = { name; props = [] } in
        lemmas := entry :: !lemmas;
        entry
  in
  get_rec !lemmas

let add_lemma = function
  | Prop (_, [ (Prop (headl, _) as left); right ]) ->
      headl.props <- (left, right) :: headl.props
  | _ -> assert false

(* Substitutions *)

type subst = Bind of int * term

let get_binding v list =
  let rec get_rec = function
    | [] -> failwith "unbound"
    | Bind (w, t) :: rest -> if v = w then t else get_rec rest
  in
  get_rec list

let apply_subst alist term =
  let rec as_rec = function
    | Var v -> ( try get_binding v alist with Failure _ -> term)
    | Prop (head, argl) -> Prop (head, List.map as_rec argl)
  in
  as_rec term

exception Unify

let rec unify term1 term2 = unify1 term1 term2 []

and unify1 term1 term2 unify_subst =
  match term2 with
  | Var v -> (
      try if get_binding v unify_subst = term1 then unify_subst else raise Unify
      with Failure _ -> Bind (v, term1) :: unify_subst)
  | Prop (head2, argl2) -> (
      match term1 with
      | Var _ -> raise Unify
      | Prop (head1, argl1) ->
          if head1 == head2 then unify1_lst argl1 argl2 unify_subst else raise Unify)

and unify1_lst l1 l2 unify_subst =
  match l1, l2 with
  | [], [] -> unify_subst
  | h1 :: r1, h2 :: r2 -> unify1_lst r1 r2 (unify1 h1 h2 unify_subst)
  | _ -> raise Unify

let rec rewrite = function
  | Var _ as term -> term
  | Prop (head, argl) ->
      rewrite_with_lemmas (Prop (head, List.map rewrite argl)) head.props

and rewrite_with_lemmas term lemmas =
  match lemmas with
  | [] -> term
  | (t1, t2) :: rest -> (
      try rewrite (apply_subst (unify term t1) t2)
      with Unify -> rewrite_with_lemmas term rest)

type cterm =
  | CVar of int
  | CProp of string * cterm list

let rec cterm_to_term = function
  | CVar v -> Var v
  | CProp (p, l) -> Prop (get p, List.map cterm_to_term l)

let add t = add_lemma (cterm_to_term t)

let _ =
  add
    (CProp
       ( "equal"
       , [ CProp ("compile", [ CVar 5 ])
         ; CProp
             ( "reverse"
             , [ CProp ("codegen", [ CProp ("optimize", [ CVar 5 ]); CProp ("nil", []) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("eqp", [ CVar 23; CVar 24 ])
         ; CProp ("equal", [ CProp ("fix", [ CVar 23 ]); CProp ("fix", [ CVar 24 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("gt", [ CVar 23; CVar 24 ]); CProp ("lt", [ CVar 24; CVar 23 ]) ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("le", [ CVar 23; CVar 24 ]); CProp ("ge", [ CVar 24; CVar 23 ]) ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("ge", [ CVar 23; CVar 24 ]); CProp ("le", [ CVar 24; CVar 23 ]) ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("boolean", [ CVar 23 ])
         ; CProp
             ( "or"
             , [ CProp ("equal", [ CVar 23; CProp ("true", []) ])
               ; CProp ("equal", [ CVar 23; CProp ("false", []) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("iff", [ CVar 23; CVar 24 ])
         ; CProp
             ( "and"
             , [ CProp ("implies", [ CVar 23; CVar 24 ])
               ; CProp ("implies", [ CVar 24; CVar 23 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("even1", [ CVar 23 ])
         ; CProp
             ( "if"
             , [ CProp ("zerop", [ CVar 23 ])
               ; CProp ("true", [])
               ; CProp ("odd", [ CProp ("sub1", [ CVar 23 ]) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("countps_", [ CVar 11; CVar 15 ])
         ; CProp ("countps_loop", [ CVar 11; CVar 15; CProp ("zero", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("fact_", [ CVar 8 ])
         ; CProp ("fact_loop", [ CVar 8; CProp ("one", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("reverse_", [ CVar 23 ])
         ; CProp ("reverse_loop", [ CVar 23; CProp ("nil", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("divides", [ CVar 23; CVar 24 ])
         ; CProp ("zerop", [ CProp ("remainder", [ CVar 24; CVar 23 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("assume_true", [ CVar 21; CVar 0 ])
         ; CProp ("cons", [ CProp ("cons", [ CVar 21; CProp ("true", []) ]); CVar 0 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("assume_false", [ CVar 21; CVar 0 ])
         ; CProp ("cons", [ CProp ("cons", [ CVar 21; CProp ("false", []) ]); CVar 0 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("tautology_checker", [ CVar 23 ])
         ; CProp ("tautologyp", [ CProp ("normalize", [ CVar 23 ]); CProp ("nil", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("falsify", [ CVar 23 ])
         ; CProp ("falsify1", [ CProp ("normalize", [ CVar 23 ]); CProp ("nil", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("prime", [ CVar 23 ])
         ; CProp
             ( "and"
             , [ CProp ("not", [ CProp ("zerop", [ CVar 23 ]) ])
               ; CProp
                   ( "not"
                   , [ CProp ("equal", [ CVar 23; CProp ("add1", [ CProp ("zero", []) ]) ])
                     ] )
               ; CProp ("prime1", [ CVar 23; CProp ("sub1", [ CVar 23 ]) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("and", [ CVar 15; CVar 16 ])
         ; CProp
             ( "if"
             , [ CVar 15
               ; CProp ("if", [ CVar 16; CProp ("true", []); CProp ("false", []) ])
               ; CProp ("false", [])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("or", [ CVar 15; CVar 16 ])
         ; CProp
             ( "if"
             , [ CVar 15
               ; CProp ("true", [])
               ; CProp ("if", [ CVar 16; CProp ("true", []); CProp ("false", []) ])
               ; CProp ("false", [])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("not", [ CVar 15 ])
         ; CProp ("if", [ CVar 15; CProp ("false", []); CProp ("true", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("implies", [ CVar 15; CVar 16 ])
         ; CProp
             ( "if"
             , [ CVar 15
               ; CProp ("if", [ CVar 16; CProp ("true", []); CProp ("false", []) ])
               ; CProp ("true", [])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("fix", [ CVar 23 ])
         ; CProp ("if", [ CProp ("numberp", [ CVar 23 ]); CVar 23; CProp ("zero", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("if", [ CProp ("if", [ CVar 0; CVar 1; CVar 2 ]); CVar 3; CVar 4 ])
         ; CProp
             ( "if"
             , [ CVar 0
               ; CProp ("if", [ CVar 1; CVar 3; CVar 4 ])
               ; CProp ("if", [ CVar 2; CVar 3; CVar 4 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("zerop", [ CVar 23 ])
         ; CProp
             ( "or"
             , [ CProp ("equal", [ CVar 23; CProp ("zero", []) ])
               ; CProp ("not", [ CProp ("numberp", [ CVar 23 ]) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("plus", [ CProp ("plus", [ CVar 23; CVar 24 ]); CVar 25 ])
         ; CProp ("plus", [ CVar 23; CProp ("plus", [ CVar 24; CVar 25 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CProp ("plus", [ CVar 0; CVar 1 ]); CProp ("zero", []) ])
         ; CProp ("and", [ CProp ("zerop", [ CVar 0 ]); CProp ("zerop", [ CVar 1 ]) ])
         ] ));
  add
    (CProp ("equal", [ CProp ("difference", [ CVar 23; CVar 23 ]); CProp ("zero", []) ]));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("plus", [ CVar 0; CVar 1 ]); CProp ("plus", [ CVar 0; CVar 2 ]) ]
             )
         ; CProp ("equal", [ CProp ("fix", [ CVar 1 ]); CProp ("fix", [ CVar 2 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ("equal", [ CProp ("zero", []); CProp ("difference", [ CVar 23; CVar 24 ]) ])
         ; CProp ("not", [ CProp ("gt", [ CVar 24; CVar 23 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CVar 23; CProp ("difference", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "and"
             , [ CProp ("numberp", [ CVar 23 ])
               ; CProp
                   ( "or"
                   , [ CProp ("equal", [ CVar 23; CProp ("zero", []) ])
                     ; CProp ("zerop", [ CVar 24 ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "meaning"
             , [ CProp ("plus_tree", [ CProp ("append", [ CVar 23; CVar 24 ]) ]); CVar 0 ]
             )
         ; CProp
             ( "plus"
             , [ CProp ("meaning", [ CProp ("plus_tree", [ CVar 23 ]); CVar 0 ])
               ; CProp ("meaning", [ CProp ("plus_tree", [ CVar 24 ]); CVar 0 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "meaning"
             , [ CProp ("plus_tree", [ CProp ("plus_fringe", [ CVar 23 ]) ]); CVar 0 ] )
         ; CProp ("fix", [ CProp ("meaning", [ CVar 23; CVar 0 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("append", [ CProp ("append", [ CVar 23; CVar 24 ]); CVar 25 ])
         ; CProp ("append", [ CVar 23; CProp ("append", [ CVar 24; CVar 25 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("reverse", [ CProp ("append", [ CVar 0; CVar 1 ]) ])
         ; CProp
             ("append", [ CProp ("reverse", [ CVar 1 ]); CProp ("reverse", [ CVar 0 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("times", [ CVar 23; CProp ("plus", [ CVar 24; CVar 25 ]) ])
         ; CProp
             ( "plus"
             , [ CProp ("times", [ CVar 23; CVar 24 ])
               ; CProp ("times", [ CVar 23; CVar 25 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("times", [ CProp ("times", [ CVar 23; CVar 24 ]); CVar 25 ])
         ; CProp ("times", [ CVar 23; CProp ("times", [ CVar 24; CVar 25 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CProp ("times", [ CVar 23; CVar 24 ]); CProp ("zero", []) ])
         ; CProp ("or", [ CProp ("zerop", [ CVar 23 ]); CProp ("zerop", [ CVar 24 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("exec", [ CProp ("append", [ CVar 23; CVar 24 ]); CVar 15; CVar 4 ])
         ; CProp
             ("exec", [ CVar 24; CProp ("exec", [ CVar 23; CVar 15; CVar 4 ]); CVar 4 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("mc_flatten", [ CVar 23; CVar 24 ])
         ; CProp ("append", [ CProp ("flatten", [ CVar 23 ]); CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("member", [ CVar 23; CProp ("append", [ CVar 0; CVar 1 ]) ])
         ; CProp
             ( "or"
             , [ CProp ("member", [ CVar 23; CVar 0 ])
               ; CProp ("member", [ CVar 23; CVar 1 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("member", [ CVar 23; CProp ("reverse", [ CVar 24 ]) ])
         ; CProp ("member", [ CVar 23; CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("length", [ CProp ("reverse", [ CVar 23 ]) ])
         ; CProp ("length", [ CVar 23 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("member", [ CVar 0; CProp ("intersect", [ CVar 1; CVar 2 ]) ])
         ; CProp
             ( "and"
             , [ CProp ("member", [ CVar 0; CVar 1 ])
               ; CProp ("member", [ CVar 0; CVar 2 ])
               ] )
         ] ));
  add
    (CProp ("equal", [ CProp ("nth", [ CProp ("zero", []); CVar 8 ]); CProp ("zero", []) ]));
  add
    (CProp
       ( "equal"
       , [ CProp ("exp", [ CVar 8; CProp ("plus", [ CVar 9; CVar 10 ]) ])
         ; CProp
             ( "times"
             , [ CProp ("exp", [ CVar 8; CVar 9 ]); CProp ("exp", [ CVar 8; CVar 10 ]) ]
             )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("exp", [ CVar 8; CProp ("times", [ CVar 9; CVar 10 ]) ])
         ; CProp ("exp", [ CProp ("exp", [ CVar 8; CVar 9 ]); CVar 10 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("reverse_loop", [ CVar 23; CVar 24 ])
         ; CProp ("append", [ CProp ("reverse", [ CVar 23 ]); CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("reverse_loop", [ CVar 23; CProp ("nil", []) ])
         ; CProp ("reverse", [ CVar 23 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("count_list", [ CVar 25; CProp ("sort_lp", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "plus"
             , [ CProp ("count_list", [ CVar 25; CVar 23 ])
               ; CProp ("count_list", [ CVar 25; CVar 24 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("append", [ CVar 0; CVar 1 ])
               ; CProp ("append", [ CVar 0; CVar 2 ])
               ] )
         ; CProp ("equal", [ CVar 1; CVar 2 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "plus"
             , [ CProp ("remainder", [ CVar 23; CVar 24 ])
               ; CProp ("times", [ CVar 24; CProp ("quotient", [ CVar 23; CVar 24 ]) ])
               ] )
         ; CProp ("fix", [ CVar 23 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ("power_eval", [ CProp ("big_plus", [ CVar 11; CVar 8; CVar 1 ]); CVar 1 ])
         ; CProp ("plus", [ CProp ("power_eval", [ CVar 11; CVar 1 ]); CVar 8 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "power_eval"
             , [ CProp ("big_plus", [ CVar 23; CVar 24; CVar 8; CVar 1 ]); CVar 1 ] )
         ; CProp
             ( "plus"
             , [ CVar 8
               ; CProp
                   ( "plus"
                   , [ CProp ("power_eval", [ CVar 23; CVar 1 ])
                     ; CProp ("power_eval", [ CVar 24; CVar 1 ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("remainder", [ CVar 24; CProp ("one", []) ]); CProp ("zero", []) ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("lt", [ CProp ("remainder", [ CVar 23; CVar 24 ]); CVar 24 ])
         ; CProp ("not", [ CProp ("zerop", [ CVar 24 ]) ])
         ] ));
  add (CProp ("equal", [ CProp ("remainder", [ CVar 23; CVar 23 ]); CProp ("zero", []) ]));
  add
    (CProp
       ( "equal"
       , [ CProp ("lt", [ CProp ("quotient", [ CVar 8; CVar 9 ]); CVar 8 ])
         ; CProp
             ( "and"
             , [ CProp ("not", [ CProp ("zerop", [ CVar 8 ]) ])
               ; CProp
                   ( "or"
                   , [ CProp ("zerop", [ CVar 9 ])
                     ; CProp ("not", [ CProp ("equal", [ CVar 9; CProp ("one", []) ]) ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("lt", [ CProp ("remainder", [ CVar 23; CVar 24 ]); CVar 23 ])
         ; CProp
             ( "and"
             , [ CProp ("not", [ CProp ("zerop", [ CVar 24 ]) ])
               ; CProp ("not", [ CProp ("zerop", [ CVar 23 ]) ])
               ; CProp ("not", [ CProp ("lt", [ CVar 23; CVar 24 ]) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("power_eval", [ CProp ("power_rep", [ CVar 8; CVar 1 ]); CVar 1 ])
         ; CProp ("fix", [ CVar 8 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "power_eval"
             , [ CProp
                   ( "big_plus"
                   , [ CProp ("power_rep", [ CVar 8; CVar 1 ])
                     ; CProp ("power_rep", [ CVar 9; CVar 1 ])
                     ; CProp ("zero", [])
                     ; CVar 1
                     ] )
               ; CVar 1
               ] )
         ; CProp ("plus", [ CVar 8; CVar 9 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("gcd", [ CVar 23; CVar 24 ]); CProp ("gcd", [ CVar 24; CVar 23 ]) ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("nth", [ CProp ("append", [ CVar 0; CVar 1 ]); CVar 8 ])
         ; CProp
             ( "append"
             , [ CProp ("nth", [ CVar 0; CVar 8 ])
               ; CProp
                   ( "nth"
                   , [ CVar 1
                     ; CProp ("difference", [ CVar 8; CProp ("length", [ CVar 0 ]) ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("difference", [ CProp ("plus", [ CVar 23; CVar 24 ]); CVar 23 ])
         ; CProp ("fix", [ CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("difference", [ CProp ("plus", [ CVar 24; CVar 23 ]); CVar 23 ])
         ; CProp ("fix", [ CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "difference"
             , [ CProp ("plus", [ CVar 23; CVar 24 ])
               ; CProp ("plus", [ CVar 23; CVar 25 ])
               ] )
         ; CProp ("difference", [ CVar 24; CVar 25 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("times", [ CVar 23; CProp ("difference", [ CVar 2; CVar 22 ]) ])
         ; CProp
             ( "difference"
             , [ CProp ("times", [ CVar 2; CVar 23 ])
               ; CProp ("times", [ CVar 22; CVar 23 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("remainder", [ CProp ("times", [ CVar 23; CVar 25 ]); CVar 25 ])
         ; CProp ("zero", [])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "difference"
             , [ CProp ("plus", [ CVar 1; CProp ("plus", [ CVar 0; CVar 2 ]) ]); CVar 0 ]
             )
         ; CProp ("plus", [ CVar 1; CVar 2 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "difference"
             , [ CProp ("add1", [ CProp ("plus", [ CVar 24; CVar 25 ]) ]); CVar 25 ] )
         ; CProp ("add1", [ CVar 24 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "lt"
             , [ CProp ("plus", [ CVar 23; CVar 24 ])
               ; CProp ("plus", [ CVar 23; CVar 25 ])
               ] )
         ; CProp ("lt", [ CVar 24; CVar 25 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "lt"
             , [ CProp ("times", [ CVar 23; CVar 25 ])
               ; CProp ("times", [ CVar 24; CVar 25 ])
               ] )
         ; CProp
             ( "and"
             , [ CProp ("not", [ CProp ("zerop", [ CVar 25 ]) ])
               ; CProp ("lt", [ CVar 23; CVar 24 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("lt", [ CVar 24; CProp ("plus", [ CVar 23; CVar 24 ]) ])
         ; CProp ("not", [ CProp ("zerop", [ CVar 23 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "gcd"
             , [ CProp ("times", [ CVar 23; CVar 25 ])
               ; CProp ("times", [ CVar 24; CVar 25 ])
               ] )
         ; CProp ("times", [ CVar 25; CProp ("gcd", [ CVar 23; CVar 24 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("value", [ CProp ("normalize", [ CVar 23 ]); CVar 0 ])
         ; CProp ("value", [ CVar 23; CVar 0 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("flatten", [ CVar 23 ])
               ; CProp ("cons", [ CVar 24; CProp ("nil", []) ])
               ] )
         ; CProp
             ( "and"
             , [ CProp ("nlistp", [ CVar 23 ]); CProp ("equal", [ CVar 23; CVar 24 ]) ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("listp", [ CProp ("gother", [ CVar 23 ]) ])
         ; CProp ("listp", [ CVar 23 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("samefringe", [ CVar 23; CVar 24 ])
         ; CProp
             ("equal", [ CProp ("flatten", [ CVar 23 ]); CProp ("flatten", [ CVar 24 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("greatest_factor", [ CVar 23; CVar 24 ]); CProp ("zero", []) ] )
         ; CProp
             ( "and"
             , [ CProp
                   ( "or"
                   , [ CProp ("zerop", [ CVar 24 ])
                     ; CProp ("equal", [ CVar 24; CProp ("one", []) ])
                     ] )
               ; CProp ("equal", [ CVar 23; CProp ("zero", []) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("greatest_factor", [ CVar 23; CVar 24 ]); CProp ("one", []) ] )
         ; CProp ("equal", [ CVar 23; CProp ("one", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("numberp", [ CProp ("greatest_factor", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "not"
             , [ CProp
                   ( "and"
                   , [ CProp
                         ( "or"
                         , [ CProp ("zerop", [ CVar 24 ])
                           ; CProp ("equal", [ CVar 24; CProp ("one", []) ])
                           ] )
                     ; CProp ("not", [ CProp ("numberp", [ CVar 23 ]) ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("times_list", [ CProp ("append", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "times"
             , [ CProp ("times_list", [ CVar 23 ]); CProp ("times_list", [ CVar 24 ]) ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("prime_list", [ CProp ("append", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "and"
             , [ CProp ("prime_list", [ CVar 23 ]); CProp ("prime_list", [ CVar 24 ]) ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CVar 25; CProp ("times", [ CVar 22; CVar 25 ]) ])
         ; CProp
             ( "and"
             , [ CProp ("numberp", [ CVar 25 ])
               ; CProp
                   ( "or"
                   , [ CProp ("equal", [ CVar 25; CProp ("zero", []) ])
                     ; CProp ("equal", [ CVar 22; CProp ("one", []) ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("ge", [ CVar 23; CVar 24 ])
         ; CProp ("not", [ CProp ("lt", [ CVar 23; CVar 24 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CVar 23; CProp ("times", [ CVar 23; CVar 24 ]) ])
         ; CProp
             ( "or"
             , [ CProp ("equal", [ CVar 23; CProp ("zero", []) ])
               ; CProp
                   ( "and"
                   , [ CProp ("numberp", [ CVar 23 ])
                     ; CProp ("equal", [ CVar 24; CProp ("one", []) ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("remainder", [ CProp ("times", [ CVar 24; CVar 23 ]); CVar 24 ])
         ; CProp ("zero", [])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CProp ("times", [ CVar 0; CVar 1 ]); CProp ("one", []) ])
         ; CProp
             ( "and"
             , [ CProp ("not", [ CProp ("equal", [ CVar 0; CProp ("zero", []) ]) ])
               ; CProp ("not", [ CProp ("equal", [ CVar 1; CProp ("zero", []) ]) ])
               ; CProp ("numberp", [ CVar 0 ])
               ; CProp ("numberp", [ CVar 1 ])
               ; CProp ("equal", [ CProp ("sub1", [ CVar 0 ]); CProp ("zero", []) ])
               ; CProp ("equal", [ CProp ("sub1", [ CVar 1 ]); CProp ("zero", []) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "lt"
             , [ CProp ("length", [ CProp ("delete", [ CVar 23; CVar 11 ]) ])
               ; CProp ("length", [ CVar 11 ])
               ] )
         ; CProp ("member", [ CVar 23; CVar 11 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("sort2", [ CProp ("delete", [ CVar 23; CVar 11 ]) ])
         ; CProp ("delete", [ CVar 23; CProp ("sort2", [ CVar 11 ]) ])
         ] ));
  add (CProp ("equal", [ CProp ("dsort", [ CVar 23 ]); CProp ("sort2", [ CVar 23 ]) ]));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "length"
             , [ CProp
                   ( "cons"
                   , [ CVar 0
                     ; CProp
                         ( "cons"
                         , [ CVar 1
                           ; CProp
                               ( "cons"
                               , [ CVar 2
                                 ; CProp
                                     ( "cons"
                                     , [ CVar 3
                                       ; CProp
                                           ( "cons"
                                           , [ CVar 4
                                             ; CProp ("cons", [ CVar 5; CVar 6 ])
                                             ] )
                                       ] )
                                 ] )
                           ] )
                     ] )
               ] )
         ; CProp ("plus", [ CProp ("six", []); CProp ("length", [ CVar 6 ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "difference"
             , [ CProp ("add1", [ CProp ("add1", [ CVar 23 ]) ]); CProp ("two", []) ] )
         ; CProp ("fix", [ CVar 23 ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "quotient"
             , [ CProp ("plus", [ CVar 23; CProp ("plus", [ CVar 23; CVar 24 ]) ])
               ; CProp ("two", [])
               ] )
         ; CProp ("plus", [ CVar 23; CProp ("quotient", [ CVar 24; CProp ("two", []) ]) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("sigma", [ CProp ("zero", []); CVar 8 ])
         ; CProp
             ( "quotient"
             , [ CProp ("times", [ CVar 8; CProp ("add1", [ CVar 8 ]) ])
               ; CProp ("two", [])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("plus", [ CVar 23; CProp ("add1", [ CVar 24 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("numberp", [ CVar 24 ])
               ; CProp ("add1", [ CProp ("plus", [ CVar 23; CVar 24 ]) ])
               ; CProp ("add1", [ CVar 23 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "equal"
             , [ CProp ("difference", [ CVar 23; CVar 24 ])
               ; CProp ("difference", [ CVar 25; CVar 24 ])
               ] )
         ; CProp
             ( "if"
             , [ CProp ("lt", [ CVar 23; CVar 24 ])
               ; CProp ("not", [ CProp ("lt", [ CVar 24; CVar 25 ]) ])
               ; CProp
                   ( "if"
                   , [ CProp ("lt", [ CVar 25; CVar 24 ])
                     ; CProp ("not", [ CProp ("lt", [ CVar 24; CVar 23 ]) ])
                     ; CProp
                         ( "equal"
                         , [ CProp ("fix", [ CVar 23 ]); CProp ("fix", [ CVar 25 ]) ] )
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp
             ( "meaning"
             , [ CProp ("plus_tree", [ CProp ("delete", [ CVar 23; CVar 24 ]) ]); CVar 0 ]
             )
         ; CProp
             ( "if"
             , [ CProp ("member", [ CVar 23; CVar 24 ])
               ; CProp
                   ( "difference"
                   , [ CProp ("meaning", [ CProp ("plus_tree", [ CVar 24 ]); CVar 0 ])
                     ; CProp ("meaning", [ CVar 23; CVar 0 ])
                     ] )
               ; CProp ("meaning", [ CProp ("plus_tree", [ CVar 24 ]); CVar 0 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("times", [ CVar 23; CProp ("add1", [ CVar 24 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("numberp", [ CVar 24 ])
               ; CProp
                   ( "plus"
                   , [ CVar 23
                     ; CProp ("times", [ CVar 23; CVar 24 ])
                     ; CProp ("fix", [ CVar 23 ])
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("nth", [ CProp ("nil", []); CVar 8 ])
         ; CProp
             ("if", [ CProp ("zerop", [ CVar 8 ]); CProp ("nil", []); CProp ("zero", []) ])
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("last", [ CProp ("append", [ CVar 0; CVar 1 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("listp", [ CVar 1 ])
               ; CProp ("last", [ CVar 1 ])
               ; CProp
                   ( "if"
                   , [ CProp ("listp", [ CVar 0 ])
                     ; CProp
                         ( "cons"
                         , [ CProp ("car", [ CProp ("last", [ CVar 0 ]) ]); CVar 1 ] )
                     ; CVar 1
                     ] )
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("equal", [ CProp ("lt", [ CVar 23; CVar 24 ]); CVar 25 ])
         ; CProp
             ( "if"
             , [ CProp ("lt", [ CVar 23; CVar 24 ])
               ; CProp ("equal", [ CProp ("true", []); CVar 25 ])
               ; CProp ("equal", [ CProp ("false", []); CVar 25 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("assignment", [ CVar 23; CProp ("append", [ CVar 0; CVar 1 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("assignedp", [ CVar 23; CVar 0 ])
               ; CProp ("assignment", [ CVar 23; CVar 0 ])
               ; CProp ("assignment", [ CVar 23; CVar 1 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("car", [ CProp ("gother", [ CVar 23 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("listp", [ CVar 23 ])
               ; CProp ("car", [ CProp ("flatten", [ CVar 23 ]) ])
               ; CProp ("zero", [])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("flatten", [ CProp ("cdr", [ CProp ("gother", [ CVar 23 ]) ]) ])
         ; CProp
             ( "if"
             , [ CProp ("listp", [ CVar 23 ])
               ; CProp ("cdr", [ CProp ("flatten", [ CVar 23 ]) ])
               ; CProp ("cons", [ CProp ("zero", []); CProp ("nil", []) ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("quotient", [ CProp ("times", [ CVar 24; CVar 23 ]); CVar 24 ])
         ; CProp
             ( "if"
             , [ CProp ("zerop", [ CVar 24 ])
               ; CProp ("zero", [])
               ; CProp ("fix", [ CVar 23 ])
               ] )
         ] ));
  add
    (CProp
       ( "equal"
       , [ CProp ("get", [ CVar 9; CProp ("set", [ CVar 8; CVar 21; CVar 12 ]) ])
         ; CProp
             ( "if"
             , [ CProp ("eqp", [ CVar 9; CVar 8 ])
               ; CVar 21
               ; CProp ("get", [ CVar 9; CVar 12 ])
               ] )
         ] ))

(* Tautology checker *)

let truep x lst =
  match x with
  | Prop (head, _) -> head.name = "true" || List.mem x lst
  | _ -> List.mem x lst

and falsep x lst =
  match x with
  | Prop (head, _) -> head.name = "false" || List.mem x lst
  | _ -> List.mem x lst

let rec tautologyp x true_lst false_lst =
  if truep x true_lst
  then true
  else if falsep x false_lst
  then false
  else
    (*
 print_term x; print_newline();
*)
    match x with
    | Var _ -> false
    | Prop (head, [ test; yes; no ]) ->
        if head.name = "if"
        then
          if truep test true_lst
          then tautologyp yes true_lst false_lst
          else if falsep test false_lst
          then tautologyp no true_lst false_lst
          else
            tautologyp yes (test :: true_lst) false_lst
            && tautologyp no true_lst (test :: false_lst)
        else false
    | _ -> assert false

let tautp x =
  (*  print_term x; print_string"\n"; *)
  let y = rewrite x in
  (*    print_term y; print_string "\n"; *)
  tautologyp y [] []

(* the benchmark *)

let subst =
  [ Bind
      ( 23
      , cterm_to_term
          (CProp
             ( "f"
             , [ CProp
                   ( "plus"
                   , [ CProp ("plus", [ CVar 0; CVar 1 ])
                     ; CProp ("plus", [ CVar 2; CProp ("zero", []) ])
                     ] )
               ] )) )
  ; Bind
      ( 24
      , cterm_to_term
          (CProp
             ( "f"
             , [ CProp
                   ( "times"
                   , [ CProp ("times", [ CVar 0; CVar 1 ])
                     ; CProp ("plus", [ CVar 2; CVar 3 ])
                     ] )
               ] )) )
  ; Bind
      ( 25
      , cterm_to_term
          (CProp
             ( "f"
             , [ CProp
                   ( "reverse"
                   , [ CProp
                         ( "append"
                         , [ CProp ("append", [ CVar 0; CVar 1 ]); CProp ("nil", []) ] )
                     ] )
               ] )) )
  ; Bind
      ( 20
      , cterm_to_term
          (CProp
             ( "equal"
             , [ CProp ("plus", [ CVar 0; CVar 1 ])
               ; CProp ("difference", [ CVar 23; CVar 24 ])
               ] )) )
  ; Bind
      ( 22
      , cterm_to_term
          (CProp
             ( "lt"
             , [ CProp ("remainder", [ CVar 0; CVar 1 ])
               ; CProp ("member", [ CVar 0; CProp ("length", [ CVar 1 ]) ])
               ] )) )
  ]

let term =
  cterm_to_term
    (CProp
       ( "implies"
       , [ CProp
             ( "and"
             , [ CProp ("implies", [ CVar 23; CVar 24 ])
               ; CProp
                   ( "and"
                   , [ CProp ("implies", [ CVar 24; CVar 25 ])
                     ; CProp
                         ( "and"
                         , [ CProp ("implies", [ CVar 25; CVar 20 ])
                           ; CProp ("implies", [ CVar 20; CVar 22 ])
                           ] )
                     ] )
               ] )
         ; CProp ("implies", [ CVar 23; CVar 22 ])
         ] ))

let _ =
  let ok = ref true in
  for _ = 1 to 50 do
    if not (tautp (apply_subst subst term)) then ok := false
  done;
  assert !ok

(*
  if !ok then
    print_string "Proved!\n"
  else
    print_string "Cannot prove!\n";
  exit 0
*)

(*********
  with
      failure s ->
        print_string "Exception failure("; print_string s; print_string ")\n"
    | Unify ->
        print_string "Exception Unify\n"
    | match_failure(file,start,stop) ->
        print_string "Exception match_failure(";
        print_string file;
        print_string ",";
        print_int start;
        print_string ",";
        print_int stop;
        print_string ")\n"
    | _ ->
        print_string "Exception ?\n"

  **********)
type bitstring = bool array
type individual = { chromosome : bitstring; fitness : float }
type fitness_function = bitstring -> float

let chromosome_length = Array.length
let population_size = Array.length

let chromosome { chromosome=x; fitness=_ } = x
let evaluate f x = { chromosome=x; fitness=(f x) }

let fittest x y = if x.fitness > y.fitness then x else y
let pop_fittest pop = Array.fold_left fittest pop.(0) pop
let state = Random.State.make_self_init ()

let random_bitstring n =
  Array.init n (fun _ -> Random.State.bool state)

let random_individual n f =
  evaluate f (random_bitstring n)

(* Onemax is a simple fitness function. *)
let add_bit x b = if b then x +. 1.0 else x
let onemax : fitness_function = Array.fold_left add_bit 0.0

(* Choose fittest out of k uniformly sampled individuals *)
let rec k_tournament k pop =
  let x = pop.(Random.State.int state (population_size pop)) in
  if k <= 1 then x
  else
    let y = k_tournament (k-1) pop in
    fittest x y

let flip_coin p = (Random.State.float state 1.0) < p

let xor a b = if a then not b else b
(* Naive Theta(n) implementation of mutation. *)
let mutate chi x =
  let n = chromosome_length x in
  let p = chi /. (float n) in
  Array.map (fun b -> xor b (flip_coin p)) x

(* Command line arguments *)


let runtime = 100000

let chi = 0.4

let lambda = 100000

let k = 2

let n = 100000

let init n f =
  let a = Array.init n (fun _ -> f ()) in
  a


let evolutionary_algorithm

    runtime       (* Runtime budget  *)
    lambda        (* Population size *)
    k             (* Tournament size *)
    chi           (* Mutation rate   *)
    fitness       (* Fitness function *)
    n             (* Problem instance size n *)

  =

  (* let adam = random_individual n fitness in *)
  let init_pop = init  in
  let pop0 = init_pop lambda (fun _ -> random_individual n fitness) in


  let rec generation time pop =
    let next_pop =
      init_pop lambda
	(fun _ ->
             (k_tournament k pop)
          |> chromosome
          |> (mutate chi)
          |> (evaluate fitness))
    in
    if time * lambda > runtime then
      (
       Printf.printf "fittest: %f\n"
         (pop_fittest next_pop).fitness)
    else
      generation (time+1) next_pop
  in generation 0 pop0

let ea () = evolutionary_algorithm runtime lambda k chi onemax n

let () =
  ea ()
let n_times =  2
let board_size = 1024

(* setup board buffers; rg contains initial state *)
let rg =
  ref (Array.init board_size (fun _ -> Array.init board_size (fun _ -> Random.int 2)))
let rg' =
  ref (Array.init board_size (fun _ -> Array.make board_size 0))

let get g x y =
  try g.(x).(y)
  with _ -> 0
  [@@inline]

let neighbourhood g x y =
  (get g (x-1) (y-1)) +
  (get g (x-1) (y  )) +
  (get g (x-1) (y+1)) +
  (get g (x  ) (y-1)) +
  (get g (x  ) (y+1)) +
  (get g (x+1) (y-1)) +
  (get g (x+1) (y  )) +
  (get g (x+1) (y+1))
  [@@inline]

let next_cell g x y =
  let n = neighbourhood g x y in
  match g.(x).(y), n with
  | 1, 0 | 1, 1                      -> 0  (* lonely *)
  | 1, 4 | 1, 5 | 1, 6 | 1, 7 | 1, 8 -> 0  (* overcrowded *)
  | 1, 2 | 1, 3                      -> 1  (* lives *)
  | 0, 3                             -> 1  (* get birth *)
  | _ (* 0, (0|1|2|4|5|6|7|8) *)     -> 0  (* barren *)


let next () =
  let g = !rg in
  let new_g = !rg' in
  for x = 0 to board_size - 1 do
    for y = 0 to board_size - 1 do
      new_g.(x).(y) <- next_cell g x y
    done
  done;
  rg := new_g;
  rg' := g

let rec repeat n =
  match n with
  | 0 -> ()
  | _ -> next (); repeat (n-1)

let ()=
  (*print !rg;*)
  repeat n_times;
  (*print !rg*)
(*
 * The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/
 *
 * contributed by Troestler Christophe
 * modified by Mauricio Fernandez
 *)


module S = struct
  type t = bytes

  let size = 0x40000

  let equal (s1:bytes) s2 = (s1 = s2)

  let hash (s:bytes) =
    let h = ref 0 in
    for i = 0 to Bytes.length s - 1 do
      let v = Bytes.get s i in
      let c = Char.code v in
      h := !h * 5 + c
    done;
    !h
end

module H = Hashtbl.Make(S)

(* [counts k dna] fills and return the hashtable [count] of
   k-nucleotide keys and count values for a particular reading-frame
   of length [k] of the string [dna].  Keys point to mutable values
   for speed (to avoid looking twice the same key to reinsert the
   value). *)
let count = H.create S.size
let counts k dna =
  H.clear count;
  let key = Bytes.create k in
    for i = 0 to Bytes.length dna - k do
      Bytes.unsafe_blit dna i key 0 k;
      try incr(H.find count key) with Not_found -> H.add count (Bytes.copy key) (ref 1)
    done;
    count

(* [write_frequencies k dna] writes the frequencies for a
   reading-frame of length [k] sorted by descending frequency and then
   ascending k-nucleotide key. *)
let compare_freq ((k1:bytes),(f1:float)) (k2, f2) =
  if f1 > f2 then -1 else if f1 < f2 then 1 else compare k1 k2

let write_frequencies k dna =
  let cnt = counts k dna in
  let tot = float(H.fold (fun _ n t -> !n + t) cnt 0) in
  let frq = H.fold (fun k n l -> (k, 100. *. float !n /. tot) :: l) cnt [] in
  let frq = List.sort compare_freq frq in
  List.iter (fun (k,f) -> Printf.printf "%s %.3f\n" (Bytes.to_string k) f) frq;
  print_string "\n"

let write_count seq_str dna =
  let seq = Bytes.of_string seq_str in
  let cnt = counts (Bytes.length seq) dna in
  Printf.printf "%d\t%s\n" (try !(H.find cnt seq) with Not_found -> 0) (Bytes.to_string seq)

(* Extract DNA sequence "THREE" from knucleotide-input.txt *)
let dna_three =
  let kinput = open_in "input25000000.txt" in
  let is_not_three s = try String.sub s 0 6 <> ">THREE" with _ -> true in
  while is_not_three(input_line kinput) do () done;
  let buf = Buffer.create 1000 in
  (* Skip possible comment *)
  (try while true do
     let line = input_line kinput in
     if line.[0] <> ';' then
       (Buffer.add_string buf (String.uppercase_ascii line); raise Exit)
   done with _ -> ());
  (* Read the DNA sequence *)
  (try while true do
       let line = input_line kinput in
       if line.[0] = '>' then raise End_of_file;
       Buffer.add_string buf (String.uppercase_ascii line)
   done with End_of_file -> ());
  Buffer.to_bytes buf

(* GC param suggestion:
 let () = Gc.set { (Gc.get()) with Gc.minor_heap_size = 1024 * 2048 } *)

let () =
  List.iter (fun i -> write_frequencies i dna_three) [1; 2];
  List.iter (fun k -> write_count k dna_three)
    ["GGT"; "GGTA"; "GGTATT"; "GGTATTTTAATT"; "GGTATTTTAATTTATAGT"]
(* nbody.ml
 *
 * The Great Computer Language Shootout
 * http://shootout.alioth.debian.org/
 *
 * Contributed by Troestler Christophe
 *)


let pi = 3.141592653589793
let solar_mass = 4. *. pi *. pi
let days_per_year = 365.24

type planet = { mutable x : float;  mutable y : float;  mutable z : float;
                mutable vx: float;  mutable vy: float;  mutable vz: float;
                mass : float }

let advance bodies dt =
  let n = Array.length bodies - 1 in
  for i = 0 to Array.length bodies - 1 do
    let b = bodies.(i) in
    for j = i+1 to Array.length bodies - 1 do
      let b' = bodies.(j) in
      let dx = b.x -. b'.x  and dy = b.y -. b'.y  and dz = b.z -. b'.z in
      let dist2 = dx *. dx +. dy *. dy +. dz *. dz in
      let mag = dt /. (dist2 *. sqrt(dist2)) in

      b.vx <- b.vx -. dx *. b'.mass *. mag;
      b.vy <- b.vy -. dy *. b'.mass *. mag;
      b.vz <- b.vz -. dz *. b'.mass *. mag;

      b'.vx <- b'.vx +. dx *. b.mass *. mag;
      b'.vy <- b'.vy +. dy *. b.mass *. mag;
      b'.vz <- b'.vz +. dz *. b.mass *. mag;
    done
  done;
  for i = 0 to n do
    let b = bodies.(i) in
    b.x <- b.x +. dt *. b.vx;
    b.y <- b.y +. dt *. b.vy;
    b.z <- b.z +. dt *. b.vz;
  done


let energy bodies =
  let e = ref 0. in
  for i = 0 to Array.length bodies - 1 do
    let b = bodies.(i) in
    e := !e +. 0.5 *. b.mass *. (b.vx *. b.vx +. b.vy *. b.vy +. b.vz *. b.vz);
    for j = i+1 to Array.length bodies - 1 do
      let b' = bodies.(j) in
      let dx = b.x -. b'.x  and dy = b.y -. b'.y  and dz = b.z -. b'.z in
      let distance = sqrt(dx *. dx +. dy *. dy +. dz *. dz) in
      e := !e -. (b.mass *. b'.mass) /. distance
    done
  done;
  !e


let offset_momentum bodies =
  let px = ref 0. and py = ref 0. and pz = ref 0. in
  for i = 0 to Array.length bodies - 1 do
    px := !px +. bodies.(i).vx *. bodies.(i).mass;
    py := !py +. bodies.(i).vy *. bodies.(i).mass;
    pz := !pz +. bodies.(i).vz *. bodies.(i).mass;
  done;
  bodies.(0).vx <- -. !px /. solar_mass;
  bodies.(0).vy <- -. !py /. solar_mass;
  bodies.(0).vz <- -. !pz /. solar_mass


let jupiter = { x = 4.84143144246472090e+00;
                y = -1.16032004402742839e+00;
                z = -1.03622044471123109e-01;
                vx = 1.66007664274403694e-03 *. days_per_year;
                vy = 7.69901118419740425e-03 *. days_per_year;
                vz = -6.90460016972063023e-05 *. days_per_year;
                mass = 9.54791938424326609e-04 *. solar_mass;    }

let saturn = { x = 8.34336671824457987e+00;
               y = 4.12479856412430479e+00;
               z = -4.03523417114321381e-01;
               vx = -2.76742510726862411e-03 *. days_per_year;
               vy = 4.99852801234917238e-03 *. days_per_year;
               vz = 2.30417297573763929e-05 *. days_per_year;
               mass = 2.85885980666130812e-04 *. solar_mass;     }

let uranus = { x = 1.28943695621391310e+01;
               y = -1.51111514016986312e+01;
               z = -2.23307578892655734e-01;
               vx = 2.96460137564761618e-03 *. days_per_year;
               vy = 2.37847173959480950e-03 *. days_per_year;
               vz = -2.96589568540237556e-05 *. days_per_year;
               mass = 4.36624404335156298e-05 *. solar_mass;     }

let neptune = { x = 1.53796971148509165e+01;
                y = -2.59193146099879641e+01;
                z = 1.79258772950371181e-01;
                vx = 2.68067772490389322e-03 *. days_per_year;
                vy = 1.62824170038242295e-03 *. days_per_year;
                vz = -9.51592254519715870e-05 *. days_per_year;
                mass = 5.15138902046611451e-05 *. solar_mass;   }

let sun = { x = 0.;  y = 0.;  z = 0.;  vx = 0.;  vy = 0.; vz = 0.;
            mass = solar_mass; }

let bodies = [| sun; jupiter; saturn; uranus; neptune |]

let () =
  let n = int_of_string(Sys.argv.(1)) in
  offset_momentum bodies;
  Printf.printf "%.9f\n" (energy bodies);
  for _ = 1 to n do advance bodies 0.01 done;
  Printf.printf "%.9f\n" (energy bodies)
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: nucleic.ml 7017 2005-08-12 09:22:04Z xleroy $ *)

[@@@ocaml.warning "-27"]

(* Use floating-point arithmetic *)

external ( + ) : float -> float -> float = "%addfloat"

external ( - ) : float -> float -> float = "%subfloat"

external ( * ) : float -> float -> float = "%mulfloat"


(* -- POINTS ----------------------------------------------------------------*)

type pt =
  { x : float
  ; y : float
  ; z : float
  }

let pt_sub p1 p2 = { x = p1.x - p2.x; y = p1.y - p2.y; z = p1.z - p2.z }

let pt_dist p1 p2 =
  let dx = p1.x - p2.x and dy = p1.y - p2.y and dz = p1.z - p2.z in
  sqrt ((dx * dx) + (dy * dy) + (dz * dz))

let pt_phi p =
  let b = atan2 p.x p.z in
  atan2 ((cos b * p.z) + (sin b * p.x)) p.y

let pt_theta p = atan2 p.x p.z

(* -- COORDINATE TRANSFORMATIONS --------------------------------------------*)

(*
   The notation for the transformations follows "Paul, R.P. (1981) Robot
   Manipulators.  MIT Press." with the exception that our transformation
   matrices don't have the perspective terms and are the transpose of
   Paul's one.  See also "M\"antyl\"a, M. (1985) An Introduction to
   Solid Modeling, Computer Science Press" Appendix A.

   The components of a transformation matrix are named like this:

    a  b  c
    d  e  f
    g  h  i
   tx ty tz

   The components tx, ty, and tz are the translation vector.
*)

type tfo =
  { a : float
  ; b : float
  ; c : float
  ; d : float
  ; e : float
  ; f : float
  ; g : float
  ; h : float
  ; i : float
  ; tx : float
  ; ty : float
  ; tz : float
  }

let tfo_id =
  { a = 1.0
  ; b = 0.0
  ; c = 0.0
  ; d = 0.0
  ; e = 1.0
  ; f = 0.0
  ; g = 0.0
  ; h = 0.0
  ; i = 1.0
  ; tx = 0.0
  ; ty = 0.0
  ; tz = 0.0
  }

(*
   The function "tfo-apply" multiplies a transformation matrix, tfo, by a
   point vector, p.  The result is a new point.
*)

let tfo_apply t p =
  { x = (p.x * t.a) + (p.y * t.d) + (p.z * t.g) + t.tx
  ; y = (p.x * t.b) + (p.y * t.e) + (p.z * t.h) + t.ty
  ; z = (p.x * t.c) + (p.y * t.f) + (p.z * t.i) + t.tz
  }

(*
   The function "tfo-combine" multiplies two transformation matrices A and B.
   The result is a new matrix which cumulates the transformations described
   by A and B.
*)

let tfo_combine a b =
  (* <HAND_CSE> *)
  (* Hand elimination of common subexpressions.
     Assumes lots of float registers (32 is perfect, 16 still OK).
     Loses on the I386, of course. *)
  let a_a = a.a
  and a_b = a.b
  and a_c = a.c
  and a_d = a.d
  and a_e = a.e
  and a_f = a.f
  and a_g = a.g
  and a_h = a.h
  and a_i = a.i
  and a_tx = a.tx
  and a_ty = a.ty
  and a_tz = a.tz
  and b_a = b.a
  and b_b = b.b
  and b_c = b.c
  and b_d = b.d
  and b_e = b.e
  and b_f = b.f
  and b_g = b.g
  and b_h = b.h
  and b_i = b.i
  and b_tx = b.tx
  and b_ty = b.ty
  and b_tz = b.tz in
  { a = (a_a * b_a) + (a_b * b_d) + (a_c * b_g)
  ; b = (a_a * b_b) + (a_b * b_e) + (a_c * b_h)
  ; c = (a_a * b_c) + (a_b * b_f) + (a_c * b_i)
  ; d = (a_d * b_a) + (a_e * b_d) + (a_f * b_g)
  ; e = (a_d * b_b) + (a_e * b_e) + (a_f * b_h)
  ; f = (a_d * b_c) + (a_e * b_f) + (a_f * b_i)
  ; g = (a_g * b_a) + (a_h * b_d) + (a_i * b_g)
  ; h = (a_g * b_b) + (a_h * b_e) + (a_i * b_h)
  ; i = (a_g * b_c) + (a_h * b_f) + (a_i * b_i)
  ; tx = (a_tx * b_a) + (a_ty * b_d) + (a_tz * b_g) + b_tx
  ; ty = (a_tx * b_b) + (a_ty * b_e) + (a_tz * b_h) + b_ty
  ; tz = (a_tx * b_c) + (a_ty * b_f) + (a_tz * b_i) + b_tz
  }

(* </HAND_CSE> *)
(* Original without CSE *)
(* <NO_CSE> *)
(***
    { a = ((a.a * b.a) + (a.b * b.d) + (a.c * b.g));
      b = ((a.a * b.b) + (a.b * b.e) + (a.c * b.h));
      c = ((a.a * b.c) + (a.b * b.f) + (a.c * b.i));
      d = ((a.d * b.a) + (a.e * b.d) + (a.f * b.g));
      e = ((a.d * b.b) + (a.e * b.e) + (a.f * b.h));
      f = ((a.d * b.c) + (a.e * b.f) + (a.f * b.i));
      g = ((a.g * b.a) + (a.h * b.d) + (a.i * b.g));
      h = ((a.g * b.b) + (a.h * b.e) + (a.i * b.h));
      i = ((a.g * b.c) + (a.h * b.f) + (a.i * b.i));
      tx = ((a.tx * b.a) + (a.ty * b.d) + (a.tz * b.g) + b.tx);
      ty = ((a.tx * b.b) + (a.ty * b.e) + (a.tz * b.h) + b.ty);
      tz = ((a.tx * b.c) + (a.ty * b.f) + (a.tz * b.i) + b.tz)
    }
  ***)
(* </NO_CSE> *)

(*
   The function "tfo-inv-ortho" computes the inverse of a homogeneous
   transformation matrix.
*)

let tfo_inv_ortho t =
  { a = t.a
  ; b = t.d
  ; c = t.g
  ; d = t.b
  ; e = t.e
  ; f = t.h
  ; g = t.c
  ; h = t.f
  ; i = t.i
  ; tx = -.((t.a * t.tx) + (t.b * t.ty) + (t.c * t.tz))
  ; ty = -.((t.d * t.tx) + (t.e * t.ty) + (t.f * t.tz))
  ; tz = -.((t.g * t.tx) + (t.h * t.ty) + (t.i * t.tz))
  }

(*
   Given three points p1, p2, and p3, the function "tfo-align" computes
   a transformation matrix such that point p1 gets mapped to (0,0,0), p2 gets
   mapped to the Y axis and p3 gets mapped to the YZ plane.
*)

let tfo_align p1 p2 p3 =
  let x31 = p3.x - p1.x in
  let y31 = p3.y - p1.y in
  let z31 = p3.z - p1.z in
  let rotpy = pt_sub p2 p1 in
  let phi = pt_phi rotpy in
  let theta = pt_theta rotpy in
  let sinp = sin phi in
  let sint = sin theta in
  let cosp = cos phi in
  let cost = cos theta in
  let sinpsint = sinp * sint in
  let sinpcost = sinp * cost in
  let cospsint = cosp * sint in
  let cospcost = cosp * cost in
  let rotpz =
    { x = (cost * x31) - (sint * z31)
    ; y = (sinpsint * x31) + (cosp * y31) + (sinpcost * z31)
    ; z = (cospsint * x31) + -.(sinp * y31) + (cospcost * z31)
    }
  in
  let rho = pt_theta rotpz in
  let cosr = cos rho in
  let sinr = sin rho in
  let x = -.(p1.x * cost) + (p1.z * sint) in
  let y = -.(p1.x * sinpsint) - (p1.y * cosp) - (p1.z * sinpcost) in
  let z = -.(p1.x * cospsint) + (p1.y * sinp) - (p1.z * cospcost) in
  { a = (cost * cosr) - (cospsint * sinr)
  ; b = sinpsint
  ; c = (cost * sinr) + (cospsint * cosr)
  ; d = sinp * sinr
  ; e = cosp
  ; f = -.(sinp * cosr)
  ; g = -.(sint * cosr) - (cospcost * sinr)
  ; h = sinpcost
  ; i = -.(sint * sinr) + (cospcost * cosr)
  ; tx = (x * cosr) - (z * sinr)
  ; ty = y
  ; tz = (x * sinr) + (z * cosr)
  }

(* -- NUCLEIC ACID CONFORMATIONS DATA BASE ----------------------------------*)

(*
   Numbering of atoms follows the paper:

   IUPAC-IUB Joint Commission on Biochemical Nomenclature (JCBN)
   (1983) Abbreviations and Symbols for the Description of
   Conformations of Polynucleotide Chains.  Eur. J. Biochem 131,
   9-15.
*)

(* Define remaining atoms for each nucleotide type. *)

type nuc_specific =
  | A of pt * pt * pt * pt * pt * pt * pt * pt
  | C of pt * pt * pt * pt * pt * pt
  | G of pt * pt * pt * pt * pt * pt * pt * pt * pt
  | U of pt * pt * pt * pt * pt

(*
   A n6 n7 n9 c8 h2 h61 h62 h8
   C n4 o2 h41 h42 h5 h6
   G n2 n7 n9 c8 o6 h1 h21 h22 h8
   U o2 o4 h3 h5 h6
*)

(* Define part common to all 4 nucleotide types. *)

type nuc =
  | N of
      tfo
      * tfo
      * tfo
      * tfo
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * pt
      * nuc_specific

(*
    dgf_base_tfo  ; defines the standard position for wc and wc_dumas
    p_o3'_275_tfo ; defines the standard position for the connect function
    p_o3'_180_tfo
    p_o3'_60_tfo
    p o1p o2p o5' c5' h5' h5'' c4' h4' o4' c1' h1' c2' h2'' o2' h2' c3'
    h3' o3' n1 n3 c2 c4 c5 c6
*)

let is_A = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , A (_, _, _, _, _, _, _, _) ) -> true
  | _ -> false

let is_C = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , C (_, _, _, _, _, _) ) -> true
  | _ -> false

let is_G = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , G (_, _, _, _, _, _, _, _, _) ) -> true
  | _ -> false

let nuc_C1'
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  c1'

let nuc_C2
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  c2

let nuc_C3'
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  c3'

let nuc_C4
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  c4

let nuc_C4'
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  c4'

let nuc_N1
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  n1

let nuc_O3'
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  o3'

let nuc_P
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  p

let nuc_dgf_base_tfo
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  dgf_base_tfo

let nuc_p_o3'_180_tfo
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  p_o3'_180_tfo

let nuc_p_o3'_275_tfo
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  p_o3'_275_tfo

let nuc_p_o3'_60_tfo
    (N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , _ )) =
  p_o3'_60_tfo

let rA_N9 = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , A (n6, n7, n9, c8, h2, h61, h62, h8) ) -> n9
  | _ -> assert false

let rG_N9 = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , G (n2, n7, n9, c8, o6, h1, h21, h22, h8) ) -> n9
  | _ -> assert false

(* Database of nucleotide conformations: *)

let rA =
  N
    ( { a = -0.0018
      ; b = -0.8207
      ; c = 0.5714
      ; (* dgf_base_tfo *)
        d = 0.2679
      ; e = -0.5509
      ; f = -0.7904
      ; g = 0.9634
      ; h = 0.1517
      ; i = 0.2209
      ; tx = 0.0073
      ; ty = 8.4030
      ; tz = 0.6232
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 5.4550; y = 8.2120; z = -2.8810 }
    , (* C5'  *)
      { x = 5.4546; y = 8.8508; z = -1.9978 }
    , (* H5'  *)
      { x = 5.7588; y = 8.6625; z = -3.8259 }
    , (* H5'' *)
      { x = 6.4970; y = 7.1480; z = -2.5980 }
    , (* C4'  *)
      { x = 7.4896; y = 7.5919; z = -2.5214 }
    , (* H4'  *)
      { x = 6.1630; y = 6.4860; z = -1.3440 }
    , (* O4'  *)
      { x = 6.5400; y = 5.1200; z = -1.4190 }
    , (* C1'  *)
      { x = 7.2763; y = 4.9681; z = -0.6297 }
    , (* H1'  *)
      { x = 7.1940; y = 4.8830; z = -2.7770 }
    , (* C2'  *)
      { x = 6.8667; y = 3.9183; z = -3.1647 }
    , (* H2'' *)
      { x = 8.5860; y = 5.0910; z = -2.6140 }
    , (* O2'  *)
      { x = 8.9510; y = 4.7626; z = -1.7890 }
    , (* H2'  *)
      { x = 6.5720; y = 6.0040; z = -3.6090 }
    , (* C3'  *)
      { x = 5.5636; y = 5.7066; z = -3.8966 }
    , (* H3'  *)
      { x = 7.3801; y = 6.3562; z = -4.7350 }
    , (* O3'  *)
      { x = 4.7150; y = 0.4910; z = -0.1360 }
    , (* N1   *)
      { x = 6.3490; y = 2.1730; z = -0.6020 }
    , (* N3   *)
      { x = 5.9530; y = 0.9650; z = -0.2670 }
    , (* C2   *)
      { x = 5.2900; y = 2.9790; z = -0.8260 }
    , (* C4   *)
      { x = 3.9720; y = 2.6390; z = -0.7330 }
    , (* C5   *)
      { x = 3.6770; y = 1.3160; z = -0.3660 }
    , (* C6 *)
      A
        ( { x = 2.4280; y = 0.8450; z = -0.2360 }
        , (* N6   *)
          { x = 3.1660; y = 3.7290; z = -1.0360 }
        , (* N7   *)
          { x = 5.3170; y = 4.2990; z = -1.1930 }
        , (* N9   *)
          { x = 4.0100; y = 4.6780; z = -1.2990 }
        , (* C8   *)
          { x = 6.6890; y = 0.1903; z = -0.0518 }
        , (* H2   *)
          { x = 1.6470; y = 1.4460; z = -0.4040 }
        , (* H61  *)
          { x = 2.2780; y = -0.1080; z = -0.0280 }
        , (* H62  *)
          { x = 3.4421; y = 5.5744; z = -1.5482 } ) )

(* H8   *)

let rA01 =
  N
    ( { a = -0.0043
      ; b = -0.8175
      ; c = 0.5759
      ; (* dgf_base_tfo *)
        d = 0.2617
      ; e = -0.5567
      ; f = -0.7884
      ; g = 0.9651
      ; h = 0.1473
      ; i = 0.2164
      ; tx = 0.0359
      ; ty = 8.3929
      ; tz = 0.5532
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 5.4352; y = 8.2183; z = -2.7757 }
    , (* C5'  *)
      { x = 5.3830; y = 8.7883; z = -1.8481 }
    , (* H5'  *)
      { x = 5.7729; y = 8.7436; z = -3.6691 }
    , (* H5'' *)
      { x = 6.4830; y = 7.1518; z = -2.5252 }
    , (* C4'  *)
      { x = 7.4749; y = 7.5972; z = -2.4482 }
    , (* H4'  *)
      { x = 6.1626; y = 6.4620; z = -1.2827 }
    , (* O4'  *)
      { x = 6.5431; y = 5.0992; z = -1.3905 }
    , (* C1'  *)
      { x = 7.2871; y = 4.9328; z = -0.6114 }
    , (* H1'  *)
      { x = 7.1852; y = 4.8935; z = -2.7592 }
    , (* C2'  *)
      { x = 6.8573; y = 3.9363; z = -3.1645 }
    , (* H2'' *)
      { x = 8.5780; y = 5.1025; z = -2.6046 }
    , (* O2'  *)
      { x = 8.9516; y = 4.7577; z = -1.7902 }
    , (* H2'  *)
      { x = 6.5522; y = 6.0300; z = -3.5612 }
    , (* C3'  *)
      { x = 5.5420; y = 5.7356; z = -3.8459 }
    , (* H3'  *)
      { x = 7.3487; y = 6.4089; z = -4.6867 }
    , (* O3'  *)
      { x = 4.7442; y = 0.4514; z = -0.1390 }
    , (* N1   *)
      { x = 6.3687; y = 2.1459; z = -0.5926 }
    , (* N3   *)
      { x = 5.9795; y = 0.9335; z = -0.2657 }
    , (* C2   *)
      { x = 5.3052; y = 2.9471; z = -0.8125 }
    , (* C4   *)
      { x = 3.9891; y = 2.5987; z = -0.7230 }
    , (* C5   *)
      { x = 3.7016; y = 1.2717; z = -0.3647 }
    , (* C6 *)
      A
        ( { x = 2.4553; y = 0.7925; z = -0.2390 }
        , (* N6   *)
          { x = 3.1770; y = 3.6859; z = -1.0198 }
        , (* N7   *)
          { x = 5.3247; y = 4.2695; z = -1.1710 }
        , (* N9   *)
          { x = 4.0156; y = 4.6415; z = -1.2759 }
        , (* C8   *)
          { x = 6.7198; y = 0.1618; z = -0.0547 }
        , (* H2   *)
          { x = 1.6709; y = 1.3900; z = -0.4039 }
        , (* H61  *)
          { x = 2.3107; y = -0.1627; z = -0.0373 }
        , (* H62  *)
          { x = 3.4426; y = 5.5361; z = -1.5199 } ) )

(* H8   *)

let rA02 =
  N
    ( { a = 0.5566
      ; b = 0.0449
      ; c = 0.8296
      ; (* dgf_base_tfo *)
        d = 0.5125
      ; e = 0.7673
      ; f = -0.3854
      ; g = -0.6538
      ; h = 0.6397
      ; i = 0.4041
      ; tx = -9.1161
      ; ty = -3.7679
      ; tz = -2.9968
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 4.5778; y = 6.6594; z = -4.0364 }
    , (* C5'  *)
      { x = 4.9220; y = 7.1963; z = -4.9204 }
    , (* H5'  *)
      { x = 3.7996; y = 5.9091; z = -4.1764 }
    , (* H5'' *)
      { x = 5.7873; y = 5.8869; z = -3.5482 }
    , (* C4'  *)
      { x = 6.0405; y = 5.0875; z = -4.2446 }
    , (* H4'  *)
      { x = 6.9135; y = 6.8036; z = -3.4310 }
    , (* O4'  *)
      { x = 7.7293; y = 6.4084; z = -2.3392 }
    , (* C1'  *)
      { x = 8.7078; y = 6.1815; z = -2.7624 }
    , (* H1'  *)
      { x = 7.1305; y = 5.1418; z = -1.7347 }
    , (* C2'  *)
      { x = 7.2040; y = 5.1982; z = -0.6486 }
    , (* H2'' *)
      { x = 7.7417; y = 4.0392; z = -2.3813 }
    , (* O2'  *)
      { x = 8.6785; y = 4.1443; z = -2.5630 }
    , (* H2'  *)
      { x = 5.6666; y = 5.2728; z = -2.1536 }
    , (* C3'  *)
      { x = 5.1747; y = 5.9805; z = -1.4863 }
    , (* H3'  *)
      { x = 4.9997; y = 4.0086; z = -2.1973 }
    , (* O3'  *)
      { x = 10.3245; y = 8.5459; z = 1.5467 }
    , (* N1   *)
      { x = 9.8051; y = 6.9432; z = -0.1497 }
    , (* N3   *)
      { x = 10.5175; y = 7.4328; z = 0.8408 }
    , (* C2   *)
      { x = 8.7523; y = 7.7422; z = -0.4228 }
    , (* C4   *)
      { x = 8.4257; y = 8.9060; z = 0.2099 }
    , (* C5   *)
      { x = 9.2665; y = 9.3242; z = 1.2540 }
    , (* C6 *)
      A
        ( { x = 9.0664; y = 10.4462; z = 1.9610 }
        , (* N6   *)
          { x = 7.2750; y = 9.4537; z = -0.3428 }
        , (* N7   *)
          { x = 7.7962; y = 7.5519; z = -1.3859 }
        , (* N9   *)
          { x = 6.9479; y = 8.6157; z = -1.2771 }
        , (* C8   *)
          { x = 11.4063; y = 6.9047; z = 1.1859 }
        , (* H2   *)
          { x = 8.2845; y = 11.0341; z = 1.7552 }
        , (* H61  *)
          { x = 9.6584; y = 10.6647; z = 2.7198 }
        , (* H62  *)
          { x = 6.0430; y = 8.9853; z = -1.7594 } ) )

(* H8   *)

let rA03 =
  N
    ( { a = -0.5021
      ; b = 0.0731
      ; c = 0.8617
      ; (* dgf_base_tfo *)
        d = -0.8112
      ; e = 0.3054
      ; f = -0.4986
      ; g = -0.2996
      ; h = -0.9494
      ; i = -0.0940
      ; tx = 6.4273
      ; ty = -5.1944
      ; tz = -3.7807
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 4.1214; y = 6.7116; z = -1.9049 }
    , (* C5'  *)
      { x = 3.3465; y = 5.9610; z = -2.0607 }
    , (* H5'  *)
      { x = 4.0789; y = 7.2928; z = -0.9837 }
    , (* H5'' *)
      { x = 5.4170; y = 5.9293; z = -1.8186 }
    , (* C4'  *)
      { x = 5.4506; y = 5.3400; z = -0.9023 }
    , (* H4'  *)
      { x = 5.5067; y = 5.0417; z = -2.9703 }
    , (* O4'  *)
      { x = 6.8650; y = 4.9152; z = -3.3612 }
    , (* C1'  *)
      { x = 7.1090; y = 3.8577; z = -3.2603 }
    , (* H1'  *)
      { x = 7.7152; y = 5.7282; z = -2.3894 }
    , (* C2'  *)
      { x = 8.5029; y = 6.2356; z = -2.9463 }
    , (* H2'' *)
      { x = 8.1036; y = 4.8568; z = -1.3419 }
    , (* O2'  *)
      { x = 8.3270; y = 3.9651; z = -1.6184 }
    , (* H2'  *)
      { x = 6.7003; y = 6.7565; z = -1.8911 }
    , (* C3'  *)
      { x = 6.5898; y = 7.5329; z = -2.6482 }
    , (* H3'  *)
      { x = 7.0505; y = 7.2878; z = -0.6105 }
    , (* O3'  *)
      { x = 9.6740; y = 4.7656; z = -7.6614 }
    , (* N1   *)
      { x = 9.0739; y = 4.3013; z = -5.3941 }
    , (* N3   *)
      { x = 9.8416; y = 4.2192; z = -6.4581 }
    , (* C2   *)
      { x = 7.9885; y = 5.0632; z = -5.6446 }
    , (* C4   *)
      { x = 7.6822; y = 5.6856; z = -6.8194 }
    , (* C5   *)
      { x = 8.5831; y = 5.5215; z = -7.8840 }
    , (* C6 *)
      A
        ( { x = 8.4084; y = 6.0747; z = -9.0933 }
        , (* N6   *)
          { x = 6.4857; y = 6.3816; z = -6.7035 }
        , (* N7   *)
          { x = 6.9740; y = 5.3703; z = -4.7760 }
        , (* N9   *)
          { x = 6.1133; y = 6.1613; z = -5.4808 }
        , (* C8   *)
          { x = 10.7627; y = 3.6375; z = -6.4220 }
        , (* H2   *)
          { x = 7.6031; y = 6.6390; z = -9.2733 }
        , (* H61  *)
          { x = 9.1004; y = 5.9708; z = -9.7893 }
        , (* H62  *)
          { x = 5.1705; y = 6.6830; z = -5.3167 } ) )

(* H8   *)

let rA04 =
  N
    ( { a = -0.5426
      ; b = -0.8175
      ; c = 0.1929
      ; (* dgf_base_tfo *)
        d = 0.8304
      ; e = -0.5567
      ; f = -0.0237
      ; g = 0.1267
      ; h = 0.1473
      ; i = 0.9809
      ; tx = -0.5075
      ; ty = 8.3929
      ; tz = 0.2229
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 5.4352; y = 8.2183; z = -2.7757 }
    , (* C5'  *)
      { x = 5.3830; y = 8.7883; z = -1.8481 }
    , (* H5'  *)
      { x = 5.7729; y = 8.7436; z = -3.6691 }
    , (* H5'' *)
      { x = 6.4830; y = 7.1518; z = -2.5252 }
    , (* C4'  *)
      { x = 7.4749; y = 7.5972; z = -2.4482 }
    , (* H4'  *)
      { x = 6.1626; y = 6.4620; z = -1.2827 }
    , (* O4'  *)
      { x = 6.5431; y = 5.0992; z = -1.3905 }
    , (* C1'  *)
      { x = 7.2871; y = 4.9328; z = -0.6114 }
    , (* H1'  *)
      { x = 7.1852; y = 4.8935; z = -2.7592 }
    , (* C2'  *)
      { x = 6.8573; y = 3.9363; z = -3.1645 }
    , (* H2'' *)
      { x = 8.5780; y = 5.1025; z = -2.6046 }
    , (* O2'  *)
      { x = 8.9516; y = 4.7577; z = -1.7902 }
    , (* H2'  *)
      { x = 6.5522; y = 6.0300; z = -3.5612 }
    , (* C3'  *)
      { x = 5.5420; y = 5.7356; z = -3.8459 }
    , (* H3'  *)
      { x = 7.3487; y = 6.4089; z = -4.6867 }
    , (* O3'  *)
      { x = 3.6343; y = 2.6680; z = 2.0783 }
    , (* N1   *)
      { x = 5.4505; y = 3.9805; z = 1.2446 }
    , (* N3   *)
      { x = 4.7540; y = 3.3816; z = 2.1851 }
    , (* C2   *)
      { x = 4.8805; y = 3.7951; z = 0.0354 }
    , (* C4   *)
      { x = 3.7416; y = 3.0925; z = -0.2305 }
    , (* C5   *)
      { x = 3.0873; y = 2.4980; z = 0.8606 }
    , (* C6 *)
      A
        ( { x = 1.9600; y = 1.7805; z = 0.7462 }
        , (* N6   *)
          { x = 3.4605; y = 3.1184; z = -1.5906 }
        , (* N7   *)
          { x = 5.3247; y = 4.2695; z = -1.1710 }
        , (* N9   *)
          { x = 4.4244; y = 3.8244; z = -2.0953 }
        , (* C8   *)
          { x = 5.0814; y = 3.4352; z = 3.2234 }
        , (* H2   *)
          { x = 1.5423; y = 1.6454; z = -0.1520 }
        , (* H61  *)
          { x = 1.5716; y = 1.3398; z = 1.5392 }
        , (* H62  *)
          { x = 4.2675; y = 3.8876; z = -3.1721 } ) )

(* H8   *)

let rA05 =
  N
    ( { a = -0.5891
      ; b = 0.0449
      ; c = 0.8068
      ; (* dgf_base_tfo *)
        d = 0.5375
      ; e = 0.7673
      ; f = 0.3498
      ; g = -0.6034
      ; h = 0.6397
      ; i = -0.4762
      ; tx = -0.3019
      ; ty = -3.7679
      ; tz = -9.5913
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 4.5778; y = 6.6594; z = -4.0364 }
    , (* C5'  *)
      { x = 4.9220; y = 7.1963; z = -4.9204 }
    , (* H5'  *)
      { x = 3.7996; y = 5.9091; z = -4.1764 }
    , (* H5'' *)
      { x = 5.7873; y = 5.8869; z = -3.5482 }
    , (* C4'  *)
      { x = 6.0405; y = 5.0875; z = -4.2446 }
    , (* H4'  *)
      { x = 6.9135; y = 6.8036; z = -3.4310 }
    , (* O4'  *)
      { x = 7.7293; y = 6.4084; z = -2.3392 }
    , (* C1'  *)
      { x = 8.7078; y = 6.1815; z = -2.7624 }
    , (* H1'  *)
      { x = 7.1305; y = 5.1418; z = -1.7347 }
    , (* C2'  *)
      { x = 7.2040; y = 5.1982; z = -0.6486 }
    , (* H2'' *)
      { x = 7.7417; y = 4.0392; z = -2.3813 }
    , (* O2'  *)
      { x = 8.6785; y = 4.1443; z = -2.5630 }
    , (* H2'  *)
      { x = 5.6666; y = 5.2728; z = -2.1536 }
    , (* C3'  *)
      { x = 5.1747; y = 5.9805; z = -1.4863 }
    , (* H3'  *)
      { x = 4.9997; y = 4.0086; z = -2.1973 }
    , (* O3'  *)
      { x = 10.2594; y = 10.6774; z = -1.0056 }
    , (* N1   *)
      { x = 9.7528; y = 8.7080; z = -2.2631 }
    , (* N3   *)
      { x = 10.4471; y = 9.7876; z = -1.9791 }
    , (* C2   *)
      { x = 8.7271; y = 8.5575; z = -1.3991 }
    , (* C4   *)
      { x = 8.4100; y = 9.3803; z = -0.3580 }
    , (* C5   *)
      { x = 9.2294; y = 10.5030; z = -0.1574 }
    , (* C6 *)
      A
        ( { x = 9.0349; y = 11.3951; z = 0.8250 }
        , (* N6   *)
          { x = 7.2891; y = 8.9068; z = 0.3121 }
        , (* N7   *)
          { x = 7.7962; y = 7.5519; z = -1.3859 }
        , (* N9   *)
          { x = 6.9702; y = 7.8292; z = -0.3353 }
        , (* C8   *)
          { x = 11.3132; y = 10.0537; z = -2.5851 }
        , (* H2   *)
          { x = 8.2741; y = 11.2784; z = 1.4629 }
        , (* H61  *)
          { x = 9.6733; y = 12.1368; z = 0.9529 }
        , (* H62  *)
          { x = 6.0888; y = 7.3990; z = 0.1403 } ) )

(* H8   *)

let rA06 =
  N
    ( { a = -0.9815
      ; b = 0.0731
      ; c = -0.1772
      ; (* dgf_base_tfo *)
        d = 0.1912
      ; e = 0.3054
      ; f = -0.9328
      ; g = -0.0141
      ; h = -0.9494
      ; i = -0.3137
      ; tx = 5.7506
      ; ty = -5.1944
      ; tz = 4.7470
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 4.1214; y = 6.7116; z = -1.9049 }
    , (* C5'  *)
      { x = 3.3465; y = 5.9610; z = -2.0607 }
    , (* H5'  *)
      { x = 4.0789; y = 7.2928; z = -0.9837 }
    , (* H5'' *)
      { x = 5.4170; y = 5.9293; z = -1.8186 }
    , (* C4'  *)
      { x = 5.4506; y = 5.3400; z = -0.9023 }
    , (* H4'  *)
      { x = 5.5067; y = 5.0417; z = -2.9703 }
    , (* O4'  *)
      { x = 6.8650; y = 4.9152; z = -3.3612 }
    , (* C1'  *)
      { x = 7.1090; y = 3.8577; z = -3.2603 }
    , (* H1'  *)
      { x = 7.7152; y = 5.7282; z = -2.3894 }
    , (* C2'  *)
      { x = 8.5029; y = 6.2356; z = -2.9463 }
    , (* H2'' *)
      { x = 8.1036; y = 4.8568; z = -1.3419 }
    , (* O2'  *)
      { x = 8.3270; y = 3.9651; z = -1.6184 }
    , (* H2'  *)
      { x = 6.7003; y = 6.7565; z = -1.8911 }
    , (* C3'  *)
      { x = 6.5898; y = 7.5329; z = -2.6482 }
    , (* H3'  *)
      { x = 7.0505; y = 7.2878; z = -0.6105 }
    , (* O3'  *)
      { x = 6.6624; y = 3.5061; z = -8.2986 }
    , (* N1   *)
      { x = 6.5810; y = 3.2570; z = -5.9221 }
    , (* N3   *)
      { x = 6.5151; y = 2.8263; z = -7.1625 }
    , (* C2   *)
      { x = 6.8364; y = 4.5817; z = -5.8882 }
    , (* C4   *)
      { x = 7.0116; y = 5.4064; z = -6.9609 }
    , (* C5   *)
      { x = 6.9173; y = 4.8260; z = -8.2361 }
    , (* C6 *)
      A
        ( { x = 7.0668; y = 5.5163; z = -9.3763 }
        , (* N6   *)
          { x = 7.2573; y = 6.7070; z = -6.5394 }
        , (* N7   *)
          { x = 6.9740; y = 5.3703; z = -4.7760 }
        , (* N9   *)
          { x = 7.2238; y = 6.6275; z = -5.2453 }
        , (* C8   *)
          { x = 6.3146; y = 1.7741; z = -7.3641 }
        , (* H2   *)
          { x = 7.2568; y = 6.4972; z = -9.3456 }
        , (* H61  *)
          { x = 7.0437; y = 5.0478; z = -10.2446 }
        , (* H62  *)
          { x = 7.4108; y = 7.6227; z = -4.8418 } ) )

(* H8   *)

let rA07 =
  N
    ( { a = 0.2379
      ; b = 0.1310
      ; c = -0.9624
      ; (* dgf_base_tfo *)
        d = -0.5876
      ; e = -0.7696
      ; f = -0.2499
      ; g = -0.7734
      ; h = 0.6249
      ; i = -0.1061
      ; tx = 30.9870
      ; ty = -26.9344
      ; tz = 42.6416
      }
    , { a = 0.7529
      ; b = 0.1548
      ; c = 0.6397
      ; (* P_O3'_275_tfo *)
        d = 0.2952
      ; e = -0.9481
      ; f = -0.1180
      ; g = 0.5882
      ; h = 0.2777
      ; i = -0.7595
      ; tx = -58.8919
      ; ty = -11.3095
      ; tz = 6.0866
      }
    , { a = -0.0239
      ; b = 0.9667
      ; c = -0.2546
      ; (* P_O3'_180_tfo *)
        d = 0.9731
      ; e = -0.0359
      ; f = -0.2275
      ; g = -0.2290
      ; h = -0.2532
      ; i = -0.9399
      ; tx = 3.5401
      ; ty = -29.7913
      ; tz = 52.2796
      }
    , { a = -0.8912
      ; b = -0.4531
      ; c = 0.0242
      ; (* P_O3'_60_tfo *)
        d = -0.1183
      ; e = 0.1805
      ; f = -0.9764
      ; g = 0.4380
      ; h = -0.8730
      ; i = -0.2145
      ; tx = 19.9023
      ; ty = 54.8054
      ; tz = 15.2799
      }
    , { x = 41.8210; y = 8.3880; z = 43.5890 }
    , (* P    *)
      { x = 42.5400; y = 8.0450; z = 44.8330 }
    , (* O1P  *)
      { x = 42.2470; y = 9.6920; z = 42.9910 }
    , (* O2P  *)
      { x = 40.2550; y = 8.2030; z = 43.7340 }
    , (* O5'  *)
      { x = 39.3505; y = 8.4697; z = 42.6565 }
    , (* C5'  *)
      { x = 39.1377; y = 7.5433; z = 42.1230 }
    , (* H5'  *)
      { x = 39.7203; y = 9.3119; z = 42.0717 }
    , (* H5'' *)
      { x = 38.0405; y = 8.9195; z = 43.2869 }
    , (* C4'  *)
      { x = 37.3687; y = 9.3036; z = 42.5193 }
    , (* H4'  *)
      { x = 37.4319; y = 7.8146; z = 43.9387 }
    , (* O4'  *)
      { x = 37.1959; y = 8.1354; z = 45.3237 }
    , (* C1'  *)
      { x = 36.1788; y = 8.5202; z = 45.3970 }
    , (* H1'  *)
      { x = 38.1721; y = 9.2328; z = 45.6504 }
    , (* C2'  *)
      { x = 39.1555; y = 8.7939; z = 45.8188 }
    , (* H2'' *)
      { x = 37.7862; y = 10.0617; z = 46.7013 }
    , (* O2'  *)
      { x = 37.3087; y = 9.6229; z = 47.4092 }
    , (* H2'  *)
      { x = 38.1844; y = 10.0268; z = 44.3367 }
    , (* C3'  *)
      { x = 39.1578; y = 10.5054; z = 44.2289 }
    , (* H3'  *)
      { x = 37.0547; y = 10.9127; z = 44.3441 }
    , (* O3'  *)
      { x = 34.8811; y = 4.2072; z = 47.5784 }
    , (* N1   *)
      { x = 35.1084; y = 6.1336; z = 46.1818 }
    , (* N3   *)
      { x = 34.4108; y = 5.1360; z = 46.7207 }
    , (* C2   *)
      { x = 36.3908; y = 6.1224; z = 46.6053 }
    , (* C4   *)
      { x = 36.9819; y = 5.2334; z = 47.4697 }
    , (* C5   *)
      { x = 36.1786; y = 4.1985; z = 48.0035 }
    , (* C6 *)
      A
        ( { x = 36.6103; y = 3.2749; z = 48.8452 }
        , (* N6   *)
          { x = 38.3236; y = 5.5522; z = 47.6595 }
        , (* N7   *)
          { x = 37.3887; y = 7.0024; z = 46.2437 }
        , (* N9   *)
          { x = 38.5055; y = 6.6096; z = 46.9057 }
        , (* C8   *)
          { x = 33.3553; y = 5.0152; z = 46.4771 }
        , (* H2   *)
          { x = 37.5730; y = 3.2804; z = 49.1507 }
        , (* H61  *)
          { x = 35.9775; y = 2.5638; z = 49.1828 }
        , (* H62  *)
          { x = 39.5461; y = 6.9184; z = 47.0041 } ) )

(* H8   *)

let rA08 =
  N
    ( { a = 0.1084
      ; b = -0.0895
      ; c = -0.9901
      ; (* dgf_base_tfo *)
        d = 0.9789
      ; e = -0.1638
      ; f = 0.1220
      ; g = -0.1731
      ; h = -0.9824
      ; i = 0.0698
      ; tx = -2.9039
      ; ty = 47.2655
      ; tz = 33.0094
      }
    , { a = 0.7529
      ; b = 0.1548
      ; c = 0.6397
      ; (* P_O3'_275_tfo *)
        d = 0.2952
      ; e = -0.9481
      ; f = -0.1180
      ; g = 0.5882
      ; h = 0.2777
      ; i = -0.7595
      ; tx = -58.8919
      ; ty = -11.3095
      ; tz = 6.0866
      }
    , { a = -0.0239
      ; b = 0.9667
      ; c = -0.2546
      ; (* P_O3'_180_tfo *)
        d = 0.9731
      ; e = -0.0359
      ; f = -0.2275
      ; g = -0.2290
      ; h = -0.2532
      ; i = -0.9399
      ; tx = 3.5401
      ; ty = -29.7913
      ; tz = 52.2796
      }
    , { a = -0.8912
      ; b = -0.4531
      ; c = 0.0242
      ; (* P_O3'_60_tfo *)
        d = -0.1183
      ; e = 0.1805
      ; f = -0.9764
      ; g = 0.4380
      ; h = -0.8730
      ; i = -0.2145
      ; tx = 19.9023
      ; ty = 54.8054
      ; tz = 15.2799
      }
    , { x = 41.8210; y = 8.3880; z = 43.5890 }
    , (* P    *)
      { x = 42.5400; y = 8.0450; z = 44.8330 }
    , (* O1P  *)
      { x = 42.2470; y = 9.6920; z = 42.9910 }
    , (* O2P  *)
      { x = 40.2550; y = 8.2030; z = 43.7340 }
    , (* O5'  *)
      { x = 39.4850; y = 8.9301; z = 44.6977 }
    , (* C5'  *)
      { x = 39.0638; y = 9.8199; z = 44.2296 }
    , (* H5'  *)
      { x = 40.0757; y = 9.0713; z = 45.6029 }
    , (* H5'' *)
      { x = 38.3102; y = 8.0414; z = 45.0789 }
    , (* C4'  *)
      { x = 37.7842; y = 8.4637; z = 45.9351 }
    , (* H4'  *)
      { x = 37.4200; y = 7.9453; z = 43.9769 }
    , (* O4'  *)
      { x = 37.2249; y = 6.5609; z = 43.6273 }
    , (* C1'  *)
      { x = 36.3360; y = 6.2168; z = 44.1561 }
    , (* H1'  *)
      { x = 38.4347; y = 5.8414; z = 44.1590 }
    , (* C2'  *)
      { x = 39.2688; y = 5.9974; z = 43.4749 }
    , (* H2'' *)
      { x = 38.2344; y = 4.4907; z = 44.4348 }
    , (* O2'  *)
      { x = 37.6374; y = 4.0386; z = 43.8341 }
    , (* H2'  *)
      { x = 38.6926; y = 6.6079; z = 45.4637 }
    , (* C3'  *)
      { x = 39.7585; y = 6.5640; z = 45.6877 }
    , (* H3'  *)
      { x = 37.8238; y = 6.0705; z = 46.4723 }
    , (* O3'  *)
      { x = 33.9162; y = 6.2598; z = 39.7758 }
    , (* N1   *)
      { x = 34.6709; y = 6.5759; z = 42.0215 }
    , (* N3   *)
      { x = 33.7257; y = 6.5186; z = 41.0858 }
    , (* C2   *)
      { x = 35.8935; y = 6.3324; z = 41.5018 }
    , (* C4   *)
      { x = 36.2105; y = 6.0601; z = 40.1932 }
    , (* C5   *)
      { x = 35.1538; y = 6.0151; z = 39.2537 }
    , (* C6 *)
      A
        ( { x = 35.3088; y = 5.7642; z = 37.9649 }
        , (* N6   *)
          { x = 37.5818; y = 5.8677; z = 40.0507 }
        , (* N7   *)
          { x = 37.0932; y = 6.3197; z = 42.1810 }
        , (* N9   *)
          { x = 38.0509; y = 6.0354; z = 41.2635 }
        , (* C8   *)
          { x = 32.6830; y = 6.6898; z = 41.3532 }
        , (* H2   *)
          { x = 36.2305; y = 5.5855; z = 37.5925 }
        , (* H61  *)
          { x = 34.5056; y = 5.7512; z = 37.3528 }
        , (* H62  *)
          { x = 39.1318; y = 5.8993; z = 41.2285 } ) )

(* H8   *)

let rA09 =
  N
    ( { a = 0.8467
      ; b = 0.4166
      ; c = -0.3311
      ; (* dgf_base_tfo *)
        d = -0.3962
      ; e = 0.9089
      ; f = 0.1303
      ; g = 0.3552
      ; h = 0.0209
      ; i = 0.9346
      ; tx = -42.7319
      ; ty = -26.6223
      ; tz = -29.8163
      }
    , { a = 0.7529
      ; b = 0.1548
      ; c = 0.6397
      ; (* P_O3'_275_tfo *)
        d = 0.2952
      ; e = -0.9481
      ; f = -0.1180
      ; g = 0.5882
      ; h = 0.2777
      ; i = -0.7595
      ; tx = -58.8919
      ; ty = -11.3095
      ; tz = 6.0866
      }
    , { a = -0.0239
      ; b = 0.9667
      ; c = -0.2546
      ; (* P_O3'_180_tfo *)
        d = 0.9731
      ; e = -0.0359
      ; f = -0.2275
      ; g = -0.2290
      ; h = -0.2532
      ; i = -0.9399
      ; tx = 3.5401
      ; ty = -29.7913
      ; tz = 52.2796
      }
    , { a = -0.8912
      ; b = -0.4531
      ; c = 0.0242
      ; (* P_O3'_60_tfo *)
        d = -0.1183
      ; e = 0.1805
      ; f = -0.9764
      ; g = 0.4380
      ; h = -0.8730
      ; i = -0.2145
      ; tx = 19.9023
      ; ty = 54.8054
      ; tz = 15.2799
      }
    , { x = 41.8210; y = 8.3880; z = 43.5890 }
    , (* P    *)
      { x = 42.5400; y = 8.0450; z = 44.8330 }
    , (* O1P  *)
      { x = 42.2470; y = 9.6920; z = 42.9910 }
    , (* O2P  *)
      { x = 40.2550; y = 8.2030; z = 43.7340 }
    , (* O5'  *)
      { x = 39.3505; y = 8.4697; z = 42.6565 }
    , (* C5'  *)
      { x = 39.1377; y = 7.5433; z = 42.1230 }
    , (* H5'  *)
      { x = 39.7203; y = 9.3119; z = 42.0717 }
    , (* H5'' *)
      { x = 38.0405; y = 8.9195; z = 43.2869 }
    , (* C4'  *)
      { x = 37.6479; y = 8.1347; z = 43.9335 }
    , (* H4'  *)
      { x = 38.2691; y = 10.0933; z = 44.0524 }
    , (* O4'  *)
      { x = 37.3999; y = 11.1488; z = 43.5973 }
    , (* C1'  *)
      { x = 36.5061; y = 11.1221; z = 44.2206 }
    , (* H1'  *)
      { x = 37.0364; y = 10.7838; z = 42.1836 }
    , (* C2'  *)
      { x = 37.8636; y = 11.0489; z = 41.5252 }
    , (* H2'' *)
      { x = 35.8275; y = 11.3133; z = 41.7379 }
    , (* O2'  *)
      { x = 35.6214; y = 12.1896; z = 42.0714 }
    , (* H2'  *)
      { x = 36.9316; y = 9.2556; z = 42.2837 }
    , (* C3'  *)
      { x = 37.1778; y = 8.8260; z = 41.3127 }
    , (* H3'  *)
      { x = 35.6285; y = 8.9334; z = 42.7926 }
    , (* O3'  *)
      { x = 38.1482; y = 15.2833; z = 46.4641 }
    , (* N1   *)
      { x = 37.3641; y = 13.0968; z = 45.9007 }
    , (* N3   *)
      { x = 37.5032; y = 14.1288; z = 46.7300 }
    , (* C2   *)
      { x = 37.9570; y = 13.3377; z = 44.7113 }
    , (* C4   *)
      { x = 38.6397; y = 14.4660; z = 44.3267 }
    , (* C5   *)
      { x = 38.7473; y = 15.5229; z = 45.2609 }
    , (* C6 *)
      A
        ( { x = 39.3720; y = 16.6649; z = 45.0297 }
        , (* N6   *)
          { x = 39.1079; y = 14.3351; z = 43.0223 }
        , (* N7   *)
          { x = 38.0132; y = 12.4868; z = 43.6280 }
        , (* N9   *)
          { x = 38.7058; y = 13.1402; z = 42.6620 }
        , (* C8   *)
          { x = 37.0731; y = 14.0857; z = 47.7306 }
        , (* H2   *)
          { x = 39.8113; y = 16.8281; z = 44.1350 }
        , (* H61  *)
          { x = 39.4100; y = 17.3741; z = 45.7478 }
        , (* H62  *)
          { x = 39.0412; y = 12.9660; z = 41.6397 } ) )

(* H8   *)

let rA10 =
  N
    ( { a = 0.7063
      ; b = 0.6317
      ; c = -0.3196
      ; (* dgf_base_tfo *)
        d = -0.0403
      ; e = -0.4149
      ; f = -0.9090
      ; g = -0.7068
      ; h = 0.6549
      ; i = -0.2676
      ; tx = 6.4402
      ; ty = -52.1496
      ; tz = 30.8246
      }
    , { a = 0.7529
      ; b = 0.1548
      ; c = 0.6397
      ; (* P_O3'_275_tfo *)
        d = 0.2952
      ; e = -0.9481
      ; f = -0.1180
      ; g = 0.5882
      ; h = 0.2777
      ; i = -0.7595
      ; tx = -58.8919
      ; ty = -11.3095
      ; tz = 6.0866
      }
    , { a = -0.0239
      ; b = 0.9667
      ; c = -0.2546
      ; (* P_O3'_180_tfo *)
        d = 0.9731
      ; e = -0.0359
      ; f = -0.2275
      ; g = -0.2290
      ; h = -0.2532
      ; i = -0.9399
      ; tx = 3.5401
      ; ty = -29.7913
      ; tz = 52.2796
      }
    , { a = -0.8912
      ; b = -0.4531
      ; c = 0.0242
      ; (* P_O3'_60_tfo *)
        d = -0.1183
      ; e = 0.1805
      ; f = -0.9764
      ; g = 0.4380
      ; h = -0.8730
      ; i = -0.2145
      ; tx = 19.9023
      ; ty = 54.8054
      ; tz = 15.2799
      }
    , { x = 41.8210; y = 8.3880; z = 43.5890 }
    , (* P    *)
      { x = 42.5400; y = 8.0450; z = 44.8330 }
    , (* O1P  *)
      { x = 42.2470; y = 9.6920; z = 42.9910 }
    , (* O2P  *)
      { x = 40.2550; y = 8.2030; z = 43.7340 }
    , (* O5'  *)
      { x = 39.4850; y = 8.9301; z = 44.6977 }
    , (* C5'  *)
      { x = 39.0638; y = 9.8199; z = 44.2296 }
    , (* H5'  *)
      { x = 40.0757; y = 9.0713; z = 45.6029 }
    , (* H5'' *)
      { x = 38.3102; y = 8.0414; z = 45.0789 }
    , (* C4'  *)
      { x = 37.7099; y = 7.8166; z = 44.1973 }
    , (* H4'  *)
      { x = 38.8012; y = 6.8321; z = 45.6380 }
    , (* O4'  *)
      { x = 38.2431; y = 6.6413; z = 46.9529 }
    , (* C1'  *)
      { x = 37.3505; y = 6.0262; z = 46.8385 }
    , (* H1'  *)
      { x = 37.8484; y = 8.0156; z = 47.4214 }
    , (* C2'  *)
      { x = 38.7381; y = 8.5406; z = 47.7690 }
    , (* H2'' *)
      { x = 36.8286; y = 8.0368; z = 48.3701 }
    , (* O2'  *)
      { x = 36.8392; y = 7.3063; z = 48.9929 }
    , (* H2'  *)
      { x = 37.3576; y = 8.6512; z = 46.1132 }
    , (* C3'  *)
      { x = 37.5207; y = 9.7275; z = 46.1671 }
    , (* H3'  *)
      { x = 35.9985; y = 8.2392; z = 45.9032 }
    , (* O3'  *)
      { x = 39.9117; y = 2.2278; z = 48.8527 }
    , (* N1   *)
      { x = 38.6207; y = 3.6941; z = 47.4757 }
    , (* N3   *)
      { x = 38.9872; y = 2.4888; z = 47.9057 }
    , (* C2   *)
      { x = 39.2961; y = 4.6720; z = 48.1174 }
    , (* C4   *)
      { x = 40.2546; y = 4.5307; z = 49.0912 }
    , (* C5   *)
      { x = 40.5932; y = 3.2189; z = 49.4985 }
    , (* C6 *)
      A
        ( { x = 41.4938; y = 2.9317; z = 50.4229 }
        , (* N6   *)
          { x = 40.7195; y = 5.7755; z = 49.5060 }
        , (* N7   *)
          { x = 39.1730; y = 6.0305; z = 47.9170 }
        , (* N9   *)
          { x = 40.0413; y = 6.6250; z = 48.7728 }
        , (* C8   *)
          { x = 38.5257; y = 1.5960; z = 47.4838 }
        , (* H2   *)
          { x = 41.9907; y = 3.6753; z = 50.8921 }
        , (* H61  *)
          { x = 41.6848; y = 1.9687; z = 50.6599 }
        , (* H62  *)
          { x = 40.3571; y = 7.6321; z = 49.0452 } ) )

(* H8   *)

let rAs = [ rA01; rA02; rA03; rA04; rA05; rA06; rA07; rA08; rA09; rA10 ]

let rC =
  N
    ( { a = -0.0359
      ; b = -0.8071
      ; c = 0.5894
      ; (* dgf_base_tfo *)
        d = -0.2669
      ; e = 0.5761
      ; f = 0.7726
      ; g = -0.9631
      ; h = -0.1296
      ; i = -0.2361
      ; tx = 0.1584
      ; ty = 8.3434
      ; tz = 0.5434
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2430; y = -8.2420; z = 2.8260 }
    , (* C5'  *)
      { x = 5.1974; y = -8.8497; z = 1.9223 }
    , (* H5'  *)
      { x = 5.5548; y = -8.7348; z = 3.7469 }
    , (* H5'' *)
      { x = 6.3140; y = -7.2060; z = 2.5510 }
    , (* C4'  *)
      { x = 7.2954; y = -7.6762; z = 2.4898 }
    , (* H4'  *)
      { x = 6.0140; y = -6.5420; z = 1.2890 }
    , (* O4'  *)
      { x = 6.4190; y = -5.1840; z = 1.3620 }
    , (* C1'  *)
      { x = 7.1608; y = -5.0495; z = 0.5747 }
    , (* H1'  *)
      { x = 7.0760; y = -4.9560; z = 2.7270 }
    , (* C2'  *)
      { x = 6.7770; y = -3.9803; z = 3.1099 }
    , (* H2'' *)
      { x = 8.4500; y = -5.1930; z = 2.5810 }
    , (* O2'  *)
      { x = 8.8309; y = -4.8755; z = 1.7590 }
    , (* H2'  *)
      { x = 6.4060; y = -6.0590; z = 3.5580 }
    , (* C3'  *)
      { x = 5.4021; y = -5.7313; z = 3.8281 }
    , (* H3'  *)
      { x = 7.1570; y = -6.4240; z = 4.7070 }
    , (* O3'  *)
      { x = 5.2170; y = -4.3260; z = 1.1690 }
    , (* N1   *)
      { x = 4.2960; y = -2.2560; z = 0.6290 }
    , (* N3   *)
      { x = 5.4330; y = -3.0200; z = 0.7990 }
    , (* C2   *)
      { x = 2.9930; y = -2.6780; z = 0.7940 }
    , (* C4   *)
      { x = 2.8670; y = -4.0630; z = 1.1830 }
    , (* C5   *)
      { x = 3.9570; y = -4.8300; z = 1.3550 }
    , (* C6 *)
      C
        ( { x = 2.0187; y = -1.8047; z = 0.5874 }
        , (* N4   *)
          { x = 6.5470; y = -2.5560; z = 0.6290 }
        , (* O2   *)
          { x = 1.0684; y = -2.1236; z = 0.7109 }
        , (* H41  *)
          { x = 2.2344; y = -0.8560; z = 0.3162 }
        , (* H42  *)
          { x = 1.8797; y = -4.4972; z = 1.3404 }
        , (* H5   *)
          { x = 3.8479; y = -5.8742; z = 1.6480 } ) )

(* H6   *)

let rC01 =
  N
    ( { a = -0.0137
      ; b = -0.8012
      ; c = 0.5983
      ; (* dgf_base_tfo *)
        d = -0.2523
      ; e = 0.5817
      ; f = 0.7733
      ; g = -0.9675
      ; h = -0.1404
      ; i = -0.2101
      ; tx = 0.2031
      ; ty = 8.3874
      ; tz = 0.4228
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2416; y = -8.2422; z = 2.8181 }
    , (* C5'  *)
      { x = 5.2050; y = -8.8128; z = 1.8901 }
    , (* H5'  *)
      { x = 5.5368; y = -8.7738; z = 3.7227 }
    , (* H5'' *)
      { x = 6.3232; y = -7.2037; z = 2.6002 }
    , (* C4'  *)
      { x = 7.3048; y = -7.6757; z = 2.5577 }
    , (* H4'  *)
      { x = 6.0635; y = -6.5092; z = 1.3456 }
    , (* O4'  *)
      { x = 6.4697; y = -5.1547; z = 1.4629 }
    , (* C1'  *)
      { x = 7.2354; y = -5.0043; z = 0.7018 }
    , (* H1'  *)
      { x = 7.0856; y = -4.9610; z = 2.8521 }
    , (* C2'  *)
      { x = 6.7777; y = -3.9935; z = 3.2487 }
    , (* H2'' *)
      { x = 8.4627; y = -5.1992; z = 2.7423 }
    , (* O2'  *)
      { x = 8.8693; y = -4.8638; z = 1.9399 }
    , (* H2'  *)
      { x = 6.3877; y = -6.0809; z = 3.6362 }
    , (* C3'  *)
      { x = 5.3770; y = -5.7562; z = 3.8834 }
    , (* H3'  *)
      { x = 7.1024; y = -6.4754; z = 4.7985 }
    , (* O3'  *)
      { x = 5.2764; y = -4.2883; z = 1.2538 }
    , (* N1   *)
      { x = 4.3777; y = -2.2062; z = 0.7229 }
    , (* N3   *)
      { x = 5.5069; y = -2.9779; z = 0.9088 }
    , (* C2   *)
      { x = 3.0693; y = -2.6246; z = 0.8500 }
    , (* C4   *)
      { x = 2.9279; y = -4.0146; z = 1.2149 }
    , (* C5   *)
      { x = 4.0101; y = -4.7892; z = 1.4017 }
    , (* C6 *)
      C
        ( { x = 2.1040; y = -1.7437; z = 0.6331 }
        , (* N4   *)
          { x = 6.6267; y = -2.5166; z = 0.7728 }
        , (* O2   *)
          { x = 1.1496; y = -2.0600; z = 0.7287 }
        , (* H41  *)
          { x = 2.3303; y = -0.7921; z = 0.3815 }
        , (* H42  *)
          { x = 1.9353; y = -4.4465; z = 1.3419 }
        , (* H5   *)
          { x = 3.8895; y = -5.8371; z = 1.6762 } ) )

(* H6   *)

let rC02 =
  N
    ( { a = 0.5141
      ; b = 0.0246
      ; c = 0.8574
      ; (* dgf_base_tfo *)
        d = -0.5547
      ; e = -0.7529
      ; f = 0.3542
      ; g = 0.6542
      ; h = -0.6577
      ; i = -0.3734
      ; tx = -9.1111
      ; ty = -3.4598
      ; tz = -3.2939
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 4.3825; y = -6.6585; z = 4.0489 }
    , (* C5'  *)
      { x = 4.6841; y = -7.2019; z = 4.9443 }
    , (* H5'  *)
      { x = 3.6189; y = -5.8889; z = 4.1625 }
    , (* H5'' *)
      { x = 5.6255; y = -5.9175; z = 3.5998 }
    , (* C4'  *)
      { x = 5.8732; y = -5.1228; z = 4.3034 }
    , (* H4'  *)
      { x = 6.7337; y = -6.8605; z = 3.5222 }
    , (* O4'  *)
      { x = 7.5932; y = -6.4923; z = 2.4548 }
    , (* C1'  *)
      { x = 8.5661; y = -6.2983; z = 2.9064 }
    , (* H1'  *)
      { x = 7.0527; y = -5.2012; z = 1.8322 }
    , (* C2'  *)
      { x = 7.1627; y = -5.2525; z = 0.7490 }
    , (* H2'' *)
      { x = 7.6666; y = -4.1249; z = 2.4880 }
    , (* O2'  *)
      { x = 8.5944; y = -4.2543; z = 2.6981 }
    , (* H2'  *)
      { x = 5.5661; y = -5.3029; z = 2.2009 }
    , (* C3'  *)
      { x = 5.0841; y = -6.0018; z = 1.5172 }
    , (* H3'  *)
      { x = 4.9062; y = -4.0452; z = 2.2042 }
    , (* O3'  *)
      { x = 7.6298; y = -7.6136; z = 1.4752 }
    , (* N1   *)
      { x = 8.6945; y = -8.7046; z = -0.2857 }
    , (* N3   *)
      { x = 8.6943; y = -7.6514; z = 0.6066 }
    , (* C2   *)
      { x = 7.7426; y = -9.6987; z = -0.3801 }
    , (* C4   *)
      { x = 6.6642; y = -9.5742; z = 0.5722 }
    , (* C5   *)
      { x = 6.6391; y = -8.5592; z = 1.4526 }
    , (* C6 *)
      C
        ( { x = 7.9033; y = -10.6371; z = -1.3010 }
        , (* N4   *)
          { x = 9.5840; y = -6.8186; z = 0.6136 }
        , (* O2   *)
          { x = 7.2009; y = -11.3604; z = -1.3619 }
        , (* H41  *)
          { x = 8.7058; y = -10.6168; z = -1.9140 }
        , (* H42  *)
          { x = 5.8585; y = -10.3083; z = 0.5822 }
        , (* H5   *)
          { x = 5.8197; y = -8.4773; z = 2.1667 } ) )

(* H6   *)

let rC03 =
  N
    ( { a = -0.4993
      ; b = 0.0476
      ; c = 0.8651
      ; (* dgf_base_tfo *)
        d = 0.8078
      ; e = -0.3353
      ; f = 0.4847
      ; g = 0.3132
      ; h = 0.9409
      ; i = 0.1290
      ; tx = 6.2989
      ; ty = -5.2303
      ; tz = -3.8577
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 3.9938; y = -6.7042; z = 1.9023 }
    , (* C5'  *)
      { x = 3.2332; y = -5.9343; z = 2.0319 }
    , (* H5'  *)
      { x = 3.9666; y = -7.2863; z = 0.9812 }
    , (* H5'' *)
      { x = 5.3098; y = -5.9546; z = 1.8564 }
    , (* C4'  *)
      { x = 5.3863; y = -5.3702; z = 0.9395 }
    , (* H4'  *)
      { x = 5.3851; y = -5.0642; z = 3.0076 }
    , (* O4'  *)
      { x = 6.7315; y = -4.9724; z = 3.4462 }
    , (* C1'  *)
      { x = 7.0033; y = -3.9202; z = 3.3619 }
    , (* H1'  *)
      { x = 7.5997; y = -5.8018; z = 2.4948 }
    , (* C2'  *)
      { x = 8.3627; y = -6.3254; z = 3.0707 }
    , (* H2'' *)
      { x = 8.0410; y = -4.9501; z = 1.4724 }
    , (* O2'  *)
      { x = 8.2781; y = -4.0644; z = 1.7570 }
    , (* H2'  *)
      { x = 6.5701; y = -6.8129; z = 1.9714 }
    , (* C3'  *)
      { x = 6.4186; y = -7.5809; z = 2.7299 }
    , (* H3'  *)
      { x = 6.9357; y = -7.3841; z = 0.7235 }
    , (* O3'  *)
      { x = 6.8024; y = -5.4718; z = 4.8475 }
    , (* N1   *)
      { x = 7.9218; y = -5.5700; z = 6.8877 }
    , (* N3   *)
      { x = 7.8908; y = -5.0886; z = 5.5944 }
    , (* C2   *)
      { x = 6.9789; y = -6.3827; z = 7.4823 }
    , (* C4   *)
      { x = 5.8742; y = -6.7319; z = 6.6202 }
    , (* C5   *)
      { x = 5.8182; y = -6.2769; z = 5.3570 }
    , (* C6 *)
      C
        ( { x = 7.1702; y = -6.7511; z = 8.7402 }
        , (* N4   *)
          { x = 8.7747; y = -4.3728; z = 5.1568 }
        , (* O2   *)
          { x = 6.4741; y = -7.3461; z = 9.1662 }
        , (* H41  *)
          { x = 7.9889; y = -6.4396; z = 9.2429 }
        , (* H42  *)
          { x = 5.0736; y = -7.3713; z = 6.9922 }
        , (* H5   *)
          { x = 4.9784; y = -6.5473; z = 4.7170 } ) )

(* H6   *)

let rC04 =
  N
    ( { a = -0.5669
      ; b = -0.8012
      ; c = 0.1918
      ; (* dgf_base_tfo *)
        d = -0.8129
      ; e = 0.5817
      ; f = 0.0273
      ; g = -0.1334
      ; h = -0.1404
      ; i = -0.9811
      ; tx = -0.3279
      ; ty = 8.3874
      ; tz = 0.3355
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2416; y = -8.2422; z = 2.8181 }
    , (* C5'  *)
      { x = 5.2050; y = -8.8128; z = 1.8901 }
    , (* H5'  *)
      { x = 5.5368; y = -8.7738; z = 3.7227 }
    , (* H5'' *)
      { x = 6.3232; y = -7.2037; z = 2.6002 }
    , (* C4'  *)
      { x = 7.3048; y = -7.6757; z = 2.5577 }
    , (* H4'  *)
      { x = 6.0635; y = -6.5092; z = 1.3456 }
    , (* O4'  *)
      { x = 6.4697; y = -5.1547; z = 1.4629 }
    , (* C1'  *)
      { x = 7.2354; y = -5.0043; z = 0.7018 }
    , (* H1'  *)
      { x = 7.0856; y = -4.9610; z = 2.8521 }
    , (* C2'  *)
      { x = 6.7777; y = -3.9935; z = 3.2487 }
    , (* H2'' *)
      { x = 8.4627; y = -5.1992; z = 2.7423 }
    , (* O2'  *)
      { x = 8.8693; y = -4.8638; z = 1.9399 }
    , (* H2'  *)
      { x = 6.3877; y = -6.0809; z = 3.6362 }
    , (* C3'  *)
      { x = 5.3770; y = -5.7562; z = 3.8834 }
    , (* H3'  *)
      { x = 7.1024; y = -6.4754; z = 4.7985 }
    , (* O3'  *)
      { x = 5.2764; y = -4.2883; z = 1.2538 }
    , (* N1   *)
      { x = 3.8961; y = -3.0896; z = -0.1893 }
    , (* N3   *)
      { x = 5.0095; y = -3.8907; z = -0.0346 }
    , (* C2   *)
      { x = 3.0480; y = -2.6632; z = 0.8116 }
    , (* C4   *)
      { x = 3.4093; y = -3.1310; z = 2.1292 }
    , (* C5   *)
      { x = 4.4878; y = -3.9124; z = 2.3088 }
    , (* C6 *)
      C
        ( { x = 2.0216; y = -1.8941; z = 0.4804 }
        , (* N4   *)
          { x = 5.7005; y = -4.2164; z = -0.9842 }
        , (* O2   *)
          { x = 1.4067; y = -1.5873; z = 1.2205 }
        , (* H41  *)
          { x = 1.8721; y = -1.6319; z = -0.4835 }
        , (* H42  *)
          { x = 2.8048; y = -2.8507; z = 2.9918 }
        , (* H5   *)
          { x = 4.7491; y = -4.2593; z = 3.3085 } ) )

(* H6   *)

let rC05 =
  N
    ( { a = -0.6298
      ; b = 0.0246
      ; c = 0.7763
      ; (* dgf_base_tfo *)
        d = -0.5226
      ; e = -0.7529
      ; f = -0.4001
      ; g = 0.5746
      ; h = -0.6577
      ; i = 0.4870
      ; tx = -0.0208
      ; ty = -3.4598
      ; tz = -9.6882
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 4.3825; y = -6.6585; z = 4.0489 }
    , (* C5'  *)
      { x = 4.6841; y = -7.2019; z = 4.9443 }
    , (* H5'  *)
      { x = 3.6189; y = -5.8889; z = 4.1625 }
    , (* H5'' *)
      { x = 5.6255; y = -5.9175; z = 3.5998 }
    , (* C4'  *)
      { x = 5.8732; y = -5.1228; z = 4.3034 }
    , (* H4'  *)
      { x = 6.7337; y = -6.8605; z = 3.5222 }
    , (* O4'  *)
      { x = 7.5932; y = -6.4923; z = 2.4548 }
    , (* C1'  *)
      { x = 8.5661; y = -6.2983; z = 2.9064 }
    , (* H1'  *)
      { x = 7.0527; y = -5.2012; z = 1.8322 }
    , (* C2'  *)
      { x = 7.1627; y = -5.2525; z = 0.7490 }
    , (* H2'' *)
      { x = 7.6666; y = -4.1249; z = 2.4880 }
    , (* O2'  *)
      { x = 8.5944; y = -4.2543; z = 2.6981 }
    , (* H2'  *)
      { x = 5.5661; y = -5.3029; z = 2.2009 }
    , (* C3'  *)
      { x = 5.0841; y = -6.0018; z = 1.5172 }
    , (* H3'  *)
      { x = 4.9062; y = -4.0452; z = 2.2042 }
    , (* O3'  *)
      { x = 7.6298; y = -7.6136; z = 1.4752 }
    , (* N1   *)
      { x = 8.5977; y = -9.5977; z = 0.7329 }
    , (* N3   *)
      { x = 8.5951; y = -8.5745; z = 1.6594 }
    , (* C2   *)
      { x = 7.7372; y = -9.7371; z = -0.3364 }
    , (* C4   *)
      { x = 6.7596; y = -8.6801; z = -0.4476 }
    , (* C5   *)
      { x = 6.7338; y = -7.6721; z = 0.4408 }
    , (* C6 *)
      C
        ( { x = 7.8849; y = -10.7881; z = -1.1289 }
        , (* N4   *)
          { x = 9.3993; y = -8.5377; z = 2.5743 }
        , (* O2   *)
          { x = 7.2499; y = -10.8809; z = -1.9088 }
        , (* H41  *)
          { x = 8.6122; y = -11.4649; z = -0.9468 }
        , (* H42  *)
          { x = 6.0317; y = -8.6941; z = -1.2588 }
        , (* H5   *)
          { x = 5.9901; y = -6.8809; z = 0.3459 } ) )

(* H6   *)

let rC06 =
  N
    ( { a = -0.9837
      ; b = 0.0476
      ; c = -0.1733
      ; (* dgf_base_tfo *)
        d = -0.1792
      ; e = -0.3353
      ; f = 0.9249
      ; g = -0.0141
      ; h = 0.9409
      ; i = 0.3384
      ; tx = 5.7793
      ; ty = -5.2303
      ; tz = 4.5997
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 3.9938; y = -6.7042; z = 1.9023 }
    , (* C5'  *)
      { x = 3.2332; y = -5.9343; z = 2.0319 }
    , (* H5'  *)
      { x = 3.9666; y = -7.2863; z = 0.9812 }
    , (* H5'' *)
      { x = 5.3098; y = -5.9546; z = 1.8564 }
    , (* C4'  *)
      { x = 5.3863; y = -5.3702; z = 0.9395 }
    , (* H4'  *)
      { x = 5.3851; y = -5.0642; z = 3.0076 }
    , (* O4'  *)
      { x = 6.7315; y = -4.9724; z = 3.4462 }
    , (* C1'  *)
      { x = 7.0033; y = -3.9202; z = 3.3619 }
    , (* H1'  *)
      { x = 7.5997; y = -5.8018; z = 2.4948 }
    , (* C2'  *)
      { x = 8.3627; y = -6.3254; z = 3.0707 }
    , (* H2'' *)
      { x = 8.0410; y = -4.9501; z = 1.4724 }
    , (* O2'  *)
      { x = 8.2781; y = -4.0644; z = 1.7570 }
    , (* H2'  *)
      { x = 6.5701; y = -6.8129; z = 1.9714 }
    , (* C3'  *)
      { x = 6.4186; y = -7.5809; z = 2.7299 }
    , (* H3'  *)
      { x = 6.9357; y = -7.3841; z = 0.7235 }
    , (* O3'  *)
      { x = 6.8024; y = -5.4718; z = 4.8475 }
    , (* N1   *)
      { x = 6.6920; y = -5.0495; z = 7.1354 }
    , (* N3   *)
      { x = 6.6201; y = -4.5500; z = 5.8506 }
    , (* C2   *)
      { x = 6.9254; y = -6.3614; z = 7.4926 }
    , (* C4   *)
      { x = 7.1046; y = -7.2543; z = 6.3718 }
    , (* C5   *)
      { x = 7.0391; y = -6.7951; z = 5.1106 }
    , (* C6 *)
      C
        ( { x = 6.9614; y = -6.6648; z = 8.7815 }
        , (* N4   *)
          { x = 6.4083; y = -3.3696; z = 5.6340 }
        , (* O2   *)
          { x = 7.1329; y = -7.6280; z = 9.0324 }
        , (* H41  *)
          { x = 6.8204; y = -5.9469; z = 9.4777 }
        , (* H42  *)
          { x = 7.2954; y = -8.3135; z = 6.5440 }
        , (* H5   *)
          { x = 7.1753; y = -7.4798; z = 4.2735 } ) )

(* H6   *)

let rC07 =
  N
    ( { a = 0.0033
      ; b = 0.2720
      ; c = -0.9623
      ; (* dgf_base_tfo *)
        d = 0.3013
      ; e = -0.9179
      ; f = -0.2584
      ; g = -0.9535
      ; h = -0.2891
      ; i = -0.0850
      ; tx = 43.0403
      ; ty = 13.7233
      ; tz = 34.5710
      }
    , { a = 0.9187
      ; b = 0.2887
      ; c = 0.2694
      ; (* P_O3'_275_tfo *)
        d = 0.0302
      ; e = -0.7316
      ; f = 0.6811
      ; g = 0.3938
      ; h = -0.6176
      ; i = -0.6808
      ; tx = -48.4330
      ; ty = 26.3254
      ; tz = 13.6383
      }
    , { a = -0.1504
      ; b = 0.7744
      ; c = -0.6145
      ; (* P_O3'_180_tfo *)
        d = 0.7581
      ; e = 0.4893
      ; f = 0.4311
      ; g = 0.6345
      ; h = -0.4010
      ; i = -0.6607
      ; tx = -31.9784
      ; ty = -13.4285
      ; tz = 44.9650
      }
    , { a = -0.6236
      ; b = -0.7810
      ; c = -0.0337
      ; (* P_O3'_60_tfo *)
        d = -0.6890
      ; e = 0.5694
      ; f = -0.4484
      ; g = 0.3694
      ; h = -0.2564
      ; i = -0.8932
      ; tx = 12.1105
      ; ty = 30.8774
      ; tz = 46.0946
      }
    , { x = 33.3400; y = 11.0980; z = 46.1750 }
    , (* P    *)
      { x = 34.5130; y = 10.2320; z = 46.4660 }
    , (* O1P  *)
      { x = 33.4130; y = 12.3960; z = 46.9340 }
    , (* O2P  *)
      { x = 31.9810; y = 10.3390; z = 46.4820 }
    , (* O5'  *)
      { x = 30.8152; y = 11.1619; z = 46.2003 }
    , (* C5'  *)
      { x = 30.4519; y = 10.9454; z = 45.1957 }
    , (* H5'  *)
      { x = 31.0379; y = 12.2016; z = 46.4400 }
    , (* H5'' *)
      { x = 29.7081; y = 10.7448; z = 47.1428 }
    , (* C4'  *)
      { x = 28.8710; y = 11.4416; z = 47.0982 }
    , (* H4'  *)
      { x = 29.2550; y = 9.4394; z = 46.8162 }
    , (* O4'  *)
      { x = 29.3907; y = 8.5625; z = 47.9460 }
    , (* C1'  *)
      { x = 28.4416; y = 8.5669; z = 48.4819 }
    , (* H1'  *)
      { x = 30.4468; y = 9.2031; z = 48.7952 }
    , (* C2'  *)
      { x = 31.4222; y = 8.9651; z = 48.3709 }
    , (* H2'' *)
      { x = 30.3701; y = 8.9157; z = 50.1624 }
    , (* O2'  *)
      { x = 30.0652; y = 8.0304; z = 50.3740 }
    , (* H2'  *)
      { x = 30.1622; y = 10.6879; z = 48.6120 }
    , (* C3'  *)
      { x = 31.0952; y = 11.2399; z = 48.7254 }
    , (* H3'  *)
      { x = 29.1076; y = 11.1535; z = 49.4702 }
    , (* O3'  *)
      { x = 29.7883; y = 7.2209; z = 47.5235 }
    , (* N1   *)
      { x = 29.1825; y = 5.0438; z = 46.8275 }
    , (* N3   *)
      { x = 28.8008; y = 6.2912; z = 47.2263 }
    , (* C2   *)
      { x = 30.4888; y = 4.6890; z = 46.7186 }
    , (* C4   *)
      { x = 31.5034; y = 5.6405; z = 47.0249 }
    , (* C5   *)
      { x = 31.1091; y = 6.8691; z = 47.4156 }
    , (* C6 *)
      C
        ( { x = 30.8109; y = 3.4584; z = 46.3336 }
        , (* N4   *)
          { x = 27.6171; y = 6.5989; z = 47.3189 }
        , (* O2   *)
          { x = 31.7923; y = 3.2301; z = 46.2638 }
        , (* H41  *)
          { x = 30.0880; y = 2.7857; z = 46.1215 }
        , (* H42  *)
          { x = 32.5542; y = 5.3634; z = 46.9395 }
        , (* H5   *)
          { x = 31.8523; y = 7.6279; z = 47.6603 } ) )

(* H6   *)

let rC08 =
  N
    ( { a = 0.0797
      ; b = -0.6026
      ; c = -0.7941
      ; (* dgf_base_tfo *)
        d = 0.7939
      ; e = 0.5201
      ; f = -0.3150
      ; g = 0.6028
      ; h = -0.6054
      ; i = 0.5198
      ; tx = -36.8341
      ; ty = 41.5293
      ; tz = 1.6628
      }
    , { a = 0.9187
      ; b = 0.2887
      ; c = 0.2694
      ; (* P_O3'_275_tfo *)
        d = 0.0302
      ; e = -0.7316
      ; f = 0.6811
      ; g = 0.3938
      ; h = -0.6176
      ; i = -0.6808
      ; tx = -48.4330
      ; ty = 26.3254
      ; tz = 13.6383
      }
    , { a = -0.1504
      ; b = 0.7744
      ; c = -0.6145
      ; (* P_O3'_180_tfo *)
        d = 0.7581
      ; e = 0.4893
      ; f = 0.4311
      ; g = 0.6345
      ; h = -0.4010
      ; i = -0.6607
      ; tx = -31.9784
      ; ty = -13.4285
      ; tz = 44.9650
      }
    , { a = -0.6236
      ; b = -0.7810
      ; c = -0.0337
      ; (* P_O3'_60_tfo *)
        d = -0.6890
      ; e = 0.5694
      ; f = -0.4484
      ; g = 0.3694
      ; h = -0.2564
      ; i = -0.8932
      ; tx = 12.1105
      ; ty = 30.8774
      ; tz = 46.0946
      }
    , { x = 33.3400; y = 11.0980; z = 46.1750 }
    , (* P    *)
      { x = 34.5130; y = 10.2320; z = 46.4660 }
    , (* O1P  *)
      { x = 33.4130; y = 12.3960; z = 46.9340 }
    , (* O2P  *)
      { x = 31.9810; y = 10.3390; z = 46.4820 }
    , (* O5'  *)
      { x = 31.8779; y = 9.9369; z = 47.8760 }
    , (* C5'  *)
      { x = 31.3239; y = 10.6931; z = 48.4322 }
    , (* H5'  *)
      { x = 32.8647; y = 9.6624; z = 48.2489 }
    , (* H5'' *)
      { x = 31.0429; y = 8.6773; z = 47.9401 }
    , (* C4'  *)
      { x = 31.0779; y = 8.2331; z = 48.9349 }
    , (* H4'  *)
      { x = 29.6956; y = 8.9669; z = 47.5983 }
    , (* O4'  *)
      { x = 29.2784; y = 8.1700; z = 46.4782 }
    , (* C1'  *)
      { x = 28.8006; y = 7.2731; z = 46.8722 }
    , (* H1'  *)
      { x = 30.5544; y = 7.7940; z = 45.7875 }
    , (* C2'  *)
      { x = 30.8837; y = 8.6410; z = 45.1856 }
    , (* H2'' *)
      { x = 30.5100; y = 6.6007; z = 45.0582 }
    , (* O2'  *)
      { x = 29.6694; y = 6.4168; z = 44.6326 }
    , (* H2'  *)
      { x = 31.5146; y = 7.5954; z = 46.9527 }
    , (* C3'  *)
      { x = 32.5255; y = 7.8261; z = 46.6166 }
    , (* H3'  *)
      { x = 31.3876; y = 6.2951; z = 47.5516 }
    , (* O3'  *)
      { x = 28.3976; y = 8.9302; z = 45.5933 }
    , (* N1   *)
      { x = 26.2155; y = 9.6135; z = 44.9910 }
    , (* N3   *)
      { x = 27.0281; y = 8.8961; z = 45.8192 }
    , (* C2   *)
      { x = 26.7044; y = 10.3489; z = 43.9595 }
    , (* C4   *)
      { x = 28.1088; y = 10.3837; z = 43.7247 }
    , (* C5   *)
      { x = 28.8978; y = 9.6708; z = 44.5535 }
    , (* C6 *)
      C
        ( { x = 25.8715; y = 11.0249; z = 43.1749 }
        , (* N4   *)
          { x = 26.5733; y = 8.2371; z = 46.7484 }
        , (* O2   *)
          { x = 26.2707; y = 11.5609; z = 42.4177 }
        , (* H41  *)
          { x = 24.8760; y = 10.9939; z = 43.3427 }
        , (* H42  *)
          { x = 28.5089; y = 10.9722; z = 42.8990 }
        , (* H5   *)
          { x = 29.9782; y = 9.6687; z = 44.4097 } ) )

(* H6   *)

let rC09 =
  N
    ( { a = 0.8727
      ; b = 0.4760
      ; c = -0.1091
      ; (* dgf_base_tfo *)
        d = -0.4188
      ; e = 0.6148
      ; f = -0.6682
      ; g = -0.2510
      ; h = 0.6289
      ; i = 0.7359
      ; tx = -8.1687
      ; ty = -52.0761
      ; tz = -25.0726
      }
    , { a = 0.9187
      ; b = 0.2887
      ; c = 0.2694
      ; (* P_O3'_275_tfo *)
        d = 0.0302
      ; e = -0.7316
      ; f = 0.6811
      ; g = 0.3938
      ; h = -0.6176
      ; i = -0.6808
      ; tx = -48.4330
      ; ty = 26.3254
      ; tz = 13.6383
      }
    , { a = -0.1504
      ; b = 0.7744
      ; c = -0.6145
      ; (* P_O3'_180_tfo *)
        d = 0.7581
      ; e = 0.4893
      ; f = 0.4311
      ; g = 0.6345
      ; h = -0.4010
      ; i = -0.6607
      ; tx = -31.9784
      ; ty = -13.4285
      ; tz = 44.9650
      }
    , { a = -0.6236
      ; b = -0.7810
      ; c = -0.0337
      ; (* P_O3'_60_tfo *)
        d = -0.6890
      ; e = 0.5694
      ; f = -0.4484
      ; g = 0.3694
      ; h = -0.2564
      ; i = -0.8932
      ; tx = 12.1105
      ; ty = 30.8774
      ; tz = 46.0946
      }
    , { x = 33.3400; y = 11.0980; z = 46.1750 }
    , (* P    *)
      { x = 34.5130; y = 10.2320; z = 46.4660 }
    , (* O1P  *)
      { x = 33.4130; y = 12.3960; z = 46.9340 }
    , (* O2P  *)
      { x = 31.9810; y = 10.3390; z = 46.4820 }
    , (* O5'  *)
      { x = 30.8152; y = 11.1619; z = 46.2003 }
    , (* C5'  *)
      { x = 30.4519; y = 10.9454; z = 45.1957 }
    , (* H5'  *)
      { x = 31.0379; y = 12.2016; z = 46.4400 }
    , (* H5'' *)
      { x = 29.7081; y = 10.7448; z = 47.1428 }
    , (* C4'  *)
      { x = 29.4506; y = 9.6945; z = 47.0059 }
    , (* H4'  *)
      { x = 30.1045; y = 10.9634; z = 48.4885 }
    , (* O4'  *)
      { x = 29.1794; y = 11.8418; z = 49.1490 }
    , (* C1'  *)
      { x = 28.4388; y = 11.2210; z = 49.6533 }
    , (* H1'  *)
      { x = 28.5211; y = 12.6008; z = 48.0367 }
    , (* C2'  *)
      { x = 29.1947; y = 13.3949; z = 47.7147 }
    , (* H2'' *)
      { x = 27.2316; y = 13.0683; z = 48.3134 }
    , (* O2'  *)
      { x = 27.0851; y = 13.3391; z = 49.2227 }
    , (* H2'  *)
      { x = 28.4131; y = 11.5507; z = 46.9391 }
    , (* C3'  *)
      { x = 28.4451; y = 12.0512; z = 45.9713 }
    , (* H3'  *)
      { x = 27.2707; y = 10.6955; z = 47.1097 }
    , (* O3'  *)
      { x = 29.8751; y = 12.7405; z = 50.0682 }
    , (* N1   *)
      { x = 30.7172; y = 13.1841; z = 52.2328 }
    , (* N3   *)
      { x = 30.0617; y = 12.3404; z = 51.3847 }
    , (* C2   *)
      { x = 31.1834; y = 14.3941; z = 51.8297 }
    , (* C4   *)
      { x = 30.9913; y = 14.8074; z = 50.4803 }
    , (* C5   *)
      { x = 30.3434; y = 13.9610; z = 49.6548 }
    , (* C6 *)
      C
        ( { x = 31.8090; y = 15.1847; z = 52.6957 }
        , (* N4   *)
          { x = 29.6470; y = 11.2494; z = 51.7616 }
        , (* O2   *)
          { x = 32.1422; y = 16.0774; z = 52.3606 }
        , (* H41  *)
          { x = 31.9392; y = 14.8893; z = 53.6527 }
        , (* H42  *)
          { x = 31.3632; y = 15.7771; z = 50.1491 }
        , (* H5   *)
          { x = 30.1742; y = 14.2374; z = 48.6141 } ) )

(* H6   *)

let rC10 =
  N
    ( { a = 0.1549
      ; b = 0.8710
      ; c = -0.4663
      ; (* dgf_base_tfo *)
        d = 0.6768
      ; e = -0.4374
      ; f = -0.5921
      ; g = -0.7197
      ; h = -0.2239
      ; i = -0.6572
      ; tx = 25.2447
      ; ty = -14.1920
      ; tz = 50.3201
      }
    , { a = 0.9187
      ; b = 0.2887
      ; c = 0.2694
      ; (* P_O3'_275_tfo *)
        d = 0.0302
      ; e = -0.7316
      ; f = 0.6811
      ; g = 0.3938
      ; h = -0.6176
      ; i = -0.6808
      ; tx = -48.4330
      ; ty = 26.3254
      ; tz = 13.6383
      }
    , { a = -0.1504
      ; b = 0.7744
      ; c = -0.6145
      ; (* P_O3'_180_tfo *)
        d = 0.7581
      ; e = 0.4893
      ; f = 0.4311
      ; g = 0.6345
      ; h = -0.4010
      ; i = -0.6607
      ; tx = -31.9784
      ; ty = -13.4285
      ; tz = 44.9650
      }
    , { a = -0.6236
      ; b = -0.7810
      ; c = -0.0337
      ; (* P_O3'_60_tfo *)
        d = -0.6890
      ; e = 0.5694
      ; f = -0.4484
      ; g = 0.3694
      ; h = -0.2564
      ; i = -0.8932
      ; tx = 12.1105
      ; ty = 30.8774
      ; tz = 46.0946
      }
    , { x = 33.3400; y = 11.0980; z = 46.1750 }
    , (* P    *)
      { x = 34.5130; y = 10.2320; z = 46.4660 }
    , (* O1P  *)
      { x = 33.4130; y = 12.3960; z = 46.9340 }
    , (* O2P  *)
      { x = 31.9810; y = 10.3390; z = 46.4820 }
    , (* O5'  *)
      { x = 31.8779; y = 9.9369; z = 47.8760 }
    , (* C5'  *)
      { x = 31.3239; y = 10.6931; z = 48.4322 }
    , (* H5'  *)
      { x = 32.8647; y = 9.6624; z = 48.2489 }
    , (* H5'' *)
      { x = 31.0429; y = 8.6773; z = 47.9401 }
    , (* C4'  *)
      { x = 30.0440; y = 8.8473; z = 47.5383 }
    , (* H4'  *)
      { x = 31.6749; y = 7.6351; z = 47.2119 }
    , (* O4'  *)
      { x = 31.9159; y = 6.5022; z = 48.0616 }
    , (* C1'  *)
      { x = 31.0691; y = 5.8243; z = 47.9544 }
    , (* H1'  *)
      { x = 31.9300; y = 7.0685; z = 49.4493 }
    , (* C2'  *)
      { x = 32.9024; y = 7.5288; z = 49.6245 }
    , (* H2'' *)
      { x = 31.5672; y = 6.1750; z = 50.4632 }
    , (* O2'  *)
      { x = 31.8416; y = 5.2663; z = 50.3200 }
    , (* H2'  *)
      { x = 30.8618; y = 8.1514; z = 49.3749 }
    , (* C3'  *)
      { x = 31.1122; y = 8.9396; z = 50.0850 }
    , (* H3'  *)
      { x = 29.5351; y = 7.6245; z = 49.5409 }
    , (* O3'  *)
      { x = 33.1890; y = 5.8629; z = 47.7343 }
    , (* N1   *)
      { x = 34.4004; y = 4.2636; z = 46.4828 }
    , (* N3   *)
      { x = 33.2062; y = 4.8497; z = 46.7851 }
    , (* C2   *)
      { x = 35.5600; y = 4.6374; z = 47.0822 }
    , (* C4   *)
      { x = 35.5444; y = 5.6751; z = 48.0577 }
    , (* C5   *)
      { x = 34.3565; y = 6.2450; z = 48.3432 }
    , (* C6 *)
      C
        ( { x = 36.6977; y = 4.0305; z = 46.7598 }
        , (* N4   *)
          { x = 32.1661; y = 4.5034; z = 46.2348 }
        , (* O2   *)
          { x = 37.5405; y = 4.3347; z = 47.2259 }
        , (* H41  *)
          { x = 36.7033; y = 3.2923; z = 46.0706 }
        , (* H42  *)
          { x = 36.4713; y = 5.9811; z = 48.5428 }
        , (* H5   *)
          { x = 34.2986; y = 7.0426; z = 49.0839 } ) )

(* H6   *)

let rCs = [ rC01; rC02; rC03; rC04; rC05; rC06; rC07; rC08; rC09; rC10 ]

let rG =
  N
    ( { a = -0.0018
      ; b = -0.8207
      ; c = 0.5714
      ; (* dgf_base_tfo *)
        d = 0.2679
      ; e = -0.5509
      ; f = -0.7904
      ; g = 0.9634
      ; h = 0.1517
      ; i = 0.2209
      ; tx = 0.0073
      ; ty = 8.4030
      ; tz = 0.6232
      }
    , { a = -0.8143
      ; b = -0.5091
      ; c = -0.2788
      ; (* P_O3'_275_tfo *)
        d = -0.0433
      ; e = -0.4257
      ; f = 0.9038
      ; g = -0.5788
      ; h = 0.7480
      ; i = 0.3246
      ; tx = 1.5227
      ; ty = 6.9114
      ; tz = -7.0765
      }
    , { a = 0.3822
      ; b = -0.7477
      ; c = 0.5430
      ; (* P_O3'_180_tfo *)
        d = 0.4552
      ; e = 0.6637
      ; f = 0.5935
      ; g = -0.8042
      ; h = 0.0203
      ; i = 0.5941
      ; tx = -6.9472
      ; ty = -4.1186
      ; tz = -5.9108
      }
    , { a = 0.5640
      ; b = 0.8007
      ; c = -0.2022
      ; (* P_O3'_60_tfo *)
        d = -0.8247
      ; e = 0.5587
      ; f = -0.0878
      ; g = 0.0426
      ; h = 0.2162
      ; i = 0.9754
      ; tx = 6.2694
      ; ty = -7.0540
      ; tz = 3.3316
      }
    , { x = 2.8930; y = 8.5380; z = -3.3280 }
    , (* P    *)
      { x = 1.6980; y = 7.6960; z = -3.5570 }
    , (* O1P  *)
      { x = 3.2260; y = 9.5010; z = -4.4020 }
    , (* O2P  *)
      { x = 4.1590; y = 7.6040; z = -3.0340 }
    , (* O5'  *)
      { x = 5.4550; y = 8.2120; z = -2.8810 }
    , (* C5'  *)
      { x = 5.4546; y = 8.8508; z = -1.9978 }
    , (* H5'  *)
      { x = 5.7588; y = 8.6625; z = -3.8259 }
    , (* H5'' *)
      { x = 6.4970; y = 7.1480; z = -2.5980 }
    , (* C4'  *)
      { x = 7.4896; y = 7.5919; z = -2.5214 }
    , (* H4'  *)
      { x = 6.1630; y = 6.4860; z = -1.3440 }
    , (* O4'  *)
      { x = 6.5400; y = 5.1200; z = -1.4190 }
    , (* C1'  *)
      { x = 7.2763; y = 4.9681; z = -0.6297 }
    , (* H1'  *)
      { x = 7.1940; y = 4.8830; z = -2.7770 }
    , (* C2'  *)
      { x = 6.8667; y = 3.9183; z = -3.1647 }
    , (* H2'' *)
      { x = 8.5860; y = 5.0910; z = -2.6140 }
    , (* O2'  *)
      { x = 8.9510; y = 4.7626; z = -1.7890 }
    , (* H2'  *)
      { x = 6.5720; y = 6.0040; z = -3.6090 }
    , (* C3'  *)
      { x = 5.5636; y = 5.7066; z = -3.8966 }
    , (* H3'  *)
      { x = 7.3801; y = 6.3562; z = -4.7350 }
    , (* O3'  *)
      { x = 4.7150; y = 0.4910; z = -0.1360 }
    , (* N1   *)
      { x = 6.3490; y = 2.1730; z = -0.6020 }
    , (* N3   *)
      { x = 5.9530; y = 0.9650; z = -0.2670 }
    , (* C2   *)
      { x = 5.2900; y = 2.9790; z = -0.8260 }
    , (* C4   *)
      { x = 3.9720; y = 2.6390; z = -0.7330 }
    , (* C5   *)
      { x = 3.6770; y = 1.3160; z = -0.3660 }
    , (* C6 *)
      G
        ( { x = 6.8426; y = 0.0056; z = -0.0019 }
        , (* N2   *)
          { x = 3.1660; y = 3.7290; z = -1.0360 }
        , (* N7   *)
          { x = 5.3170; y = 4.2990; z = -1.1930 }
        , (* N9   *)
          { x = 4.0100; y = 4.6780; z = -1.2990 }
        , (* C8   *)
          { x = 2.4280; y = 0.8450; z = -0.2360 }
        , (* O6   *)
          { x = 4.6151; y = -0.4677; z = 0.1305 }
        , (* H1   *)
          { x = 6.6463; y = -0.9463; z = 0.2729 }
        , (* H21  *)
          { x = 7.8170; y = 0.2642; z = -0.0640 }
        , (* H22  *)
          { x = 3.4421; y = 5.5744; z = -1.5482 } ) )

(* H8   *)


(* H8   *)

(* H8   *)

let rU =
  N
    ( { a = -0.0359
      ; b = -0.8071
      ; c = 0.5894
      ; (* dgf_base_tfo *)
        d = -0.2669
      ; e = 0.5761
      ; f = 0.7726
      ; g = -0.9631
      ; h = -0.1296
      ; i = -0.2361
      ; tx = 0.1584
      ; ty = 8.3434
      ; tz = 0.5434
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2430; y = -8.2420; z = 2.8260 }
    , (* C5'  *)
      { x = 5.1974; y = -8.8497; z = 1.9223 }
    , (* H5'  *)
      { x = 5.5548; y = -8.7348; z = 3.7469 }
    , (* H5'' *)
      { x = 6.3140; y = -7.2060; z = 2.5510 }
    , (* C4'  *)
      { x = 7.2954; y = -7.6762; z = 2.4898 }
    , (* H4'  *)
      { x = 6.0140; y = -6.5420; z = 1.2890 }
    , (* O4'  *)
      { x = 6.4190; y = -5.1840; z = 1.3620 }
    , (* C1'  *)
      { x = 7.1608; y = -5.0495; z = 0.5747 }
    , (* H1'  *)
      { x = 7.0760; y = -4.9560; z = 2.7270 }
    , (* C2'  *)
      { x = 6.7770; y = -3.9803; z = 3.1099 }
    , (* H2'' *)
      { x = 8.4500; y = -5.1930; z = 2.5810 }
    , (* O2'  *)
      { x = 8.8309; y = -4.8755; z = 1.7590 }
    , (* H2'  *)
      { x = 6.4060; y = -6.0590; z = 3.5580 }
    , (* C3'  *)
      { x = 5.4021; y = -5.7313; z = 3.8281 }
    , (* H3'  *)
      { x = 7.1570; y = -6.4240; z = 4.7070 }
    , (* O3'  *)
      { x = 5.2170; y = -4.3260; z = 1.1690 }
    , (* N1   *)
      { x = 4.2960; y = -2.2560; z = 0.6290 }
    , (* N3   *)
      { x = 5.4330; y = -3.0200; z = 0.7990 }
    , (* C2   *)
      { x = 2.9930; y = -2.6780; z = 0.7940 }
    , (* C4   *)
      { x = 2.8670; y = -4.0630; z = 1.1830 }
    , (* C5   *)
      { x = 3.9570; y = -4.8300; z = 1.3550 }
    , (* C6 *)
      U
        ( { x = 6.5470; y = -2.5560; z = 0.6290 }
        , (* O2   *)
          { x = 2.0540; y = -1.9000; z = 0.6130 }
        , (* O4   *)
          { x = 4.4300; y = -1.3020; z = 0.3600 }
        , (* H3   *)
          { x = 1.9590; y = -4.4570; z = 1.3250 }
        , (* H5   *)
          { x = 3.8460; y = -5.7860; z = 1.6240 } ) )

(* H6   *)

let rU01 =
  N
    ( { a = -0.0137
      ; b = -0.8012
      ; c = 0.5983
      ; (* dgf_base_tfo *)
        d = -0.2523
      ; e = 0.5817
      ; f = 0.7733
      ; g = -0.9675
      ; h = -0.1404
      ; i = -0.2101
      ; tx = 0.2031
      ; ty = 8.3874
      ; tz = 0.4228
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2416; y = -8.2422; z = 2.8181 }
    , (* C5'  *)
      { x = 5.2050; y = -8.8128; z = 1.8901 }
    , (* H5'  *)
      { x = 5.5368; y = -8.7738; z = 3.7227 }
    , (* H5'' *)
      { x = 6.3232; y = -7.2037; z = 2.6002 }
    , (* C4'  *)
      { x = 7.3048; y = -7.6757; z = 2.5577 }
    , (* H4'  *)
      { x = 6.0635; y = -6.5092; z = 1.3456 }
    , (* O4'  *)
      { x = 6.4697; y = -5.1547; z = 1.4629 }
    , (* C1'  *)
      { x = 7.2354; y = -5.0043; z = 0.7018 }
    , (* H1'  *)
      { x = 7.0856; y = -4.9610; z = 2.8521 }
    , (* C2'  *)
      { x = 6.7777; y = -3.9935; z = 3.2487 }
    , (* H2'' *)
      { x = 8.4627; y = -5.1992; z = 2.7423 }
    , (* O2'  *)
      { x = 8.8693; y = -4.8638; z = 1.9399 }
    , (* H2'  *)
      { x = 6.3877; y = -6.0809; z = 3.6362 }
    , (* C3'  *)
      { x = 5.3770; y = -5.7562; z = 3.8834 }
    , (* H3'  *)
      { x = 7.1024; y = -6.4754; z = 4.7985 }
    , (* O3'  *)
      { x = 5.2764; y = -4.2883; z = 1.2538 }
    , (* N1   *)
      { x = 4.3777; y = -2.2062; z = 0.7229 }
    , (* N3   *)
      { x = 5.5069; y = -2.9779; z = 0.9088 }
    , (* C2   *)
      { x = 3.0693; y = -2.6246; z = 0.8500 }
    , (* C4   *)
      { x = 2.9279; y = -4.0146; z = 1.2149 }
    , (* C5   *)
      { x = 4.0101; y = -4.7892; z = 1.4017 }
    , (* C6 *)
      U
        ( { x = 6.6267; y = -2.5166; z = 0.7728 }
        , (* O2   *)
          { x = 2.1383; y = -1.8396; z = 0.6581 }
        , (* O4   *)
          { x = 4.5223; y = -1.2489; z = 0.4716 }
        , (* H3   *)
          { x = 2.0151; y = -4.4065; z = 1.3290 }
        , (* H5   *)
          { x = 3.8886; y = -5.7486; z = 1.6535 } ) )

(* H6   *)

let rU02 =
  N
    ( { a = 0.5141
      ; b = 0.0246
      ; c = 0.8574
      ; (* dgf_base_tfo *)
        d = -0.5547
      ; e = -0.7529
      ; f = 0.3542
      ; g = 0.6542
      ; h = -0.6577
      ; i = -0.3734
      ; tx = -9.1111
      ; ty = -3.4598
      ; tz = -3.2939
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 4.3825; y = -6.6585; z = 4.0489 }
    , (* C5'  *)
      { x = 4.6841; y = -7.2019; z = 4.9443 }
    , (* H5'  *)
      { x = 3.6189; y = -5.8889; z = 4.1625 }
    , (* H5'' *)
      { x = 5.6255; y = -5.9175; z = 3.5998 }
    , (* C4'  *)
      { x = 5.8732; y = -5.1228; z = 4.3034 }
    , (* H4'  *)
      { x = 6.7337; y = -6.8605; z = 3.5222 }
    , (* O4'  *)
      { x = 7.5932; y = -6.4923; z = 2.4548 }
    , (* C1'  *)
      { x = 8.5661; y = -6.2983; z = 2.9064 }
    , (* H1'  *)
      { x = 7.0527; y = -5.2012; z = 1.8322 }
    , (* C2'  *)
      { x = 7.1627; y = -5.2525; z = 0.7490 }
    , (* H2'' *)
      { x = 7.6666; y = -4.1249; z = 2.4880 }
    , (* O2'  *)
      { x = 8.5944; y = -4.2543; z = 2.6981 }
    , (* H2'  *)
      { x = 5.5661; y = -5.3029; z = 2.2009 }
    , (* C3'  *)
      { x = 5.0841; y = -6.0018; z = 1.5172 }
    , (* H3'  *)
      { x = 4.9062; y = -4.0452; z = 2.2042 }
    , (* O3'  *)
      { x = 7.6298; y = -7.6136; z = 1.4752 }
    , (* N1   *)
      { x = 8.6945; y = -8.7046; z = -0.2857 }
    , (* N3   *)
      { x = 8.6943; y = -7.6514; z = 0.6066 }
    , (* C2   *)
      { x = 7.7426; y = -9.6987; z = -0.3801 }
    , (* C4   *)
      { x = 6.6642; y = -9.5742; z = 0.5722 }
    , (* C5   *)
      { x = 6.6391; y = -8.5592; z = 1.4526 }
    , (* C6 *)
      U
        ( { x = 9.5840; y = -6.8186; z = 0.6136 }
        , (* O2   *)
          { x = 7.8505; y = -10.5925; z = -1.2223 }
        , (* O4   *)
          { x = 9.4601; y = -8.7514; z = -0.9277 }
        , (* H3   *)
          { x = 5.9281; y = -10.2509; z = 0.5782 }
        , (* H5   *)
          { x = 5.8831; y = -8.4931; z = 2.1028 } ) )

(* H6   *)

let rU03 =
  N
    ( { a = -0.4993
      ; b = 0.0476
      ; c = 0.8651
      ; (* dgf_base_tfo *)
        d = 0.8078
      ; e = -0.3353
      ; f = 0.4847
      ; g = 0.3132
      ; h = 0.9409
      ; i = 0.1290
      ; tx = 6.2989
      ; ty = -5.2303
      ; tz = -3.8577
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 3.9938; y = -6.7042; z = 1.9023 }
    , (* C5'  *)
      { x = 3.2332; y = -5.9343; z = 2.0319 }
    , (* H5'  *)
      { x = 3.9666; y = -7.2863; z = 0.9812 }
    , (* H5'' *)
      { x = 5.3098; y = -5.9546; z = 1.8564 }
    , (* C4'  *)
      { x = 5.3863; y = -5.3702; z = 0.9395 }
    , (* H4'  *)
      { x = 5.3851; y = -5.0642; z = 3.0076 }
    , (* O4'  *)
      { x = 6.7315; y = -4.9724; z = 3.4462 }
    , (* C1'  *)
      { x = 7.0033; y = -3.9202; z = 3.3619 }
    , (* H1'  *)
      { x = 7.5997; y = -5.8018; z = 2.4948 }
    , (* C2'  *)
      { x = 8.3627; y = -6.3254; z = 3.0707 }
    , (* H2'' *)
      { x = 8.0410; y = -4.9501; z = 1.4724 }
    , (* O2'  *)
      { x = 8.2781; y = -4.0644; z = 1.7570 }
    , (* H2'  *)
      { x = 6.5701; y = -6.8129; z = 1.9714 }
    , (* C3'  *)
      { x = 6.4186; y = -7.5809; z = 2.7299 }
    , (* H3'  *)
      { x = 6.9357; y = -7.3841; z = 0.7235 }
    , (* O3'  *)
      { x = 6.8024; y = -5.4718; z = 4.8475 }
    , (* N1   *)
      { x = 7.9218; y = -5.5700; z = 6.8877 }
    , (* N3   *)
      { x = 7.8908; y = -5.0886; z = 5.5944 }
    , (* C2   *)
      { x = 6.9789; y = -6.3827; z = 7.4823 }
    , (* C4   *)
      { x = 5.8742; y = -6.7319; z = 6.6202 }
    , (* C5   *)
      { x = 5.8182; y = -6.2769; z = 5.3570 }
    , (* C6 *)
      U
        ( { x = 8.7747; y = -4.3728; z = 5.1568 }
        , (* O2   *)
          { x = 7.1154; y = -6.7509; z = 8.6509 }
        , (* O4   *)
          { x = 8.7055; y = -5.3037; z = 7.4491 }
        , (* H3   *)
          { x = 5.1416; y = -7.3178; z = 6.9665 }
        , (* H5   *)
          { x = 5.0441; y = -6.5310; z = 4.7784 } ) )

(* H6   *)

let rU04 =
  N
    ( { a = -0.5669
      ; b = -0.8012
      ; c = 0.1918
      ; (* dgf_base_tfo *)
        d = -0.8129
      ; e = 0.5817
      ; f = 0.0273
      ; g = -0.1334
      ; h = -0.1404
      ; i = -0.9811
      ; tx = -0.3279
      ; ty = 8.3874
      ; tz = 0.3355
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2416; y = -8.2422; z = 2.8181 }
    , (* C5'  *)
      { x = 5.2050; y = -8.8128; z = 1.8901 }
    , (* H5'  *)
      { x = 5.5368; y = -8.7738; z = 3.7227 }
    , (* H5'' *)
      { x = 6.3232; y = -7.2037; z = 2.6002 }
    , (* C4'  *)
      { x = 7.3048; y = -7.6757; z = 2.5577 }
    , (* H4'  *)
      { x = 6.0635; y = -6.5092; z = 1.3456 }
    , (* O4'  *)
      { x = 6.4697; y = -5.1547; z = 1.4629 }
    , (* C1'  *)
      { x = 7.2354; y = -5.0043; z = 0.7018 }
    , (* H1'  *)
      { x = 7.0856; y = -4.9610; z = 2.8521 }
    , (* C2'  *)
      { x = 6.7777; y = -3.9935; z = 3.2487 }
    , (* H2'' *)
      { x = 8.4627; y = -5.1992; z = 2.7423 }
    , (* O2'  *)
      { x = 8.8693; y = -4.8638; z = 1.9399 }
    , (* H2'  *)
      { x = 6.3877; y = -6.0809; z = 3.6362 }
    , (* C3'  *)
      { x = 5.3770; y = -5.7562; z = 3.8834 }
    , (* H3'  *)
      { x = 7.1024; y = -6.4754; z = 4.7985 }
    , (* O3'  *)
      { x = 5.2764; y = -4.2883; z = 1.2538 }
    , (* N1   *)
      { x = 3.8961; y = -3.0896; z = -0.1893 }
    , (* N3   *)
      { x = 5.0095; y = -3.8907; z = -0.0346 }
    , (* C2   *)
      { x = 3.0480; y = -2.6632; z = 0.8116 }
    , (* C4   *)
      { x = 3.4093; y = -3.1310; z = 2.1292 }
    , (* C5   *)
      { x = 4.4878; y = -3.9124; z = 2.3088 }
    , (* C6 *)
      U
        ( { x = 5.7005; y = -4.2164; z = -0.9842 }
        , (* O2   *)
          { x = 2.0800; y = -1.9458; z = 0.5503 }
        , (* O4   *)
          { x = 3.6834; y = -2.7882; z = -1.1190 }
        , (* H3   *)
          { x = 2.8508; y = -2.8721; z = 2.9172 }
        , (* H5   *)
          { x = 4.7188; y = -4.2247; z = 3.2295 } ) )

(* H6   *)

let rU05 =
  N
    ( { a = -0.6298
      ; b = 0.0246
      ; c = 0.7763
      ; (* dgf_base_tfo *)
        d = -0.5226
      ; e = -0.7529
      ; f = -0.4001
      ; g = 0.5746
      ; h = -0.6577
      ; i = 0.4870
      ; tx = -0.0208
      ; ty = -3.4598
      ; tz = -9.6882
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 4.3825; y = -6.6585; z = 4.0489 }
    , (* C5'  *)
      { x = 4.6841; y = -7.2019; z = 4.9443 }
    , (* H5'  *)
      { x = 3.6189; y = -5.8889; z = 4.1625 }
    , (* H5'' *)
      { x = 5.6255; y = -5.9175; z = 3.5998 }
    , (* C4'  *)
      { x = 5.8732; y = -5.1228; z = 4.3034 }
    , (* H4'  *)
      { x = 6.7337; y = -6.8605; z = 3.5222 }
    , (* O4'  *)
      { x = 7.5932; y = -6.4923; z = 2.4548 }
    , (* C1'  *)
      { x = 8.5661; y = -6.2983; z = 2.9064 }
    , (* H1'  *)
      { x = 7.0527; y = -5.2012; z = 1.8322 }
    , (* C2'  *)
      { x = 7.1627; y = -5.2525; z = 0.7490 }
    , (* H2'' *)
      { x = 7.6666; y = -4.1249; z = 2.4880 }
    , (* O2'  *)
      { x = 8.5944; y = -4.2543; z = 2.6981 }
    , (* H2'  *)
      { x = 5.5661; y = -5.3029; z = 2.2009 }
    , (* C3'  *)
      { x = 5.0841; y = -6.0018; z = 1.5172 }
    , (* H3'  *)
      { x = 4.9062; y = -4.0452; z = 2.2042 }
    , (* O3'  *)
      { x = 7.6298; y = -7.6136; z = 1.4752 }
    , (* N1   *)
      { x = 8.5977; y = -9.5977; z = 0.7329 }
    , (* N3   *)
      { x = 8.5951; y = -8.5745; z = 1.6594 }
    , (* C2   *)
      { x = 7.7372; y = -9.7371; z = -0.3364 }
    , (* C4   *)
      { x = 6.7596; y = -8.6801; z = -0.4476 }
    , (* C5   *)
      { x = 6.7338; y = -7.6721; z = 0.4408 }
    , (* C6 *)
      U
        ( { x = 9.3993; y = -8.5377; z = 2.5743 }
        , (* O2   *)
          { x = 7.8374; y = -10.6990; z = -1.1008 }
        , (* O4   *)
          { x = 9.2924; y = -10.3081; z = 0.8477 }
        , (* H3   *)
          { x = 6.0932; y = -8.6982; z = -1.1929 }
        , (* H5   *)
          { x = 6.0481; y = -6.9515; z = 0.3446 } ) )

(* H6   *)

let rU06 =
  N
    ( { a = -0.9837
      ; b = 0.0476
      ; c = -0.1733
      ; (* dgf_base_tfo *)
        d = -0.1792
      ; e = -0.3353
      ; f = 0.9249
      ; g = -0.0141
      ; h = 0.9409
      ; i = 0.3384
      ; tx = 5.7793
      ; ty = -5.2303
      ; tz = 4.5997
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 3.9938; y = -6.7042; z = 1.9023 }
    , (* C5'  *)
      { x = 3.2332; y = -5.9343; z = 2.0319 }
    , (* H5'  *)
      { x = 3.9666; y = -7.2863; z = 0.9812 }
    , (* H5'' *)
      { x = 5.3098; y = -5.9546; z = 1.8564 }
    , (* C4'  *)
      { x = 5.3863; y = -5.3702; z = 0.9395 }
    , (* H4'  *)
      { x = 5.3851; y = -5.0642; z = 3.0076 }
    , (* O4'  *)
      { x = 6.7315; y = -4.9724; z = 3.4462 }
    , (* C1'  *)
      { x = 7.0033; y = -3.9202; z = 3.3619 }
    , (* H1'  *)
      { x = 7.5997; y = -5.8018; z = 2.4948 }
    , (* C2'  *)
      { x = 8.3627; y = -6.3254; z = 3.0707 }
    , (* H2'' *)
      { x = 8.0410; y = -4.9501; z = 1.4724 }
    , (* O2'  *)
      { x = 8.2781; y = -4.0644; z = 1.7570 }
    , (* H2'  *)
      { x = 6.5701; y = -6.8129; z = 1.9714 }
    , (* C3'  *)
      { x = 6.4186; y = -7.5809; z = 2.7299 }
    , (* H3'  *)
      { x = 6.9357; y = -7.3841; z = 0.7235 }
    , (* O3'  *)
      { x = 6.8024; y = -5.4718; z = 4.8475 }
    , (* N1   *)
      { x = 6.6920; y = -5.0495; z = 7.1354 }
    , (* N3   *)
      { x = 6.6201; y = -4.5500; z = 5.8506 }
    , (* C2   *)
      { x = 6.9254; y = -6.3614; z = 7.4926 }
    , (* C4   *)
      { x = 7.1046; y = -7.2543; z = 6.3718 }
    , (* C5   *)
      { x = 7.0391; y = -6.7951; z = 5.1106 }
    , (* C6 *)
      U
        ( { x = 6.4083; y = -3.3696; z = 5.6340 }
        , (* O2   *)
          { x = 6.9679; y = -6.6901; z = 8.6800 }
        , (* O4   *)
          { x = 6.5626; y = -4.3957; z = 7.8812 }
        , (* H3   *)
          { x = 7.2781; y = -8.2254; z = 6.5350 }
        , (* H5   *)
          { x = 7.1657; y = -7.4312; z = 4.3503 } ) )

(* H6   *)

let rU07 =
  N
    ( { a = -0.9434
      ; b = 0.3172
      ; c = 0.0971
      ; (* dgf_base_tfo *)
        d = 0.2294
      ; e = 0.4125
      ; f = 0.8816
      ; g = 0.2396
      ; h = 0.8539
      ; i = -0.4619
      ; tx = 8.3625
      ; ty = -52.7147
      ; tz = 1.3745
      }
    , { a = 0.2765
      ; b = -0.1121
      ; c = -0.9545
      ; (* P_O3'_275_tfo *)
        d = -0.8297
      ; e = 0.4733
      ; f = -0.2959
      ; g = 0.4850
      ; h = 0.8737
      ; i = 0.0379
      ; tx = -14.7774
      ; ty = -45.2464
      ; tz = 21.9088
      }
    , { a = 0.1063
      ; b = -0.6334
      ; c = -0.7665
      ; (* P_O3'_180_tfo *)
        d = -0.5932
      ; e = -0.6591
      ; f = 0.4624
      ; g = -0.7980
      ; h = 0.4055
      ; i = -0.4458
      ; tx = 43.7634
      ; ty = 4.3296
      ; tz = 28.4890
      }
    , { a = 0.7136
      ; b = -0.5032
      ; c = -0.4873
      ; (* P_O3'_60_tfo *)
        d = 0.6803
      ; e = 0.3317
      ; f = 0.6536
      ; g = -0.1673
      ; h = -0.7979
      ; i = 0.5791
      ; tx = -17.1858
      ; ty = 41.4390
      ; tz = -27.0751
      }
    , { x = 21.3880; y = 15.0780; z = 45.5770 }
    , (* P    *)
      { x = 21.9980; y = 14.5500; z = 46.8210 }
    , (* O1P  *)
      { x = 21.1450; y = 14.0270; z = 44.5420 }
    , (* O2P  *)
      { x = 22.1250; y = 16.3600; z = 44.9460 }
    , (* O5'  *)
      { x = 21.5037; y = 16.8594; z = 43.7323 }
    , (* C5'  *)
      { x = 20.8147; y = 17.6663; z = 43.9823 }
    , (* H5'  *)
      { x = 21.1086; y = 16.0230; z = 43.1557 }
    , (* H5'' *)
      { x = 22.5654; y = 17.4874; z = 42.8616 }
    , (* C4'  *)
      { x = 22.1584; y = 17.7243; z = 41.8785 }
    , (* H4'  *)
      { x = 23.0557; y = 18.6826; z = 43.4751 }
    , (* O4'  *)
      { x = 24.4788; y = 18.6151; z = 43.6455 }
    , (* C1'  *)
      { x = 24.9355; y = 19.0840; z = 42.7739 }
    , (* H1'  *)
      { x = 24.7958; y = 17.1427; z = 43.6474 }
    , (* C2'  *)
      { x = 24.5652; y = 16.7400; z = 44.6336 }
    , (* H2'' *)
      { x = 26.1041; y = 16.8773; z = 43.2455 }
    , (* O2'  *)
      { x = 26.7516; y = 17.5328; z = 43.5149 }
    , (* H2'  *)
      { x = 23.8109; y = 16.5979; z = 42.6377 }
    , (* C3'  *)
      { x = 23.5756; y = 15.5686; z = 42.9084 }
    , (* H3'  *)
      { x = 24.2890; y = 16.7447; z = 41.2729 }
    , (* O3'  *)
      { x = 24.9420; y = 19.2174; z = 44.8923 }
    , (* N1   *)
      { x = 25.2655; y = 20.5636; z = 44.8883 }
    , (* N3   *)
      { x = 25.1663; y = 21.2219; z = 43.8561 }
    , (* C2   *)
      { x = 25.6911; y = 21.1219; z = 46.0494 }
    , (* C4   *)
      { x = 25.8051; y = 20.4068; z = 47.2048 }
    , (* C5   *)
      { x = 26.2093; y = 20.9962; z = 48.2534 }
    , (* C6 *)
      U
        ( { x = 25.4692; y = 19.0221; z = 47.2053 }
        , (* O2   *)
          { x = 25.0502; y = 18.4827; z = 46.0370 }
        , (* O4   *)
          { x = 25.9599; y = 22.1772; z = 46.0966 }
        , (* H3   *)
          { x = 25.5545; y = 18.4409; z = 48.1234 }
        , (* H5   *)
          { x = 24.7854; y = 17.4265; z = 45.9883 } ) )

(* H6   *)

let rU08 =
  N
    ( { a = -0.0080
      ; b = -0.7928
      ; c = 0.6094
      ; (* dgf_base_tfo *)
        d = -0.7512
      ; e = 0.4071
      ; f = 0.5197
      ; g = -0.6601
      ; h = -0.4536
      ; i = -0.5988
      ; tx = 44.1482
      ; ty = 30.7036
      ; tz = 2.1088
      }
    , { a = 0.2765
      ; b = -0.1121
      ; c = -0.9545
      ; (* P_O3'_275_tfo *)
        d = -0.8297
      ; e = 0.4733
      ; f = -0.2959
      ; g = 0.4850
      ; h = 0.8737
      ; i = 0.0379
      ; tx = -14.7774
      ; ty = -45.2464
      ; tz = 21.9088
      }
    , { a = 0.1063
      ; b = -0.6334
      ; c = -0.7665
      ; (* P_O3'_180_tfo *)
        d = -0.5932
      ; e = -0.6591
      ; f = 0.4624
      ; g = -0.7980
      ; h = 0.4055
      ; i = -0.4458
      ; tx = 43.7634
      ; ty = 4.3296
      ; tz = 28.4890
      }
    , { a = 0.7136
      ; b = -0.5032
      ; c = -0.4873
      ; (* P_O3'_60_tfo *)
        d = 0.6803
      ; e = 0.3317
      ; f = 0.6536
      ; g = -0.1673
      ; h = -0.7979
      ; i = 0.5791
      ; tx = -17.1858
      ; ty = 41.4390
      ; tz = -27.0751
      }
    , { x = 21.3880; y = 15.0780; z = 45.5770 }
    , (* P    *)
      { x = 21.9980; y = 14.5500; z = 46.8210 }
    , (* O1P  *)
      { x = 21.1450; y = 14.0270; z = 44.5420 }
    , (* O2P  *)
      { x = 22.1250; y = 16.3600; z = 44.9460 }
    , (* O5'  *)
      { x = 23.5096; y = 16.1227; z = 44.5783 }
    , (* C5'  *)
      { x = 23.5649; y = 15.8588; z = 43.5222 }
    , (* H5'  *)
      { x = 23.9621; y = 15.4341; z = 45.2919 }
    , (* H5'' *)
      { x = 24.2805; y = 17.4138; z = 44.7151 }
    , (* C4'  *)
      { x = 25.3492; y = 17.2309; z = 44.6030 }
    , (* H4'  *)
      { x = 23.8497; y = 18.3471; z = 43.7208 }
    , (* O4'  *)
      { x = 23.4090; y = 19.5681; z = 44.3321 }
    , (* C1'  *)
      { x = 24.2595; y = 20.2496; z = 44.3524 }
    , (* H1'  *)
      { x = 23.0418; y = 19.1813; z = 45.7407 }
    , (* C2'  *)
      { x = 22.0532; y = 18.7224; z = 45.7273 }
    , (* H2'' *)
      { x = 23.1307; y = 20.2521; z = 46.6291 }
    , (* O2'  *)
      { x = 22.8888; y = 21.1051; z = 46.2611 }
    , (* H2'  *)
      { x = 24.0799; y = 18.1326; z = 46.0700 }
    , (* C3'  *)
      { x = 23.6490; y = 17.4370; z = 46.7900 }
    , (* H3'  *)
      { x = 25.3329; y = 18.7227; z = 46.5109 }
    , (* O3'  *)
      { x = 22.2515; y = 20.1624; z = 43.6698 }
    , (* N1   *)
      { x = 22.4760; y = 21.0609; z = 42.6406 }
    , (* N3   *)
      { x = 23.6229; y = 21.3462; z = 42.3061 }
    , (* C2   *)
      { x = 21.3986; y = 21.6081; z = 42.0236 }
    , (* C4   *)
      { x = 20.1189; y = 21.3012; z = 42.3804 }
    , (* C5   *)
      { x = 19.1599; y = 21.8516; z = 41.7578 }
    , (* C6 *)
      U
        ( { x = 19.8919; y = 20.3745; z = 43.4387 }
        , (* O2   *)
          { x = 20.9790; y = 19.8423; z = 44.0440 }
        , (* O4   *)
          { x = 21.5235; y = 22.3222; z = 41.2097 }
        , (* H3   *)
          { x = 18.8732; y = 20.1200; z = 43.7312 }
        , (* H5   *)
          { x = 20.8545; y = 19.1313; z = 44.8608 } ) )

(* H6   *)

let rU09 =
  N
    ( { a = -0.0317
      ; b = 0.1374
      ; c = 0.9900
      ; (* dgf_base_tfo *)
        d = -0.3422
      ; e = -0.9321
      ; f = 0.1184
      ; g = 0.9391
      ; h = -0.3351
      ; i = 0.0765
      ; tx = -32.1929
      ; ty = 25.8198
      ; tz = -28.5088
      }
    , { a = 0.2765
      ; b = -0.1121
      ; c = -0.9545
      ; (* P_O3'_275_tfo *)
        d = -0.8297
      ; e = 0.4733
      ; f = -0.2959
      ; g = 0.4850
      ; h = 0.8737
      ; i = 0.0379
      ; tx = -14.7774
      ; ty = -45.2464
      ; tz = 21.9088
      }
    , { a = 0.1063
      ; b = -0.6334
      ; c = -0.7665
      ; (* P_O3'_180_tfo *)
        d = -0.5932
      ; e = -0.6591
      ; f = 0.4624
      ; g = -0.7980
      ; h = 0.4055
      ; i = -0.4458
      ; tx = 43.7634
      ; ty = 4.3296
      ; tz = 28.4890
      }
    , { a = 0.7136
      ; b = -0.5032
      ; c = -0.4873
      ; (* P_O3'_60_tfo *)
        d = 0.6803
      ; e = 0.3317
      ; f = 0.6536
      ; g = -0.1673
      ; h = -0.7979
      ; i = 0.5791
      ; tx = -17.1858
      ; ty = 41.4390
      ; tz = -27.0751
      }
    , { x = 21.3880; y = 15.0780; z = 45.5770 }
    , (* P    *)
      { x = 21.9980; y = 14.5500; z = 46.8210 }
    , (* O1P  *)
      { x = 21.1450; y = 14.0270; z = 44.5420 }
    , (* O2P  *)
      { x = 22.1250; y = 16.3600; z = 44.9460 }
    , (* O5'  *)
      { x = 21.5037; y = 16.8594; z = 43.7323 }
    , (* C5'  *)
      { x = 20.8147; y = 17.6663; z = 43.9823 }
    , (* H5'  *)
      { x = 21.1086; y = 16.0230; z = 43.1557 }
    , (* H5'' *)
      { x = 22.5654; y = 17.4874; z = 42.8616 }
    , (* C4'  *)
      { x = 23.0565; y = 18.3036; z = 43.3915 }
    , (* H4'  *)
      { x = 23.5375; y = 16.5054; z = 42.4925 }
    , (* O4'  *)
      { x = 23.6574; y = 16.4257; z = 41.0649 }
    , (* C1'  *)
      { x = 24.4701; y = 17.0882; z = 40.7671 }
    , (* H1'  *)
      { x = 22.3525; y = 16.9643; z = 40.5396 }
    , (* C2'  *)
      { x = 21.5993; y = 16.1799; z = 40.6133 }
    , (* H2'' *)
      { x = 22.4693; y = 17.4849; z = 39.2515 }
    , (* O2'  *)
      { x = 23.0899; y = 17.0235; z = 38.6827 }
    , (* H2'  *)
      { x = 22.0341; y = 18.0633; z = 41.5279 }
    , (* C3'  *)
      { x = 20.9509; y = 18.1709; z = 41.5846 }
    , (* H3'  *)
      { x = 22.7249; y = 19.3020; z = 41.2100 }
    , (* O3'  *)
      { x = 23.8580; y = 15.0648; z = 40.5757 }
    , (* N1   *)
      { x = 25.1556; y = 14.5982; z = 40.4523 }
    , (* N3   *)
      { x = 26.1047; y = 15.3210; z = 40.7448 }
    , (* C2   *)
      { x = 25.3391; y = 13.3315; z = 40.0020 }
    , (* C4   *)
      { x = 24.2974; y = 12.5148; z = 39.6749 }
    , (* C5   *)
      { x = 24.5450; y = 11.3410; z = 39.2610 }
    , (* C6 *)
      U
        ( { x = 22.9633; y = 12.9979; z = 39.8053 }
        , (* O2   *)
          { x = 22.8009; y = 14.2648; z = 40.2524 }
        , (* O4   *)
          { x = 26.3414; y = 12.9194; z = 39.8855 }
        , (* H3   *)
          { x = 22.1227; y = 12.3533; z = 39.5486 }
        , (* H5   *)
          { x = 21.7989; y = 14.6788; z = 40.3650 } ) )

(* H6   *)

let rU10 =
  N
    ( { a = -0.9674
      ; b = 0.1021
      ; c = -0.2318
      ; (* dgf_base_tfo *)
        d = -0.2514
      ; e = -0.2766
      ; f = 0.9275
      ; g = 0.0306
      ; h = 0.9555
      ; i = 0.2933
      ; tx = 27.8571
      ; ty = -42.1305
      ; tz = -24.4563
      }
    , { a = 0.2765
      ; b = -0.1121
      ; c = -0.9545
      ; (* P_O3'_275_tfo *)
        d = -0.8297
      ; e = 0.4733
      ; f = -0.2959
      ; g = 0.4850
      ; h = 0.8737
      ; i = 0.0379
      ; tx = -14.7774
      ; ty = -45.2464
      ; tz = 21.9088
      }
    , { a = 0.1063
      ; b = -0.6334
      ; c = -0.7665
      ; (* P_O3'_180_tfo *)
        d = -0.5932
      ; e = -0.6591
      ; f = 0.4624
      ; g = -0.7980
      ; h = 0.4055
      ; i = -0.4458
      ; tx = 43.7634
      ; ty = 4.3296
      ; tz = 28.4890
      }
    , { a = 0.7136
      ; b = -0.5032
      ; c = -0.4873
      ; (* P_O3'_60_tfo *)
        d = 0.6803
      ; e = 0.3317
      ; f = 0.6536
      ; g = -0.1673
      ; h = -0.7979
      ; i = 0.5791
      ; tx = -17.1858
      ; ty = 41.4390
      ; tz = -27.0751
      }
    , { x = 21.3880; y = 15.0780; z = 45.5770 }
    , (* P    *)
      { x = 21.9980; y = 14.5500; z = 46.8210 }
    , (* O1P  *)
      { x = 21.1450; y = 14.0270; z = 44.5420 }
    , (* O2P  *)
      { x = 22.1250; y = 16.3600; z = 44.9460 }
    , (* O5'  *)
      { x = 23.5096; y = 16.1227; z = 44.5783 }
    , (* C5'  *)
      { x = 23.5649; y = 15.8588; z = 43.5222 }
    , (* H5'  *)
      { x = 23.9621; y = 15.4341; z = 45.2919 }
    , (* H5'' *)
      { x = 24.2805; y = 17.4138; z = 44.7151 }
    , (* C4'  *)
      { x = 23.8509; y = 18.1819; z = 44.0720 }
    , (* H4'  *)
      { x = 24.2506; y = 17.8583; z = 46.0741 }
    , (* O4'  *)
      { x = 25.5830; y = 18.0320; z = 46.5775 }
    , (* C1'  *)
      { x = 25.8569; y = 19.0761; z = 46.4256 }
    , (* H1'  *)
      { x = 26.4410; y = 17.1555; z = 45.7033 }
    , (* C2'  *)
      { x = 26.3459; y = 16.1253; z = 46.0462 }
    , (* H2'' *)
      { x = 27.7649; y = 17.5888; z = 45.6478 }
    , (* O2'  *)
      { x = 28.1004; y = 17.9719; z = 46.4616 }
    , (* H2'  *)
      { x = 25.7796; y = 17.2997; z = 44.3513 }
    , (* C3'  *)
      { x = 25.9478; y = 16.3824; z = 43.7871 }
    , (* H3'  *)
      { x = 26.2154; y = 18.4984; z = 43.6541 }
    , (* O3'  *)
      { x = 25.7321; y = 17.6281; z = 47.9726 }
    , (* N1   *)
      { x = 25.5136; y = 18.5779; z = 48.9560 }
    , (* N3   *)
      { x = 25.2079; y = 19.7276; z = 48.6503 }
    , (* C2   *)
      { x = 25.6482; y = 18.1987; z = 50.2518 }
    , (* C4   *)
      { x = 25.9847; y = 16.9266; z = 50.6092 }
    , (* C5   *)
      { x = 26.0918; y = 16.6439; z = 51.8416 }
    , (* C6 *)
      U
        ( { x = 26.2067; y = 15.9515; z = 49.5943 }
        , (* O2   *)
          { x = 26.0713; y = 16.3497; z = 48.3080 }
        , (* O4   *)
          { x = 25.4890; y = 18.9105; z = 51.0618 }
        , (* H3   *)
          { x = 26.4742; y = 14.9310; z = 49.8682 }
        , (* H5   *)
          { x = 26.2346; y = 15.6394; z = 47.4975 } ) )

(* H6   *)

let rUs = [ rU01; rU02; rU03; rU04; rU05; rU06; rU07; rU08; rU09; rU10 ]

let rG' =
  N
    ( { a = -0.2067
      ; b = -0.0264
      ; c = 0.9780
      ; (* dgf_base_tfo *)
        d = 0.9770
      ; e = -0.0586
      ; f = 0.2049
      ; g = 0.0519
      ; h = 0.9979
      ; i = 0.0379
      ; tx = 1.0331
      ; ty = -46.8078
      ; tz = -36.4742
      }
    , { a = -0.8644
      ; b = -0.4956
      ; c = -0.0851
      ; (* P_O3'_275_tfo *)
        d = -0.0427
      ; e = 0.2409
      ; f = -0.9696
      ; g = 0.5010
      ; h = -0.8345
      ; i = -0.2294
      ; tx = 4.0167
      ; ty = 54.5377
      ; tz = 12.4779
      }
    , { a = 0.3706
      ; b = -0.6167
      ; c = 0.6945
      ; (* P_O3'_180_tfo *)
        d = -0.2867
      ; e = -0.7872
      ; f = -0.5460
      ; g = 0.8834
      ; h = 0.0032
      ; i = -0.4686
      ; tx = -52.9020
      ; ty = 18.6313
      ; tz = -0.6709
      }
    , { a = 0.4155
      ; b = 0.9025
      ; c = -0.1137
      ; (* P_O3'_60_tfo *)
        d = 0.9040
      ; e = -0.4236
      ; f = -0.0582
      ; g = -0.1007
      ; h = -0.0786
      ; i = -0.9918
      ; tx = -7.6624
      ; ty = -25.2080
      ; tz = 49.5181
      }
    , { x = 31.3810; y = 0.1400; z = 47.5810 }
    , (* P    *)
      { x = 29.9860; y = 0.6630; z = 47.6290 }
    , (* O1P  *)
      { x = 31.7210; y = -0.6460; z = 48.8090 }
    , (* O2P  *)
      { x = 32.4940; y = 1.2540; z = 47.2740 }
    , (* O5'  *)
      { x = 32.1610; y = 2.2370; z = 46.2560 }
    , (* C5'  *)
      { x = 31.2986; y = 2.8190; z = 46.5812 }
    , (* H5'  *)
      { x = 32.0980; y = 1.7468; z = 45.2845 }
    , (* H5'' *)
      { x = 33.3476; y = 3.1959; z = 46.1947 }
    , (* C4'  *)
      { x = 33.2668; y = 3.8958; z = 45.3630 }
    , (* H4'  *)
      { x = 33.3799; y = 3.9183; z = 47.4216 }
    , (* O4'  *)
      { x = 34.6515; y = 3.7222; z = 48.0398 }
    , (* C1'  *)
      { x = 35.2947; y = 4.5412; z = 47.7180 }
    , (* H1'  *)
      { x = 35.1756; y = 2.4228; z = 47.4827 }
    , (* C2'  *)
      { x = 34.6778; y = 1.5937; z = 47.9856 }
    , (* H2'' *)
      { x = 36.5631; y = 2.2672; z = 47.4798 }
    , (* O2'  *)
      { x = 37.0163; y = 2.6579; z = 48.2305 }
    , (* H2'  *)
      { x = 34.6953; y = 2.5043; z = 46.0448 }
    , (* C3'  *)
      { x = 34.5444; y = 1.4917; z = 45.6706 }
    , (* H3'  *)
      { x = 35.6679; y = 3.3009; z = 45.3487 }
    , (* O3'  *)
      { x = 37.4804; y = 4.0914; z = 52.2559 }
    , (* N1   *)
      { x = 36.9670; y = 4.1312; z = 49.9281 }
    , (* N3   *)
      { x = 37.8045; y = 4.2519; z = 50.9550 }
    , (* C2   *)
      { x = 35.7171; y = 3.8264; z = 50.3222 }
    , (* C4   *)
      { x = 35.2668; y = 3.6420; z = 51.6115 }
    , (* C5   *)
      { x = 36.2037; y = 3.7829; z = 52.6706 }
    , (* C6 *)
      G
        ( { x = 39.0869; y = 4.5552; z = 50.7092 }
        , (* N2   *)
          { x = 33.9075; y = 3.3338; z = 51.6102 }
        , (* N7   *)
          { x = 34.6126; y = 3.6358; z = 49.5108 }
        , (* N9   *)
          { x = 33.5805; y = 3.3442; z = 50.3425 }
        , (* C8   *)
          { x = 35.9958; y = 3.6512; z = 53.8724 }
        , (* O6   *)
          { x = 38.2106; y = 4.2053; z = 52.9295 }
        , (* H1   *)
          { x = 39.8218; y = 4.6863; z = 51.3896 }
        , (* H21  *)
          { x = 39.3420; y = 4.6857; z = 49.7407 }
        , (* H22  *)
          { x = 32.5194; y = 3.1070; z = 50.2664 } ) )

(* H8   *)

let rU' =
  N
    ( { a = -0.0109
      ; b = 0.5907
      ; c = 0.8068
      ; (* dgf_base_tfo *)
        d = 0.2217
      ; e = -0.7853
      ; f = 0.5780
      ; g = 0.9751
      ; h = 0.1852
      ; i = -0.1224
      ; tx = -1.4225
      ; ty = -11.0956
      ; tz = -2.5217
      }
    , { a = -0.8313
      ; b = -0.4738
      ; c = -0.2906
      ; (* P_O3'_275_tfo *)
        d = 0.0649
      ; e = 0.4366
      ; f = -0.8973
      ; g = 0.5521
      ; h = -0.7648
      ; i = -0.3322
      ; tx = 1.6833
      ; ty = 6.8060
      ; tz = -7.0011
      }
    , { a = 0.3445
      ; b = -0.7630
      ; c = 0.5470
      ; (* P_O3'_180_tfo *)
        d = -0.4628
      ; e = -0.6450
      ; f = -0.6082
      ; g = 0.8168
      ; h = -0.0436
      ; i = -0.5753
      ; tx = -6.8179
      ; ty = -3.9778
      ; tz = -5.9887
      }
    , { a = 0.5855
      ; b = 0.7931
      ; c = -0.1682
      ; (* P_O3'_60_tfo *)
        d = 0.8103
      ; e = -0.5790
      ; f = 0.0906
      ; g = -0.0255
      ; h = -0.1894
      ; i = -0.9816
      ; tx = 6.1203
      ; ty = -7.1051
      ; tz = 3.1984
      }
    , { x = 2.6760; y = -8.4960; z = 3.2880 }
    , (* P    *)
      { x = 1.4950; y = -7.6230; z = 3.4770 }
    , (* O1P  *)
      { x = 2.9490; y = -9.4640; z = 4.3740 }
    , (* O2P  *)
      { x = 3.9730; y = -7.5950; z = 3.0340 }
    , (* O5'  *)
      { x = 5.2430; y = -8.2420; z = 2.8260 }
    , (* C5'  *)
      { x = 5.1974; y = -8.8497; z = 1.9223 }
    , (* H5'  *)
      { x = 5.5548; y = -8.7348; z = 3.7469 }
    , (* H5'' *)
      { x = 6.3140; y = -7.2060; z = 2.5510 }
    , (* C4'  *)
      { x = 5.8744; y = -6.2116; z = 2.4731 }
    , (* H4'  *)
      { x = 7.2798; y = -7.2260; z = 3.6420 }
    , (* O4'  *)
      { x = 8.5733; y = -6.9410; z = 3.1329 }
    , (* C1'  *)
      { x = 8.9047; y = -6.0374; z = 3.6446 }
    , (* H1'  *)
      { x = 8.4429; y = -6.6596; z = 1.6327 }
    , (* C2'  *)
      { x = 9.2880; y = -7.1071; z = 1.1096 }
    , (* H2'' *)
      { x = 8.2502; y = -5.2799; z = 1.4754 }
    , (* O2'  *)
      { x = 8.7676; y = -4.7284; z = 2.0667 }
    , (* H2'  *)
      { x = 7.1642; y = -7.4416; z = 1.3021 }
    , (* C3'  *)
      { x = 7.4125; y = -8.5002; z = 1.2260 }
    , (* H3'  *)
      { x = 6.5160; y = -6.9772; z = 0.1267 }
    , (* O3'  *)
      { x = 9.4531; y = -8.1107; z = 3.4087 }
    , (* N1   *)
      { x = 11.5931; y = -9.0015; z = 3.6357 }
    , (* N3   *)
      { x = 10.8101; y = -7.8950; z = 3.3748 }
    , (* C2   *)
      { x = 11.1439; y = -10.2744; z = 3.9206 }
    , (* C4   *)
      { x = 9.7056; y = -10.4026; z = 3.9332 }
    , (* C5   *)
      { x = 8.9192; y = -9.3419; z = 3.6833 }
    , (* C6 *)
      U
        ( { x = 11.3013; y = -6.8063; z = 3.1326 }
        , (* O2   *)
          { x = 11.9431; y = -11.1876; z = 4.1375 }
        , (* O4   *)
          { x = 12.5840; y = -8.8673; z = 3.6158 }
        , (* H3   *)
          { x = 9.2891; y = -11.2898; z = 4.1313 }
        , (* H5   *)
          { x = 7.9263; y = -9.4537; z = 3.6977 } ) )

(* H6   *)

(* -- PARTIAL INSTANTIATIONS ------------------------------------------------*)

type variable =
  { id : int
  ; t : tfo
  ; n : nuc
  }

let mk_var i t n = { id = i; t; n }

let absolute_pos v p = tfo_apply v.t p

let atom_pos atom v = absolute_pos v (atom v.n)

let rec get_var id = function
  | v :: lst -> if id = v.id then v else get_var id lst
  | _ -> assert false

(* -- SEARCH ----------------------------------------------------------------*)

(* Sequential backtracking algorithm *)

let rec search (partial_inst : variable list) l constr =
  match l with
  | [] -> [ partial_inst ]
  | h :: t ->
      let rec try_assignments = function
        | [] -> []
        | v :: vs ->
            if constr v partial_inst
            then search (v :: partial_inst) t constr @ try_assignments vs
            else try_assignments vs
      in
      try_assignments (h partial_inst)

(* -- DOMAINS ---------------------------------------------------------------*)

(* Primary structure:   strand A CUGCCACGUCUG, strand B CAGACGUGGCAG

   Secondary structure: strand A CUGCCACGUCUG
                                 ||||||||||||
                                 GACGGUGCAGAC strand B

   Tertiary structure:

      5' end of strand A C1----G12 3' end of strand B
                       U2-------A11
                      G3-------C10
                      C4-----G9
                       C5---G8
                          A6
                        G6-C7
                       C5----G8
                      A4-------U9
                      G3--------C10
                       A2-------U11
     5' end of strand B C1----G12 3' end of strand A

   "helix", "stacked" and "connected" describe the spatial relationship
   between two consecutive nucleotides. E.g. the nucleotides C1 and U2
   from the strand A.

   "wc" (stands for Watson-Crick and is a type of base-pairing),
   and "wc-dumas" describe the spatial relationship between
   nucleotides from two chains that are growing in opposite directions.
   E.g. the nucleotides C1 from strand A and G12 from strand B.
*)

(* Dynamic Domains *)

(* Given,
     "refnuc" a nucleotide which is already positioned,
     "nucl" the nucleotide to be placed,
     and "tfo" a transformation matrix which expresses the desired
     relationship between "refnuc" and "nucl",
   the function "dgf-base" computes the transformation matrix that
   places the nucleotide "nucl" in the given relationship to "refnuc".
*)

let dgf_base tfo v nucl =
  let x =
    if is_A v.n
    then tfo_align (atom_pos nuc_C1' v) (atom_pos rA_N9 v) (atom_pos nuc_C4 v)
    else if is_C v.n
    then tfo_align (atom_pos nuc_C1' v) (atom_pos nuc_N1 v) (atom_pos nuc_C2 v)
    else if is_G v.n
    then tfo_align (atom_pos nuc_C1' v) (atom_pos rG_N9 v) (atom_pos nuc_C4 v)
    else tfo_align (atom_pos nuc_C1' v) (atom_pos nuc_N1 v) (atom_pos nuc_C2 v)
  in
  tfo_combine (nuc_dgf_base_tfo nucl) (tfo_combine tfo (tfo_inv_ortho x))

(* Placement of first nucleotide. *)

let reference n i partial_inst = [ mk_var i tfo_id n ]

(* The transformation matrix for wc is from:

   Chandrasekaran R. et al (1989) A Re-Examination of the Crystal
   Structure of A-DNA Using Fiber Diffraction Data. J. Biomol.
   Struct. & Dynamics 6(6):1189-1202.
*)

let wc_dumas_tfo =
  { a = -0.9737
  ; b = -0.1834
  ; c = 0.1352
  ; d = -0.1779
  ; e = 0.2417
  ; f = -0.9539
  ; g = 0.1422
  ; h = -0.9529
  ; i = -0.2679
  ; tx = 0.4837
  ; ty = 6.2649
  ; tz = 8.0285
  }

let wc_dumas nucl i j partial_inst =
  [ mk_var i (dgf_base wc_dumas_tfo (get_var j partial_inst) nucl) nucl ]

let helix5'_tfo =
  { a = 0.9886
  ; b = -0.0961
  ; c = 0.1156
  ; d = 0.1424
  ; e = 0.8452
  ; f = -0.5152
  ; g = -0.0482
  ; h = 0.5258
  ; i = 0.8492
  ; tx = -3.8737
  ; ty = 0.5480
  ; tz = 3.8024
  }

let helix5' nucl i j partial_inst =
  [ mk_var i (dgf_base helix5'_tfo (get_var j partial_inst) nucl) nucl ]

let helix3'_tfo =
  { a = 0.9886
  ; b = 0.1424
  ; c = -0.0482
  ; d = -0.0961
  ; e = 0.8452
  ; f = 0.5258
  ; g = 0.1156
  ; h = -0.5152
  ; i = 0.8492
  ; tx = 3.4426
  ; ty = 2.0474
  ; tz = -3.7042
  }

let helix3' nucl i j partial_inst =
  [ mk_var i (dgf_base helix3'_tfo (get_var j partial_inst) nucl) nucl ]

let g37_a38_tfo =
  { a = 0.9991
  ; b = 0.0164
  ; c = -0.0387
  ; d = -0.0375
  ; e = 0.7616
  ; f = -0.6470
  ; g = 0.0189
  ; h = 0.6478
  ; i = 0.7615
  ; tx = -3.3018
  ; ty = 0.9975
  ; tz = 2.5585
  }

let g37_a38 nucl i j partial_inst =
  mk_var i (dgf_base g37_a38_tfo (get_var j partial_inst) nucl) nucl

let stacked5' nucl i j partial_inst =
  g37_a38 nucl i j partial_inst :: helix5' nucl i j partial_inst

let p_o3' nucls i j partial_inst =
  let refnuc = get_var j partial_inst in
  let align =
    tfo_inv_ortho
      (tfo_align
         (atom_pos nuc_O3' refnuc)
         (atom_pos nuc_C3' refnuc)
         (atom_pos nuc_C4' refnuc))
  in
  let rec generate domains = function
    | [] -> domains
    | n :: ns ->
        generate
          (mk_var i (tfo_combine (nuc_p_o3'_60_tfo n) align) n
          :: mk_var i (tfo_combine (nuc_p_o3'_180_tfo n) align) n
          :: mk_var i (tfo_combine (nuc_p_o3'_275_tfo n) align) n
          :: domains)
          ns
  in
  generate [] nucls

(* -- PROBLEM STATEMENT -----------------------------------------------------*)

(* Define anticodon problem -- Science 253:1255 Figure 3a, 3b and 3c *)

[@@ocamlformat "disable"]

(* Anticodon constraint *)

(* Define pseudoknot problem -- Science 253:1255 Figure 4a and 4b *)

let pseudoknot_domains =
  [ reference rA 23
  ; wc_dumas rU 8 23
  ; helix3' rG 22 23
  ; wc_dumas rC 9 22
  ; helix3' rG 21 22
  ; wc_dumas rC 10 21
  ; helix3' rC 20 21
  ; wc_dumas rG 11 20
  ; helix3' rU' 19 20 (* <-.               *)
  ; wc_dumas rA 12 19 (*   | Distance      *)
    (*                     | Constraint    *)
    (*  Helix 1            | 4.0 Angstroms *)
  ; helix3' rC 3 19   (*   |               *)
  ; wc_dumas rG 13 3  (*   |               *)
  ; helix3' rC 2 3    (*   |               *)
  ; wc_dumas rG 14 2  (*   |               *)
  ; helix3' rC 1 2    (*   |               *)
  ; wc_dumas rG' 15 1 (*   |               *)
    (*                     |               *)
    (*  L2 LOOP            |               *)
  ; p_o3' rUs 16 15   (*   |               *)
  ; p_o3' rCs 17 16   (*   |               *)
  ; p_o3' rAs 18 17   (* <-'               *) 
    (*                                     *)
    (*  L1 LOOP                            *)
  ; helix3' rU 7 8    (* <-.               *)
  ; p_o3' rCs 4 3     (*   | Constraint    *)
  ; stacked5' rU 5 4  (*   | 4.5 Angstroms *)
  ; stacked5' rC 6 5  (* <-'               *)
  ]
[@@ocamlformat "disable"]

(* Pseudoknot constraint *)

let pseudoknot_constraint v partial_inst =
  let dist j =
    let p = atom_pos nuc_P (get_var j partial_inst) in
    let o3' = atom_pos nuc_O3' v in
    pt_dist p o3'
  in
  if v.id = 18 then dist 19 <= 4.0 else if v.id = 6 then dist 7 <= 4.5 else true

let pseudoknot () = search [] pseudoknot_domains pseudoknot_constraint

(* -- TESTING ---------------------------------------------------------------*)

let list_of_atoms = function
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , A (n6, n7, n9, c8, h2, h61, h62, h8) ) ->
      [| p
       ; o1p
       ; o2p
       ; o5'
       ; c5'
       ; h5'
       ; h5''
       ; c4'
       ; h4'
       ; o4'
       ; c1'
       ; h1'
       ; c2'
       ; h2''
       ; o2'
       ; h2'
       ; c3'
       ; h3'
       ; o3'
       ; n1
       ; n3
       ; c2
       ; c4
       ; c5
       ; c6
       ; n6
       ; n7
       ; n9
       ; c8
       ; h2
       ; h61
       ; h62
       ; h8
      |]
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , C (n4, o2, h41, h42, h5, h6) ) ->
      [| p
       ; o1p
       ; o2p
       ; o5'
       ; c5'
       ; h5'
       ; h5''
       ; c4'
       ; h4'
       ; o4'
       ; c1'
       ; h1'
       ; c2'
       ; h2''
       ; o2'
       ; h2'
       ; c3'
       ; h3'
       ; o3'
       ; n1
       ; n3
       ; c2
       ; c4
       ; c5
       ; c6
       ; n4
       ; o2
       ; h41
       ; h42
       ; h5
       ; h6
      |]
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , G (n2, n7, n9, c8, o6, h1, h21, h22, h8) ) ->
      [| p
       ; o1p
       ; o2p
       ; o5'
       ; c5'
       ; h5'
       ; h5''
       ; c4'
       ; h4'
       ; o4'
       ; c1'
       ; h1'
       ; c2'
       ; h2''
       ; o2'
       ; h2'
       ; c3'
       ; h3'
       ; o3'
       ; n1
       ; n3
       ; c2
       ; c4
       ; c5
       ; c6
       ; n2
       ; n7
       ; n9
       ; c8
       ; o6
       ; h1
       ; h21
       ; h22
       ; h8
      |]
  | N
      ( dgf_base_tfo
      , p_o3'_275_tfo
      , p_o3'_180_tfo
      , p_o3'_60_tfo
      , p
      , o1p
      , o2p
      , o5'
      , c5'
      , h5'
      , h5''
      , c4'
      , h4'
      , o4'
      , c1'
      , h1'
      , c2'
      , h2''
      , o2'
      , h2'
      , c3'
      , h3'
      , o3'
      , n1
      , n3
      , c2
      , c4
      , c5
      , c6
      , U (o2, o4, h3, h5, h6) ) ->
      [| p
       ; o1p
       ; o2p
       ; o5'
       ; c5'
       ; h5'
       ; h5''
       ; c4'
       ; h4'
       ; o4'
       ; c1'
       ; h1'
       ; c2'
       ; h2''
       ; o2'
       ; h2'
       ; c3'
       ; h3'
       ; o3'
       ; n1
       ; n3
       ; c2
       ; c4
       ; c5
       ; c6
       ; o2
       ; o4
       ; h3
       ; h5
       ; h6
      |]

let maximum = function
  | x :: xs ->
      let rec iter m = function
        | [] -> m
        | a :: b -> iter (if a > m then a else m) b
      in
      iter x xs
  | _ -> assert false

let var_most_distant_atom v =
  let atoms = list_of_atoms v.n in
  let max_dist = ref 0.0 in
  for i = 0 to pred (Array.length atoms) do
    let p = atoms.(i) in
    let distance =
      let pos = absolute_pos v p in
      sqrt ((pos.x * pos.x) + (pos.y * pos.y) + (pos.z * pos.z))
    in
    if distance > !max_dist then max_dist := distance
  done;
  !max_dist

let sol_most_distant_atom s = maximum (List.map var_most_distant_atom s)

let most_distant_atom sols = maximum (List.map sol_most_distant_atom sols)

let run () = most_distant_atom (pseudoknot ())

let main () =
  for _ = 1 to 50 do
    ignore (run ())
  done;
  assert (abs_float (run () -. 33.7976) < 0.0002)

(*
  Printf.printf "%.4f" (run ()); print_newline()
*)

let _ = main ()
