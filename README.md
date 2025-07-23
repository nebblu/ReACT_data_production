# Nonlinear Boost Emulator for Modified Gravity and Dark Scattering Models

This package contains the data production pipeline and [Cosmopower](https://alessiospuriomancini.github.io/cosmopower/) emulation files required to create a nonlinear boost emulator specifically tailored for:

* **f(R) gravity**
* **Dark Scattering model**

The nonlinear boost is defined as:

$B(k, z) = R(k, z) \times \frac{P_{\text{pseudo}}(k, z)}{P_{\text{LCDM}}(k, z)}$

Both power spectra, $P_{\text{pseudo}}$ and $P_{\text{LCDM}}$, are computed using **[HMCode2020](https://github.com/alexander-mead/HMcode)** without baryonic feedback. The halo model reaction $R(k,z)$ is calculated using **[ReACT](https://github.com/nebblu/ACTio-ReACTio)**.

## Directory Structure

* `pipe_cosmopower_parallel`: Main data production pipeline directory.

* `codes`: Folder containing Boltzmann Solver and HMCode2020

* `cosmopower`: Folder containing files needed to train the emulator once boosts are produced. 

## Other relevant files 

* `pipe_cosmopower_parallel/parameters.dat`: Configuration file specifying:

  * Directories for your Boltzmann Solver, ReACT, and HMCode2020.
  * k-range and number of wave modes sampled logarithmically within the range.

* `pipe_cosmopower_parallel/params/cosmo.txt`: Contains the cosmological parameter sets to be sampled. Typically, around **400k cosmologies** are needed for adequate sampling, though the exact number is model and prior-dependent.

* `cosmopower/create_params.py`: Script to generate `cosmo.txt` using a Latin Hypercube sampling strategy.

## Running the Pipeline

The main execution script is:

```bash
pipe_cosmopower_parallel/run_cp_x.sh
```

This bash script:

* Calls the Boltzmann Solver (e.g., MGCAMB or CLASS), ReACT, and HMCode2020.
* Uses template files found in `pipe_cosmopower_parallel/templates`.
* Outputs boost files into the `data/` directory, labeled as `boost{I}.dat`.

You can try to run 

> ./run_cp_x.sh 1 1 1 1 

to run the first cosmology in the cosmo.txt file in the log in node as a test. 

## Dependencies

### HMCode2020 Installation

* Locate the source file provided in `codes`.
* Copy this file into your HMCode2020 source directory (`HMCode2020/src`).
* Install HMCode2020 following standard procedures. This modified file allows specifying specific redshifts directly via terminal commands.

### Boltzmann Solver Installation

* Install either **MGCAMB** or **CLASS** in the `codes` directory.

## Post-processing and Training

* **Post-processing scripts** located in `cosmopower/` convert the raw `boost{I}.dat` files into `.npz` files suitable for emulator training.
* Training script (`training_boost_x.py`) is available in the `cosmopower/` directory to train your nonlinear boost emulator using processed data.

## Cluster Submission

Batch scripts compatible with **SLURM** are included, facilitating easy submission and management of large-scale jobs on computational clusters.

## Citation 

If you use this code in a publication, make sure to cite the relevant code and theory papers, mainly: 

```
 @article{Cataneo:2018cic,
   author = "Cataneo, Matteo and Lombriser, Lucas and Heymans, Catherine and Mead, Alexander and Barreira, Alexandre and Bose, Sownak and Li, Baojiu",
    title = "{On the road to percent accuracy: non-linear reaction of the matter power spectrum to dark energy and modified gravity}",
     eprint = "1812.05594",
    archivePrefix = "arXiv",
    primaryClass = "astro-ph.CO",
    doi = "10.1093/mnras/stz1836",
    journal = "Mon. Not. Roy. Astron. Soc.",
    volume = "488",
    number = "2",
    pages = "2121--2142",
    year = "2019"
}
```



```
@article{Bose:2020wch,
    author = "Bose, Benjamin and Cataneo, Matteo and Tröster, Tilman and Xia, Qianli and Heymans, Catherine and Lombriser, Lucas",
    title = "{On the road to per-cent accuracy IV: ReACT -- computing the non-linear power spectrum beyond $\Lambda$CDM}",
    eprint = "2005.12184",
    archivePrefix = "arXiv",
    primaryClass = "astro-ph.CO",
    month = "5",
    year = "2020"
}
```


```
@article{Bose:2022vwi,
    author = "Bose, B. and Tsedrik, M. and Kennedy, J. and Lombriser, L. and Pourtsidou, A. and Taylor, A.",
    title = "{Fast and accurate predictions of the nonlinear matter power spectrum for general models of Dark Energy and Modified Gravity}",
    eprint = "2210.01094",
    archivePrefix = "arXiv",
    primaryClass = "astro-ph.CO",
    doi = "10.1093/mnras/stac3783",
    month = "10",
    year = "2022"
}
```

```
@article{spuriomancini2021,
         title={CosmoPower: emulating cosmological power spectra for accelerated Bayesian inference from next-generation surveys},
         author={{Spurio Mancini}, A. and {Piras}, D. and {Alsing}, J. and {Joachimi}, B. and {Hobson}, M.~P.},
         year={2021},
         eprint={2106.03846},
         archivePrefix={arXiv},
         primaryClass={astro-ph.CO}
         }
```

```
@article{Mead:2020vgs,
    author = {Mead, Alexander and Brieden, Samuel and Tr{\"o}ster, Tilman and Heymans, Catherine},
    title = "{hmcode-2020: improved modelling of non-linear cosmological power spectra with baryonic feedback}",
    eprint = "2009.01858",
    archivePrefix = "arXiv",
    primaryClass = "astro-ph.CO",
    doi = "10.1093/mnras/stab082",
    journal = "Mon. Not. Roy. Astron. Soc.",
    volume = "502",
    number = "1",
    pages = "1401--1422",
    year = "2021"
}
```
---

Ensure all necessary dependencies are correctly installed and configured before running the pipeline. For further assistance or questions, consult the included scripts and files, or reach out to the maintainers of this package.
