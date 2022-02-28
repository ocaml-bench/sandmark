(executable (name lazylist) (modes native byte) (modules lazylist))
(executable (name lazy_primes) (modes native byte) (modules lazy_primes))

(alias (name buildbench) (deps lazylist.exe lazy_primes.exe))

(alias (name bytebench) (deps lazylist.bc))
