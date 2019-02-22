# Stand-alone programs for numerical analysis in OCaml

Sometimes you need a small code (that has no dependency to a huge or unfamiliar
library/tool) for scientific computing. In this repository, we distribute such
[OCaml](http://ocaml.org/) programs under MIT license (the copyright of each
data set belongs to the maker of the data).

## Linear algebra

- [LU decomposition](lu-decomposition/):
  [LU decomposition](http://en.wikipedia.org/wiki/LU_decomposition) is
  factorization such that `PA = LU` (or `A = PLU`) where `A` is a matrix, `L` is
  a lower trapezoidal matrix, `U` is a upper trapezoidal matrix, and `P` is
  a permutation matrix. LU decomposition is used for solving linear equations,
  computing determinant, etc. This code implements Crout's method.

  - Compilation: `ocamlopt lu.ml`

- [QR decomposition](qr-decomposition/):
  [QR decomposition](http://en.wikipedia.org/wiki/QR_decomposition) is
  to factorize square matrix `A` into `QR` where `Q` is an orthogonal matrix and
  `R` is a right triangular matrix (a.k.a., an upper triangular matrix). QR
  decomposition is used for solving linear equations, eigenproblems, etc. This
  code QR-decomposes a given square matrix by
  [Gram-Schmidt orthonormalization](http://en.wikipedia.org/wiki/Gram%E2%80%93Schmidt_process).
  If `A` is not full-rank, `Q` has zero vectors of the nullity of `A`.

  - Compilation: `ocamlopt qr.ml`

## Signal processing

- [Fast Fourier transform](fft/):
  This is an implementation of radix-2
  [Cooley-Tukey fast Fourier transform (FFT) algorithm](http://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm),
  the most famous method in FFT algorithms. The naive computation according to
  the definition of discrete Fourier transform (DFT) takes `O(n^2)` time where
  `n` is the number of input points, but this FFT algorithm takes only
  `O(n log n)` time. Input length `n` must be equal to `2^m` (where `m` is a
  natural number). Fourier transform is frequently used for signal analysis,
  data compression, etc.

  - Compilation: `ocamlopt fft.ml`

- [Autocorrelation & Levinson-Durbin recursion](levinson-durbin/):
  [Levinson-Durbin recursion](http://en.wikipedia.org/wiki/Levinson_recursion)
  is an algorithm to compute AR coefficients of
  [autoregressive (AR) model](http://en.wikipedia.org/wiki/Autoregressive_model).
  The most well-known application of AR model is
  [linear predictive coding (LPC)](http://en.wikipedia.org/wiki/Linear_predictive_coding),
  a classic analysis/coding/compression approach for voice. We decompose
  input voice into *glottal source* (buzz-like sound) and *vocal tract filter
  characteristics* (filter coefficients) by using Levinson-Durbin algorithm,
  and analyze or encode the two kinds of sound by different ways.
  LPC vocoder (voice coder) is applied to
  [FS-1015](http://en.wikipedia.org/wiki/FS-1015) (secure telephony speech
  encoding), [Shorten](http://en.wikipedia.org/wiki/Shorten_(file_format)),
  [MPEG-4 ALS](http://en.wikipedia.org/wiki/MPEG-4_ALS),
  [FLAC](http://en.wikipedia.org/wiki/FLAC) audio codec, etc. This program
  computes AR coefficients from time-domain sound and outputs them.

  - Compilation: `ocamlopt dataset.ml levinson.ml`
  - Data set: Japanese vowel sound /a/ (1957 points), /i/ (3439 points),
    /u/ (2644 points), /e/ (3316 points), /o/ (2793 points);
    sampling rate = 16000, original data is at
    http://www.gavo.t.u-tokyo.ac.jp/~mine/B3enshu2001/samples.html
  - AR order: 20

## Machine learning

### Classification

- [Naive multilayer neural network](neural-network/naive-multilayer):
  a neural network that has two or more layers can be used for nonlinear
  classification, regression, etc. in machine learning. This code is a very
  simple implementation of multilayer neural network. This neural network tends
  to fall into over-fitting. (In the past, multilayer neural networks are rarely
  applied for practical tasks because they have some problems such as
  [over-fitting](http://en.wikipedia.org/wiki/Overfitting) and
  [vanishing gradient](http://en.wikipedia.org/wiki/Vanishing_gradient_problem).
  After 2006, [Hinton](http://www.cs.toronto.edu/~hinton/) et al. proposed some
  epoch‐making approaches to solve the problems and accomplished surprisingly
  high performance. The newer techniques are also known as *deep learning*.)
  The following default setting is for classification. If you want to use this
  for regression, you should change the activation function of the output layer
  to a linear function, and the error function to sum of squared errors.

  - Compilation: `ocamlopt dataset.ml neuralNetwork.ml`
  - Data set: [Ionosphere (UCI Machine Learning Repository)](https://archive.ics.uci.edu/ml/datasets/Ionosphere)
    (\#features = 34, \#classes = 2)
  - Training: error backpropagation
    [[Rumelhard et al., 1986]](http://dl.acm.org/citation.cfm?id=104293) +
    stochastic gradient descent (with a constant learning rate)
  - Regularization: none
  - Error function: cross-entropy
  - Layers: 4 layers + the input layer (all neurons in each layer are connected
    with all neurons in the lower layer.
  - The 1st hidden layer: 10 units, activation function = tanh
  - The 2nd hidden layer: 5 units, activation function = tanh
  - The output layer: 2 units (binary classification, 1-of-K coding),
    activation function = softmax

### Clustering

- [K-means](k-means/):
  This program implements a classic clustering approach
  [K-means](http://en.wikipedia.org/wiki/K-means_clustering).

  - Compilation: `ocamlopt dataset.ml kmeans.ml`
  - Data set: artificially generated according to three kinds of Gaussian
    distribution (dimension = 2, \#classes = 3, \#points of each class = 100)

    ![The distribution of data points](k-means/dataset.png)

## Miscellaneous

- [Durand-Kerner-Aberth method](durand-kerner-aberth/):
  [Durand-Kerner method](http://en.wikipedia.org/wiki/Durand%E2%80%93Kerner_method)
  is an algorithm to find all (complex) roots of a given polynominal at the same
  time, and [Aberth method](http://en.wikipedia.org/wiki/Aberth_method) is an
  approach to compute the initial values for Durand-Kerner method.

  - Compilation: `ocamlopt dka.ml`
