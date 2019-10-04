(executable (name stacks) (modules stacks))

(alias (name buildbench) (deps stacks.exe))
