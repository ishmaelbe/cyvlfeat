# distutils: language = c
# Copyright (C) 2007-12 Andrea Vedaldi and Brian Fulkerson.
# All rights reserved.

# This file is modified from part of the VLFeat library and is made available
# under the terms of the BSD license.
import numpy as np
import ctypes
cimport numpy as np
cimport cython

# Import the header files
from cyvlfeat._vl.host cimport VL_TYPE_FLOAT
from cyvlfeat._vl.host cimport vl_size
from cyvlfeat._vl.fisher cimport vl_fisher_encode
from cyvlfeat._vl.fisher cimport VL_FISHER_FLAG_NORMALIZED
from cyvlfeat._vl.fisher cimport VL_FISHER_FLAG_SQUARE_ROOT
from cyvlfeat._vl.fisher cimport VL_FISHER_FLAG_IMPROVED
from cyvlfeat._vl.fisher cimport VL_FISHER_FLAG_FAST

@cython.boundscheck(False)
cpdef cy_fisher(float[:, :] X,
                float[:, :] MEANS,
                float[:, :] COVARIANCES,
                float[:] PRIORS,
                bint normalized,
                bint square_root,
                bint improved,
                bint fast,
                bint verbose):

    cdef:
        vl_size numClusters = MEANS.shape[1]
        vl_size dimension = MEANS.shape[0]
        vl_size numData = X.shape[1]
        int flags = 0

    if normalized:
        flags |= VL_FISHER_FLAG_NORMALIZED
    
    if square_root:
        flags |= VL_FISHER_FLAG_SQUARE_ROOT
        
    if improved:
        flags |= VL_FISHER_FLAG_IMPROVED
        
    if fast:
        flags |= VL_FISHER_FLAG_FAST
    
    if verbose:
        print('vl_fisher: num data:       {}\n'
              'vl_fisher: num clusters:   {}\n'
              'vl_fisher: data dimension: {}\n'
              'vl_fisher: code dimension: {}\n'
              'vl_fisher: square root:    {}\n'
              'vl_fisher: normalized:     {}\n'
              'vl_fisher: fast:           {}'.format(
            numData, numClusters, dimension, 2 * numClusters * dimension,
            square_root, normalized, fast))

    cdef float[:] enc = np.zeros((2*numClusters*dimension,),
                                 dtype=np.float32)

    cdef int numTerms = vl_fisher_encode(&enc[0],
                                         VL_TYPE_FLOAT,
                                         &MEANS[0, 0],
                                         dimension,
                                         numClusters,
                                         &COVARIANCES[0, 0],
                                         &PRIORS[0],
                                         &X[0, 0],
                                         numData,
                                         flags)

    if verbose:
        print('vl_fisher: sparsity of assignments: {:.2f}% '
              '({} non-negligible assignments)'.format(
            100.0 * (1.0 - <float>numTerms / (numData * numClusters + 1e-12)),
            numTerms))

    return np.asarray(enc)
