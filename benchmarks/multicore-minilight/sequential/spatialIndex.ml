(*------------------------------------------------------------------------------

   MiniLight OCaml : minimal global illumination renderer
   Copyright (c) 2006-2008, Harrison Ainsworth / HXA7241.

   http://www.hxa7241.org/

------------------------------------------------------------------------------*)




open Vector3f




(**
 * A minimal spatial index for ray tracing.
 *
 * Suitable for a scale of 1 metre == 1 numerical unit, and has a resolution of
 * 1 millimetre. (Implementation uses fixed tolerances)
 *
 * @implementation
 * Octree: axis-aligned, cubical. Subcells are numbered thusly:
 * <pre>      110---111
 *            /|    /|
 *         010---011 |
 *    y z   | 100-|-101
 *    |/    |/    | /
 *    .-x  000---001      </pre>
 *
 * Each cell stores its bound: fatter data, but simpler code.
 *
 * Calculations for building and tracing are absolute rather than incremental --
 * so quite numerically solid. Uses tolerances in: bounding triangles (in
 * Triangle.obj#bound), and checking intersection is inside cell (both effective
 * for axis-aligned items). Also, depth is constrained to an absolute subcell
 * size (easy way to handle overlapping items).
 *
 * @invariants
 * - node.bound has length 6
 * - node.bound.(0-2) <= node.bound.(3-5)
 * - SubCells has length 8
 *)


(* types -------------------------------------------------------------------- *)
type nArray = SubCells of t array | Items of Triangle.obj array
and  node   = { bound: float array;  subparts: nArray }
and  t      = Node of node | Empty


(* constants ---------------------------------------------------------------- *)
(* accommodates scene including sun and earth, down to cm cells
   (use 47 for mm) *)
let maxLevels_k = 44
and maxItems_k  =  8




(* construction ------------------------------------------------------------- *)
(**
 * Internal constructor.
 *
 * @param bound (6 float array)
 * @param items (Triangle.Obj list)
 * @param level (int)
 *
 * @return (SpatialIndex.node)
 *)
let rec construct bound items level =

   (* if items overflow leaf and tree not too deep --
      make branch: make subcells, and recurse construction *)
   if (List.length items > maxItems_k) && (level < (maxLevels_k - 1)) then

      let q1 = ref 0 in
      (* define subcell maker *)
      let makeSubcell subcellIndex =

         (* make subcell bound *)
         let subBound = Array.init 6 (fun i -> let m = i mod 3 in
            if (((subcellIndex lsr m) land 1) lxor (i / 3)) <> 0 then
               (bound.(m) +. bound.(m + 3)) *. 0.5 else bound.(i)) in

         (* collect items that overlap subcell *)
         let subItems =
            let isOverlap item = let itemBound = item#bound in
               (* must overlap in all dimensions *)
               let all = ref 1 in
               for j = 0 to 5 do
                  let d, m = j / 3, j mod 3 in
                  all := !all land ((if itemBound.(d lxor 1).(m) >=
                     subBound.(j) then 1 else 0) lxor d) ;
               done ;
               !all = 1 in
            List.filter isOverlap items in

         (* curtail degenerate subdivision by adjusting next level
            (degenerate if two or more subcells copy entire contents of parent,
            or if subdivision reaches below mm size)
            (having a model including the sun requires one subcell copying
            entire contents of parent to be allowed) *)
         q1 := !q1 + if List.length subItems = List.length items then 1 else 0 ;
         let q2  = (subBound.(3) -. subBound.(0)) <
            (Triangle.tolerance_k *. 4.0) in

         (* recurse *)
         if List.length subItems > 0 then Node (construct subBound subItems
            (if (!q1 > 1) || q2 then maxLevels_k else level + 1)) else Empty in

      (* make subcells *)
      { bound= bound;  subparts= SubCells (Array.init 8 makeSubcell) }

   (* make leaf: store items, and end recursion *)
   else
      (* (make sure to trim any reserve capacity) *)
      { bound= bound;  subparts= Items (Array.of_list items) }


(**
 * @param eyePosition (Vector3f.vT)
 * @param items       (Triangle.Obj list)
 *
 * @return (SpatialIndex.t)
 *)
