(executable (name finalise) (modules finalise))

(alias (name buildbench) (deps finalise.exe))
