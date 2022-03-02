(executable (name stacks) (modes native byte) (modules stacks))

(alias (name buildbench) (deps stacks.exe))

(alias (name bytebench) (deps stacks.bc))
