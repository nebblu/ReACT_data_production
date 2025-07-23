#!/usr/bin/env/python

# Author: A. Spurio Mancini


import numpy as np
import pyDOE as pyDOE

# number of parameters and samples

n_params           = 10
n_samples          = 40000

# parameter ranges

Omega_m            =   np.linspace(0.24,     0.35,       n_samples)
Omega_b            =   np.linspace(0.04,    0.06,      n_samples)
Omega_nu           =   np.linspace(0.00015,  0.00317,   n_samples)
H0                 =   np.linspace(63,      84,      n_samples)
ns                 =   np.linspace(0.8,     1.1,       n_samples)
As                 =   np.linspace(1.9e-9,  2.5e-9,    n_samples)
w0                =   np.linspace(-1.3, -0.7, n_samples)
wa                =   np.linspace(-0.5,0.5, n_samples)
xi                =   np.linspace(0,30, n_samples)
z                  =   np.linspace(0.,         2.5,   n_samples)

# LHS grid

AllParams          = np.vstack([Omega_m, Omega_b, Omega_nu, H0, ns, As, w0, wa, xi, z])
lhd                = pyDOE.lhs(n_params, samples=n_samples, criterion=None)
idx                = (lhd * n_samples).astype(int)

AllCombinations = np.zeros((n_samples, n_params))
for i in range(n_params):
    AllCombinations[:, i] = AllParams[i][idx[:, i]]

print(AllCombinations)

AllCombinations = np.hstack([np.arange(n_samples).reshape((-1,1)), AllCombinations])

# saving

np.savetxt('cosmo_validation.txt', AllCombinations)
