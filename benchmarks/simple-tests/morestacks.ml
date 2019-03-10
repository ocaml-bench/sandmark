let bar n =
    n + 5

let foo () = for a = 0 to 1_000_000 do
        ignore(bar a)
    done

let () = for _ = 0 to 10_000 do
        foo()
    done