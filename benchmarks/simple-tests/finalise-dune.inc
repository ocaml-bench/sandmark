(executable (name finalise) (modes native byte) (modules finalise))

(alias (name buildbench) (deps finalise.exe))

(alias (name bytebench) (deps finalise.bc))
