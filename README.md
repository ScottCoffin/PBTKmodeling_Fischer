# PBTK Model for PFAS in Mice – Model v1.0

This repository contains the R code for a physiologically based toxicokinetic (PBTK) model developed to simulate the absorption, distribution, and elimination of per- and polyfluoroalkyl substances (PFAS) in mice. The model integrates in vitro-derived parameters (e.g., permeability, protein/phospholipid binding, and transporter activity) with physiological data to simulate PFAS toxicokinetics.

New versions of the model will be added in the future. The mouse model is currently being adjusted for humans.

This version includes:
- A **standard PBTK model** for single simulation runs
- A **Monte Carlo (MC) version** to evaluate variability and calculate 95% confidence intervals
- A **sensitivity analysis version** to assess the sensitivity of TK parameters to outcomes (split into transporter-related and binding-related sensitivity)

---

## 📄 Reference

**Fischer et al.** (2025). *Understanding Mechanisms of PFAS Absorption, Distribution, and Elimination using a Physiologically Based Toxicokinetic Model*. Environmental Science & Technology.  

---

## 📁 File Overview

Models are provided for each PFAS chemical, which include the parameters (permeabilitiy, partition coefficients, membrane transporter interactions) specific to the chemical. The physiological parameters are the same for all models and can be found in the Supporting Information of Fischer et al. (2025).

| File Name                                                                      | Description                                           |
|--------------------------------------------------------------------------------|-------------------------------------------------------|
| `2025-04-24 - Mouse PBTK model - PFAS name.R`                                  | Standard model (deterministic simulation)             |
| `2025-04-22 - Mouse PBTK model - PFAS name - MC.R`                             | Monte Carlo simulation version (n = 100, changed)     |
| `2025-03-30 - Mouse PBTK model - PFAS name sensitivity analysis binding.R`     | Sensitivity analysis for protein/lipid binding        |
| `2025-03-30 - Mouse PBTK model - PFAS name sensitivity analysis transporters.R`| Sensitivity analysis for membrane transporters        |

Each model simulates toxicokinetics of the chemical in wild-type mice. The dosing regimen can be adjusted to single or repeated IV or oral dosing (see Fischer et al. 2025 for more information).

---

## 🧪 Model Features

- **Five compartments**: Blood, liver, kidneys, gut, and rest of body
- **Processes modeled**: 
  - Blood flow
  - Protein and phospholipid binding
  - Passive membrane permeability
  - Transporter-mediated uptake and excretion
  - Renal and biliary excretion
- **Input parameters**: Sourced from in vitro and literature data (see SI of Fischer et al. 2025)
- **Monte Carlo sampling**: Evaluates variability in chemical-specific parameters
- **Sensitivity analysis**: Identifies key determinants of blood/tissue AUC and half-life

---

## 🚀 How to Run

1. Open R (tested with **R v4.3.1**)
2. Install required packages if not already installed:
```r
install.packages(c(
  "deSolve", 
  "dplyr", 
  "pracma", 
  "ggplot2", 
  "reshape2", 
  "mcmc", 
  "readxl", 
  "openxlsx", 
  "tictoc", 
  "tidyr"
))
