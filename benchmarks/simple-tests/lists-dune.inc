(executable (name lists) (modes native byte) (modules lists))

(alias (name buildbench) (deps lists.exe))

(alias (name bytebench) (deps lists.bc))
