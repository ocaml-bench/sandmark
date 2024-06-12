module AS = CCArray
module A = Array

let swap (arr : 'a AS.t) (i : int) (j : int) =
  let temp = AS.get arr i in
  AS.set arr i (AS.get arr j);
  AS.set arr j temp

let insert_sort (f : 'a -> 'a -> int) (arr : 'a AS.t) (start : int) (n : int) =
  for i = start to n - 2 do
    for j = i + 1 to n - 1 do
      if f (AS.get arr j) (AS.get arr i) < 0
      then swap arr i j
      else ()
    done
  done

let partition (f : 'a -> 'a -> int) (arr : 'a AS.t) (low : int) (high : int) =
  let x = (AS.get arr high) and  i = ref (low-1) in
  if (high-low > 0) then
    begin
      for j= low to high - 1 do
        if f (AS.get arr j) x <= 0 then
          begin
            i := !i+1;
            swap arr !i j
          end
      done
    end;
  swap arr (!i+1) high;
  !i+1

let rec quicksort (f : 'a -> 'a -> int) (arr : 'a AS.t) (low : int) (high : int) : unit =
  if (high - low) <= 0 then ()
  (* else if (high - low) <= 8
   * then insert_sort f arr low (high+1) *)
  else
    let q = partition f arr low high in
    quicksort f arr low (q-1);
    quicksort f arr (q+1) high

let sortInPlace (f : 'a -> 'a -> int) (arr : 'a AS.t) : unit =
  quicksort f arr 0 (AS.length arr - 1)

let sort (f : 'a -> 'a -> int) (arr : 'a array) : 'a array =
  let result = A.copy arr in
  quicksort f (A.fill result) 0 (A.length arr - 1) ;
  result