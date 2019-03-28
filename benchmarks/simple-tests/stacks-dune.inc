(executable (name stacks) (modules stacks))

(rule
         (targets stacks.100000.ints-small.bench)
          (deps (:prog stacks.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 ints-small)))
(rule
         (targets stacks.20000.ints-large.bench)
          (deps (:prog stacks.exe))
           (action (run orun -o %{targets} -- %{prog} 20000 ints-large)))
(rule
         (targets stacks.100000.floats-small.bench)
          (deps (:prog stacks.exe))
           (action (run orun -o %{targets} -- %{prog} 100000 floats-small)))
(rule
         (targets stacks.20000.floats-large.bench)
          (deps (:prog stacks.exe))
           (action (run orun -o %{targets} -- %{prog} 20000 floats-large)))

(alias (name bench) (deps stacks.100000.ints-small.bench stacks.20000.ints-large.bench stacks.100000.floats-small.bench stacks.20000.floats-large.bench))
