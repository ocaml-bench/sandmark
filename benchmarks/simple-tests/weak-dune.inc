(executable (name weakretain) (modes native byte) (modules weakretain))
; (executable (name weak_htbl) (modules weak_htbl))

;(alias (name buildbench) (deps weakretain.exe weak_htbl.exe))
(alias (name buildbench) (deps weakretain.exe))

(alias (name bytebench) (deps weakretain.bc))
