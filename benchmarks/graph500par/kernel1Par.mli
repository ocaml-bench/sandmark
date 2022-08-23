open GraphTypes

module T = Domainslib.Task

val kernel1 : pool:T.pool -> edge array -> SparseGraph.t

val max_vertex_label : pool:T.pool -> edge array -> vertex
