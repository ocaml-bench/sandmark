let hash64 u =
  let v = u in
  let v = Int64.add (Int64.mul v 3935559000370003845L) 2691343689449507681L in
  let v = Int64.logxor v (Int64.shift_right_logical v 21) in
  let v = Int64.logxor v (Int64.shift_left v 37) in
  let v = Int64.logxor v (Int64.shift_right_logical v 4) in
  let v = Int64.mul v 4768777513237032717L in
  let v = Int64.logxor v (Int64.shift_left v 20) in
  let v = Int64.logxor v (Int64.shift_right_logical v 41) in
  let v = Int64.logxor v (Int64.shift_left v 5) in
  v


let ceilDiv n k = 1 + (n-1) / k
