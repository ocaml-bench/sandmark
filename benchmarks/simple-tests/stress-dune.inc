(executable (name stress) (modes native byte) (modules stress))

(alias (name buildbench) (deps stress.exe))

(alias (name bytebench) (deps stress.bc))
