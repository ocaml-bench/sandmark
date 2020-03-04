(executable (name lazylist) (modules lazylist))
(executable (name lazy_primes) (modules lazy_primes))

(alias (name buildbench) (deps lazylist.exe lazy_primes.exe))