let create eyePosition items =

   (* make overall bound *)
   let bound =
      (* accommodate all items, and eye position (makes tracing algorithm
         simpler) *)
      let rectBound = let encompass rb item = let ib = item#bound in
            [| vZip min rb.(0) ib.(0);  vZip max rb.(1) ib.(1) |] in
         List.fold_left encompass [| eyePosition; eyePosition |] items in

      (* make cubical *)
      let maxSize = vFold max (rectBound.(1) -| rectBound.(0)) in
      [| rectBound.(0);
         vZip max rectBound.(1) (rectBound.(0) +| (vOne *|. maxSize)) |] in

   (* delegate to recursive constructor *)
   Node (construct (Array.append bound.(0) bound.(1)) items 0)




(* queries ------------------------------------------------------------------ *)
(** Find nearest intersection of ray with item.
 *
 * @param octree       (SpatialIndex.t)
 * @param rayOrigin    (Vector3f.vT)
 * @param rayDirection (Vector3f.vT)
 * @param start        (Vector3f.vT) traversal position
 * @param lastHit      (Triangle.var) previous intersected item
 *
 * @return (Triangle.var, Vector3f.vT) object|null hit, and hit position
 *)
let rec intersection octree rayOrigin rayDirection ?(start = rayOrigin)
   lastHit =

   match octree with

   (* is branch: step through subcells and recurse *)
   | Node { bound= bound; subparts= SubCells subCells } ->

      (* find which subcell holds ray origin (ray origin is inside cell) *)
      let subCell = let bit i =
         (* compare dimension with center *)
         if start.(i) >= ((bound.(i) +. bound.(i + 3)) *. 0.5) then
            1 lsl i else 0 in
         (bit 0) lor (bit 1) lor (bit 2) in

      (* define subcell walker *)
      let rec walk subCell cellPosition =

         (* intersect subcell *)
         match intersection subCells.(subCell) rayOrigin rayDirection
            ~start:(cellPosition) lastHit with

         (* no hit, so continue walking across subcells *)
         | None ->

            (* find next subcell ray moves to
               (by finding which face of the corner ahead is crossed first) *)
            let step, axis, _ = let findNext (step, axis, i) =
               let high = (subCell lsr i) land 1 in
               let face = if ((if (rayDirection.(i) < 0.0) then 1 else 0) lxor
                  high) <> 0 then
                     bound.(i + (high * 3))
                  else
                     (bound.(i) +. bound.(i + 3)) *. 0.5 in
               let distance = (face -. rayOrigin.(i)) /. rayDirection.(i) in
               if distance <= step then
                  (distance, i, i + 1) else (step, axis, i + 1) in

               findNext (findNext (findNext (max_float, 0, 0))) in

            (* leaving branch if: direction is negative and subcell is low,
               or direction is positive and subcell is high *)
            if ((if (rayDirection.(axis) < 0.0) then 1 else 0) lxor
               ((subCell lsr axis) land 1)) = 1 then
               None
            else
               (* move to (outer face of) next subcell *)
               walk (subCell lxor (1 lsl axis)) (rayOrigin +| (rayDirection *|.
                  step))

         (* hit, so exit *)
         | Some _ as hit -> hit in

      (* step through intersected subcells *)
      walk subCell start

   (* is leaf: exhaustively intersect contained items *)
   | Node { bound= bound; subparts= Items items } ->

      (* define nearest-finder *)
      let findNearest nearest item = match lastHit with
         (* avoid false intersection with surface just come from *)
          Some it when it == item -> nearest
        | _ ->
            let _, _, nearestDistance = nearest in

            (* intersect item and inspect if nearest so far *)
            match item#intersection rayOrigin rayDirection with
                Some distance when distance < nearestDistance ->
                  let hit = rayOrigin +| (rayDirection *|. distance) in

                  (* check intersection is inside cell bound (with tolerance) *)
                  let t = Triangle.tolerance_k in
                    if (bound.(0) -. hit.(0) > t) || (hit.(0) -. bound.(3) > t) ||
                       (bound.(1) -. hit.(1) > t) || (hit.(1) -. bound.(4) > t) ||
                       (bound.(2) -. hit.(2) > t) || (hit.(2) -. bound.(5) > t)
                    then nearest
                    else (Some item, hit, distance)
              | _ -> nearest

      (* apply nearest-finder to items list *)
      in (match Array.fold_left findNearest (None, vZero, infinity) items with
              Some hitObject, hitPosition, _ -> Some (hitObject, hitPosition)
            | None, _, _ -> None)

   (* is empty: no intersection *)
   | Empty -> None
