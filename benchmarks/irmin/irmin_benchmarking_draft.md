##Benchmarking Irmin

####Rough Draft on how to go about

* Merging 2 text files
  * Start with 2 considerably large files and try to merge them.
  * To create files which has some control over the variations in the way text are generated one needs a random text generator Right now it would be using just a large text in a variable
  * The degree of how different the documents are, variations in the differences between the files can be accounted to test the merging capabilities.
  * To create the merging benchmark we'll start off with `custom_merge.ml` example inside the `examples` folder. 

  ***


* Benchmarking the merge function
  * To benchmark the function go through the [blogpost](https://github.com/prismlab/docs/wiki/Adding-a-benchmark-to-Sandmark) created in the prismlab github repo.