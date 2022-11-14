let tokenRanges f b =
  let n = Bytes.length b in
  let check i =
    if (i = n) then not (f(Bytes.get b (n-1)))
    else if (i = 0) then not (f(Bytes.get b 0))
    else
    let i1 = f (Bytes.get b i) in
    let i2 = f (Bytes.get b (i-1)) in
    (i1 && not i2) || (i2 && not i1)
  in
  let ids = Seqbasis.filter 5000 (0, n+1) (fun i -> i) check in
  let count = (Array.length ids) / 2 in
  (count, fun i -> (ids.(2*i), ids.(2*i+1)))

let tokensSeq _ _ = raise (Failure "Tokenize.tokensSeq not implemented yet")

(*
fun tokensSeq f s =
  let
    val (n, g) = tokenRanges f s
    fun token i =
      let
        val (lo, hi) = g i
      in
        Seq.subseq s (lo, hi-lo)
      end
  in
    Seq.tabulate token n
  end
*)

let tokens f b =
  let (n, g) = tokenRanges f b in
  let token i =
    let (lo, hi) = g i in
    Bytes.sub_string b lo (hi-lo)
  in
  let result = Seq.full (Seqbasis.tabulate 1024 (0, n) token) in
  result
