open Owl

let size = 2048

let _ = 
    let a = Mat.sequential size size in 
    Mat.(a * a);;
