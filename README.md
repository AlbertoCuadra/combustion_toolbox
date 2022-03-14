<p align="left">
    <img alt="UC3M" style="border-width:0" src="https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/GUI/Icons/logo.svg" width="1500"/></a>
</p>

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6353961.svg)](https://doi.org/10.5281/zenodo.6353961)
[![File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://es.mathworks.com/matlabcentral/fileexchange/101088-combustion-toolbox)
![repo size](https://img.shields.io/github/repo-size/AlbertoCuadra/combustion_toolbox)
![last modified](https://img.shields.io/github/last-commit/AlbertoCuadra/combustion_toolbox)
[![license](https://img.shields.io/github/license/AlbertoCuadra/combustion_toolbox)](https://www.gnu.org/licenses/gpl-3.0.html)

A MATLAB-GUI based open-source tool for solving gaseous combustion problems.

<!-- Website: https://combustiontoolbox.netlify.app/ -->
:top: There is also a (less complete) [Python version](https://github.com/AlbertoCuadra/Combustion-PyToolbox)

## Introduction
In this work, we present an in-house thermochemical code (hereafter Combustion Toolbox) that can be applied to gaseous combustion problems. The code stems from the minimization of the free energy of the system by using Lagrange multipliers combined with a Newton-Raphson method, upon condition that initial gas properties are defined by two functions of states (e.g., temperature and pressure). The kernel of the code is similar as NASA’s Chemical Equilibrium with Applications (CEA) code. The corresponding thermodynamic properties of the species are modelled with NASA’s 9-coefficient polynomial fits, which ranges up to 20000 K, and the ideal gas equation of state. When temperature is not externally imposed, which demands additional information about the thermodynamical process (typically, the conservation equations applied to the system) the code retrieves a routine based on the Steffensen-Aitken root-finding algorithm to find the equilibrium temperature. With this modelization Combustion Toolbox can be used to solve processes that involve strong changes in the dynamic pressure, such as detonations and shock waves in the steady state, by providing the corresponding Rankine-Hugoniot equations. For example, to compute the properties of strong shocks in hypersonic conditions, a phenomenon that involves changes in the molecular structure of the molecules, Combustion Toolbox can be used to find the equilibrium conditions of the different phenomena undergoing behind the shock: molecular vibrational excitation up to dissociation, and electronic excitation up to ionization, thereby providing the properties of the gas in plasma state within the temperature range given by the NASA’s 9-coefficient polynomial fits.
The tool has been equipped with a Graphical User Interface developed in MATLAB 2021 under AppDesigner in an architecturally modular format. A preview of the GUI is shown in Fig. 1 (a). The GUI has been successfully used for both teaching and research in Bachelor of Science and Master of Science over the last three years. Results have been contrasted with NASA’s CEA code, showing excellent agreement. An example of its capabilities are shown in Fig. 1 - Fig. 3. The code is available to the scientific community via Github and Zenodo, and new capabilities are under development: estimation of rocket propellant performance, and addition of non-ideal equations of state, e.g., Virial and BKW.


<!--
---
⚠️ **NOTE**
- At the moment, the Python version does not have all the capabilities that the MATLAB version has. I will continue with the development of this version adding all the remaining capabilities. I will also add a GUI using Qt6 and Pyside6.
---
-->

The code computes the equilibrium composition by minimization of the Gibbs–Helmholtz free energy by using Lagrange multipliers, and employs NASA’s 9-coefficient polynomial fits to evaluate the thermodynamic properties. Results computed with **Combustion Toolbox** have been validated against, and are in good agreement with, [NASA’s Chemical Equilibrium with Applications](https://cearun.grc.nasa.gov/) (CEA) program, [CANTERA](https://cantera.org/) and [Caltech’s Shock and Detonation Toolbox](https://shepherd.caltech.edu/EDL/PublicResources/sdt/). Along with the plain code, the new tool has been `equipped with a Graphical User Interface` developed in MATLAB 2021 under AppDesigner.

This project is also part of the PhD of [Alberto Cuadra-Lara](https://www.acuadralara.com/).

---
⚠️ **NOTE**

- The first final version v1.0.0 is expected to be released in April 2022. Check out the  upcoming features of [Combustion Toolbox v1.0.0](https://github.com/AlbertoCuadra/combustion_toolbox/projects/2).
- [Wiki](https://github.com/AlbertoCuadra/combustion_toolbox/wiki) under construction :building_construction:

---
## Start here!
The [tutorial](https://github.com/AlbertoCuadra/combustion_toolbox/wiki/Tutorial) will help you get started using Combustion Toolbox on your pc.

## Gallery
We have several examples of what Combustion Toolbox can do. Here we show some results obtained from Combustion Toolbox and a preview of the GUI.

<p align="left">
    <img src="https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/Validations/Figures/Hugoniot_benchmarking.svg" width="400">
</p>
    
**Figure 1:** *Hugoniot curves for different molecular gases at pre-shock temperature T1 = 300 K and pressure p1 = 1 atm \[numerical results obtained with Combustion Toolbox (lines) and contrasted with NASA’s Chemical Equilibrium with Applications (CEA) code excluding ionization (symbols)\]*.
    
<p align="left">
    <img src="https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/Validations/Figures/validation_DET_CEA_3_molar.svg" width="1200">
</p>

**Figure 2:** *Example CJ detonation for lean to rich CH4-air mixtures at standard conditions: (a) variation of molar fraction, (b) variation of temperature. The computational time was of 12.70 seconds using a Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz for a set of 24 species considered and a total of 451 case studies.*

<p align="left">
    <img src="https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/GUI/Snapshots/snapshot_1.svg" width="500">
</p>

**Figure 3:** *Snapshot of the GUI*.

Figure 1 is postprocesed with [Veusz](https://github.com/veusz/veusz) and [Inkscape](https://inkscape.org/). 

## Contributing

Please read [CONTRIBUTING.md](https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

Please send feedback or inquiries to [acuadra@ing.uc3m.es](mailto:acuadra@ing.uc3m.es)

Thank you for testing Combustion Toolbox!

## Acknowledgements
Combustion Toolbox's color palette is obtained from the next repository:

Stephen (2021). ColorBrewer: Attractive and Distinctive Colormaps (https://github.com/DrosteEffect/BrewerMap), GitHub. Retrieved December 3, 2021.
## Developers

* **[Alberto Cuadra-Lara](https://acuadralara.com/)** - *Core Developer and App designer*
* **César Huete** - *Developer*
* **Marcos Vera** - *Developer*

Grupo de Mecánica de Fluidos, Universidad Carlos III, Av. Universidad 30, 28911, Leganés, Spain

See also the list of [contributors](https://github.com/AlbertoCuadra/combustion_toolbox/blob/master/CONTRIBUTORS.md) who participated in this project.

## Citing Combustion Toolbox

```bibtex
@misc{combustiontoolbox,
    author = "Cuadra, A and Huete, C and Vera, M",
    title = "Combustion Toolbox: A MATLAB-GUI based open-source tool for solving combustion problems",
    year = 2022,
    note = "Version 0.8.0",
    doi = {https://doi.org/10.5281/zenodo.6353961}
}
```
