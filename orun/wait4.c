#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <sys/errno.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>

int caml_rev_convert_signal_number (int);

static value float_of_timeval(struct timeval t)
{
  double d = t.tv_sec;
  d *= 1000000;
  d += t.tv_usec;
  d /= 1000000;
  return caml_copy_double(d);
}

value ml_wait4(value pid)
{
  CAMLparam1(pid);
  CAMLlocal2(st, usg);
  int wstatus;
  struct rusage usage;

  if (wait4(Long_val(pid), &wstatus, 0, &usage) < 0) {
    caml_failwith("wait4 failed");
  }

  if (WIFEXITED(wstatus)) {
    st = caml_alloc_small(1, 0);
    Field(st, 0) = Val_int(WEXITSTATUS(wstatus));
  } else if (WIFSTOPPED(wstatus)) {
    caml_failwith("WSTOPPED without WUNTRACED?");
  } else {
    st = caml_alloc_small(1, 1);
    Field(st, 0) = Val_int(caml_rev_convert_signal_number(WTERMSIG(wstatus)));
  }

  usg = caml_alloc(4, 0);
  caml_initialize(&Field(usg, 0), st);
  caml_initialize(&Field(usg, 1), float_of_timeval(usage.ru_utime));
  caml_initialize(&Field(usg, 2), float_of_timeval(usage.ru_stime));
  caml_initialize(&Field(usg, 3), Val_long(usage.ru_maxrss));

  CAMLreturn (usg);
}
