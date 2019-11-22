type 'a t =
  { head: int Atomic.t
  ; (* this won't end well on 32-bit platforms *)
    _pad0: int
  ; _pad1: int
  ; _pad2: int
  ; _pad3: int
  ; _pad4: int
  ; _pad5: int
  ; _pad6: int
  ; buffer: 'a option array
  ; _pad7: int
  ; _pad8: int
  ; _pad9: int
  ; _pad10: int
  ; _pad11: int
  ; _pad12: int
  ; _pad13: int
  ; tail: int Atomic.t (* ditto *) }

let create length =
  { head= Atomic.make 0
  ; _pad0= 0
  ; _pad1= 1
  ; _pad2= 2
  ; _pad3= 3
  ; _pad4= 4
  ; _pad5= 5
  ; _pad6= 6
  ; buffer= Array.make length None
  ; _pad7= 7
  ; _pad8= 8
  ; _pad9= 9
  ; _pad10= 10
  ; _pad11= 11
  ; _pad12= 12
  ; _pad13= 13
  ; tail= Atomic.make 0 }

let enqueue t a =
  let current_tail = Atomic.get t.tail in
  let buffer_length = Array.length t.buffer in
  let wrap_point = current_tail - buffer_length in
  if Atomic.get t.head <= wrap_point then false
  else
    let pos = current_tail mod buffer_length in
    t.buffer.(pos) <- Some a ;
    Atomic.set t.tail (current_tail + 1) ;
    (* This should do a StoreStore fence, which means the previous buffer set is safe *)
    true

let dequeue t =
  let current_head = Atomic.get t.head in
  if current_head >= Atomic.get t.tail then None
  else
    let buffer_length = Array.length t.buffer in
    let index = current_head mod buffer_length in
    let item = t.buffer.(index) in
    t.buffer.(index) <- None ;
    Atomic.set t.head (current_head + 1) ;
    (* See previous note about safety *)
    item
