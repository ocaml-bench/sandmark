open Owl

let size = try int_of_string Sys.argv.(1) with _ -> 2048

let () = 
    let a = Mat.sequential size size in 
    Mat.(a * a)
