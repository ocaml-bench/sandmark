val tokenRanges: (char -> bool) -> Bytes.t -> int * (int -> (int * int))
val tokensSeq: (char -> bool) -> Bytes.t -> (char Seq.t) Seq.t
val tokens: (char -> bool) -> Bytes.t -> string Seq.t
