#include <stdio.h>
#include <caml/mlvalues.h>

CAMLprim value
test_no_args_alloc(value unit)
{
    return Int_val(42);
}