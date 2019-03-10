#include <stdio.h>
#include <caml/mlvalues.h>

CAMLprim value
test_no_args_alloc(value unit)
{
    return Int_val(42);
}

CAMLprim value test_no_args_no_alloc(value unit)
{
    return Int_val(42);
}

CAMLprim value test_few_args_alloc(value input) {
    return Int_val(42);
}

CAMLprim value test_few_args_no_alloc(value input) {
    return Int_val(42);
}

CAMLprim value test_many_args_alloc_nc(value one, value two, value three, value four, value five, value six, value seven) {
    return Int_val(42);
}

CAMLprim value test_many_args_noalloc_nc(value one, value two, value three, value four, value five, value six, value seven) {
    return Int_val(42);
}

