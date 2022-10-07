let _ = 
    let samples = Array.init nsamples (fun _ -> SparseGraphSeq.get_sample graph) in
    FileHandler.to_file ~filename:!filename samples
