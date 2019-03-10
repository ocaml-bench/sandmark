external test_no_args_alloc : unit -> int = "test_no_args_alloc"
external test_no_args_noalloc : unit -> int = "test_no_args_no_alloc" [@@noalloc]
external test_few_args_alloc : int -> int = "test_few_args_alloc"
external test_few_args_noalloc : int -> int = "test_few_args_no_alloc" [@@noalloc]
external test_many_args_alloc : int -> int -> int -> int -> int -> int -> int -> int = "test_many_args_noalloc_bc" "test_many_args_alloc_nc"
external test_many_args_noalloc : int -> int -> int -> int -> int -> int -> int -> int = "test_many_args_noalloc_bc" "test_many_args_noalloc_nc" [@@noalloc]
