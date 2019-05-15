(* The Computer Language Benchmarks Game
 * https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

   contributed by Ingo Bormuth <ibormuth@efil.de>
*)

open Bytes

let () =
  let t, b, bi = make 256 ' ', make 61 '\n', ref 1 in
  blit_string "TVGHEFCDIJMLKNOPQYSAABWXRZ" 0 t 65 26;
  blit t 65 t 97 26;

  let rec rd ls =
    let l, q = try input_line stdin, false with _ -> "", true in
    if l <> "" && l.[0] <> '>' then rd (l::ls)
    else (
      let rec wr = function
        s::ss ->
            for si = String.length s - 1 downto 0 do
              Bytes.set b !bi (Bytes.get t (Char.code s.[si]));
              if !bi<60 then bi:=!bi+1 else ( print_bytes b; bi:=1 )
            done;
            wr ss
        | [] ->
            if !bi>1 then output stdout b 0 !bi;
            bi:=1 in
      wr ls;
      print_string ( if ls<>[] then ("\n"^l) else l );
      if not q then rd [];
    ) in
  rd []
