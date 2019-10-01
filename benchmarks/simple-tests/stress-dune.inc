(executable (name stress) (modules stress))

(alias (name buildbench) (deps stress.exe))
