library(deSolve)
library(tictoc)
library(openxlsx)
library(ggplot2)
library(dplyr)
library(pracma)
library(readxl)
library(tidyr)
library(mcmc)
tic()

# Duration of simulation
days     = 65
t_end    = days * 86400                       # duration of simulation in seconds

#### Physiological & Chemical Parameters ####
## Body and blood parameters ##
bw                 = 30                       # body weight (g)
V_body             = 30                       # body volume (cm3)
Q_blood_liver      = 0.021                    # Physiological blood flow rate perfusing the liver (cm3_blood/s)
Q_blood_gut        = 0.025                    # Physiological blood flow rate perfusing the gut (cm3_blood/s)
Q_blood_kidneys    = 0.0217                   # Physiological blood flow rate perfusing the liver (cm3_blood/s)
Q_blood_rest       = 0.0717                   # Physiological blood flow rate perfusing the rest of the body (cm3_blood/s)
Q_blood_liver_port = 0.009                    # Physiological blood flow rate perfusing the liver from the gut (cm3_blood/s)

## LIVER ##
# Liver physiology
V_liver_tissue        = 1.65                           # Volume of liver tissue (cm3)
V_blood_liver_hep     = 0.357                          # volume of blood in the hepatic portal vein at steady state (cm3)
V_bile                = 0.03                           # steady-state volume of bile acids (cm3)
V_blood_liver         = 0.153                          # volume of blood in the hepatic artery at steady state (cm3)
V_liver               = V_liver_tissue + V_blood_liver + V_blood_liver_hep # total volume of perfused liver (cm3)
A_liver_hep           = 700                             # capillary surface area of portal vein (cm2)
A_liver               = 300                             # capillary surface area of hepatic artery (cm2)

# Blood in liver
V_SA_blood_liver      = 0.0147 * V_blood_liver # volume of SA in the blood perfusing liver (cm3)
V_Glob_blood_liver    = 0.0133 * V_blood_liver # volume of globulins in the blood perfusing liver (cm3)
V_SP_blood_liver      = 0.1657 * V_blood_liver # volume of structural proteins in the blood perfusing liver (cm3)
V_ML_blood_liver      = 0.00392 * V_blood_liver # volume of membrane lipids in the blood perfusing liver (cm3)
V_water_blood_liver   = V_blood_liver - V_SA_blood_liver - V_Glob_blood_liver - V_SP_blood_liver - V_ML_blood_liver # volume of water and non-sorptive materials in the blood perfusing liver (cm3)
V_sorb_blood_liver    = V_blood_liver - V_water_blood_liver # volume of colloids in the blood perfusing liver (cm3)

# Blood in hepatic portal vein
V_SA_blood_liver_hep      = 0.0147 * V_blood_liver_hep # volume of SA in the hepatic artery at steady state (60% of proteins are albumin) (cm3)
V_Glob_blood_liver_hep    = 0.0133 * V_blood_liver_hep # volume of globulins in the blood perfusing liver (cm3)
V_SP_blood_liver_hep      = 0.1657 * V_blood_liver_hep # volume of structural proteins in the hepatic artery at steady state (60% of proteins are albumin) (cm3)
V_ML_blood_liver_hep      = 0.00392 * V_blood_liver_hep # volume of membrane lipids in the hepatic artery at steady state (60% of proteins are albumin) (cm3)
V_water_blood_liver_hep   = V_blood_liver_hep - V_SA_blood_liver_hep - V_Glob_blood_liver_hep - V_SP_blood_liver_hep - V_ML_blood_liver_hep # volume of water and non-sorptive materials in the hepatic artery at steady state (cm3)
V_sorb_blood_liver_hep    = V_blood_liver_hep - V_water_blood_liver_hep  # volume of colloids in the blood in the hepatic artery at steady state (cm3)

# Liver tissue composition
V_FABP_liver        = 0.0025 * V_liver_tissue # volume of FABPs in the liver (cm3)
V_SA_liver          = 0.0012  * V_liver_tissue # volume of albumin-like proteins in the liver (cm3)
V_SP_liver          = 0.2075 * V_liver_tissue  # volume of structural proteins in the liver (cm3)
V_ML_liver          = 0.02046 * V_liver_tissue # volume of membrane lipids in the liver (cm3)
V_water_liver       = V_liver_tissue - V_FABP_liver - V_SA_liver - V_SP_liver - V_ML_liver # volume of water and non-sorptive materials in liver (cm3)
V_sorb_liver        = V_liver_tissue - V_water_liver # volume of sorptive colloids in the liver tissue (cm3)

## Bile ##
V_SA_bile           = 0.01 * V_bile # volume of albumin-like proteins in bile (cm3)
V_ML_bile           = 0.03 * V_bile # volume of phospholipid-like lipids in bile acids (cm3)
V_water_bile        = V_bile - V_SA_bile - V_ML_bile # volume of water in bile (cm3)
V_sorb_bile         = V_SA_bile + V_ML_bile # volume of sorptive colloids in bile (cm3)
Q_bile              = 1 * 10^-7 # Bile flow rate from liver to gut (cm3_bile/s)

## GUT ##
# Gut physiology
V_gut_tissue        = 1.71  # Volume of gut tissue (cm3)
V_blood_gut         = 0.03  # steady-state volume of blood perfusing the gut tissue (cm3)
V_gut_lumen         = 3.15  # Volume of gut lumen (cm3)
A_gut               = 1200  # capillary surface area (contact area between blood and gut) (cm2)
A_gut_lumen         = 4800  # capillary surface area of gut lumen (contact area between gut lumen and gut tissue) (cm2)
V_gut               = V_gut_tissue + V_blood_gut # Total volume of perfused gut (cm3)

# Blood in gut
V_SA_blood_gut      = 0.0147 * V_blood_gut # volume of SA in the blood perfusing gut (cm3)
V_Glob_blood_gut    = 0.0133 * V_blood_gut # volume of globulins in the blood perfusing liver (cm3)
V_SP_blood_gut      = 0.1657 * V_blood_gut # volume of structural proteins in the blood perfusing gut (cm3)
V_ML_blood_gut      = 0.00392 * V_blood_gut # volume of membrane lipids in the blood perfusing gut (cm3)
V_water_blood_gut   = V_blood_gut - V_SA_blood_gut - V_Glob_blood_gut - V_SP_blood_gut - V_ML_blood_gut # volume of water and non-sorptive materials in the blood perfusing gut (cm3)
V_sorb_blood_gut    = V_blood_gut - V_water_blood_gut  # volume of colloids in the blood perfusing gut (cm3)

V_FABP_gut          = 0.0002 # volume of FABPs in gut (cm3)
V_SA_gut            = 0.0007 * V_gut_tissue # volume of SA in the gut (cm3)
V_SP_gut            = 0.0563 * V_gut_tissue # volume of structural proteins in the gut (cm3) 
V_ML_gut            = 0.0126 * V_gut_tissue # volume of membrane lipids in the gut (cm3)
V_water_gut         = V_gut_tissue - V_FABP_gut - V_SA_gut - V_SP_gut - V_ML_gut # volume of water and non-sorptive materials in the gut (cm3)
V_sorb_gut          = V_gut_tissue - V_water_gut # volume of sorptive colloids in the gut (cm3)

## Kidneys ##
# Kidneys physiology
V_kidneys_tissue        = 0.51 # Volume of kidney tissue (cm3)
V_blood_kidneys         = 0.12 # steady-state volume of blood perfusing the kidneys (cm3)
V_kidneys_lumen         = 0.0765 # Volume of renal tubular lumen (cm3)
VF_water_filtrate       = 0.81   # Volume fraction of water in filtrate (cm3_w/cm3_filtrate)
A_kidneys               = 400 # capillary surface area (contact area between blood and kidneys) (cm2)
V_kidneys               = V_kidneys_tissue + V_blood_kidneys # Total volume of perfused kidneys (cm3)

# Blood in kidneys
V_SA_blood_kidneys      = 0.0147 * V_blood_kidneys # volume of SA in the blood perfusing kidneys (cm3)
V_Glob_blood_kidneys    = 0.0133 * V_blood_kidneys # volume of globulins in the blood perfusing liver (cm3)
V_SP_blood_kidneys      = 0.1657 * V_blood_kidneys # volume of structural proteins in the blood perfusing kidneys (cm3)
V_ML_blood_kidneys      = 0.00392 * V_blood_kidneys # volume of membrane lipids in the blood perfusing kidneys (cm3)
V_water_blood_kidneys   = V_blood_kidneys - V_SA_blood_kidneys - V_Glob_blood_kidneys - V_SP_blood_kidneys - V_ML_blood_kidneys # volume of water and non-sorptive materials in the blood perfusing kidneys (cm3)
V_sorb_blood_kidneys    = V_blood_kidneys - V_water_blood_kidneys  # volume of colloids in the blood perfusing kidneys (cm3)

V_SA_kidneys            = 0.0014 * V_kidneys_tissue # volume of SA in kidneys (cm3)
V_FABP_kidneys          = 0.0031 * V_kidneys_tissue # volume of FABPs in kidneys (cm3)
V_SP_kidneys            = 0.1767 * V_kidneys_tissue # volume of structural proteins in kidneys (cm3) 
V_ML_kidneys            = 0.0206 * V_kidneys_tissue # volume of membrane lipids in kidneys (cm3)
V_water_kidneys         = V_kidneys_tissue - V_SA_kidneys - V_FABP_kidneys - V_SP_kidneys - V_ML_kidneys # volume of water and non-sorptive materials in kidneys (cm3)
V_sorb_kidneys          = V_kidneys_tissue - V_water_kidneys  # volume of sorptive colloids in kidneys (cm3)

## REST ##
# rest physiology
V_rest_tissue        = 24.13 # Volume of "rest" tissue (cm3)
V_blood_rest         = 0.33  # steady-state volume of blood perfusing "rest" (cm3)
A_rest               = 400   # capillary surface area (contact area between blood and "rest") (cm2)
V_rest               = V_rest_tissue + V_blood_rest  # Volume of perfused "rest" tissue (cm3)

# Blood in rest
V_SA_blood_rest      = 0.0147 * V_blood_rest # volume of SA in the blood perfusing "rest" (cm3)
V_Glob_blood_rest    = 0.0133 * V_blood_rest # volume of globulins in the blood perfusing liver (cm3)
V_SP_blood_rest      = 0.1657 * V_blood_rest # volume of structural proteins in the blood perfusing "rest" (cm3)
V_ML_blood_rest      = 0.00392 * V_blood_rest # volume of membrane lipids in the blood perfusing "rest" (cm3)
V_water_blood_rest   = V_blood_rest - V_SA_blood_rest - V_Glob_blood_rest - V_SP_blood_rest - V_ML_blood_rest # volume of water and non-sorptive materials in the blood perfusing "rest" (cm?)
V_sorb_blood_rest    = V_blood_rest - V_water_blood_rest # volume of colloids in the blood perfusing "rest" (cm3)

V_SA_rest            = 0.00086 # volume of SA in "rest" (cm3)
V_FABP_rest          = 0 # volume of FABPs in "rest" (cm3)
V_SP_rest            = 0.1128 * V_rest_tissue # volume of structural proteins in "rest" (cm3) 
V_ML_rest            = 0.0114 * V_rest_tissue # volume of membrane lipids in "rest" (cm3)
V_water_rest         = V_rest_tissue - V_FABP_rest - V_SP_rest - V_ML_rest # volume of water and non-sorptive materials in "rest" (cm3)
V_sorb_rest          = V_rest_tissue - V_water_rest # volume of sorptive materials in "rest" (cm3)

## CENTRAL BLOOD ##
# Central blood compartment
V_blood         = 1.0068 # total volume of blood in the central blood (cm3)
V_SA_blood      = 0.0147 * V_blood # volume of SA in central blood (cm3)
V_Glob_blood    = 0.0133 * V_blood # volume of globulins in in central blood (cm3)
V_SP_blood      = 0.1657 * V_blood # volume of structural proteins in central blood (cm3)
V_ML_blood      = 0.00392 * V_blood # volume of membrane lipids in central blood (cm3)
V_water_blood   = V_blood - V_SA_blood - V_Glob_blood - V_SP_blood - V_ML_blood # volume of water and non-sorptive materials in the blood (cm?)
V_sorb_blood    = V_blood - V_water_blood  # volume of colloids in the blood

# Excretion
Q_feces    = 3.48/86400 # Feces flow rate (excretion) (cm3_water/s)
Q_urine    = 2.26/86400 # Urine flow rate (excretion) (cm3_urine/s)
A_GF       = 35 # Area for glomerular filtration and renal tubular reabsorption (cm2)
A_tubular  = 11.6 # Area for passive reabsorption or secretion between renal filtrate and kidney tissue (cm2)

#### Chemical descriptors for partitioning & transport ####
# Permeability
P_app           = 1.84*10^-6             # apparent permeability of the chemical (passive membrane diffusion) (cm/s)

# Partition coefficients to tissue constituents
K_FABP          = 10^2.90                  # Fatty acid binding protein-water partition coefficient (L_w/L_FABP)
K_SA            = 10^4.75                  # Human serum albumin-water partition coefficient (L_w/L_SA)
K_Glob          = 10^1.95                  # Globulin-water partition coefficient (L_w/L_SP)
K_SP            = 10^1.73                  # Structural proteins-water partition coefficient (L_w/L_SP)
K_ML            = 10^4.00                  # Membrane lipid-water partition coefficient (L_w/L_ML)

# Membrane transporters (expressed as permeabilities)
P_OATP1B2       = 6.17*10^-7             # OATP1B3-mediated active transport membrane permeability (cm/s)
P_OATP2B1       = 2.30*10^-7             # OATP2B1-mediated active transport membrane permeability (cm/s)
P_NTCP          = 1.13*10^-6             # NTCP-mediated active transport membrane permeability (cm/s)
P_OAT1          = 0                      # OAT1-mediated active transport membrane permeability (cm/s)
P_OAT2          = 2.53*10^-9             # OAT2-mediated active transport membrane permeability (cm/s)
P_OAT3          = 1.35*10^-5             # OAT3-mediated active transport membrane permeability (cm/s)

# Partition coefficients to and between tissues
K_blood       = V_water_blood / V_blood + V_SA_blood / V_blood * K_SA + V_Glob_blood / V_blood * K_Glob + V_SP_blood / V_blood * K_SP + V_ML_blood / V_blood * K_ML  # Blood-water partition coefficient (cm?/cm?), equal for all blood components
K_liver       = V_water_liver / V_liver_tissue + V_FABP_liver / V_liver_tissue * K_FABP + V_SA_liver / V_liver_tissue * K_SA + V_SP_liver / V_liver_tissue * K_SP + V_ML_liver / V_liver_tissue * K_ML # Liver-water partition coefficient (cm?/cm?)
K_bile        = V_water_bile / V_bile + V_SA_bile / V_bile * K_SA + V_ML_bile / V_bile * K_ML # Bile-water partition coefficient (cm?/cm?)  
K_bile_liver  = K_bile / K_liver
K_gut         = V_water_gut / V_gut_tissue + V_FABP_gut / V_gut_tissue * K_FABP + V_SP_gut / V_gut_tissue * K_SP + V_ML_gut / V_gut_tissue * K_ML + V_SA_gut / V_gut_tissue * K_SA # Gut-water partition coefficient (cm?/cm?)
K_kidneys     = V_water_kidneys / V_kidneys_tissue + V_SA_kidneys / V_kidneys_tissue * K_SA + V_FABP_kidneys / V_kidneys_tissue * K_FABP + V_SP_kidneys / V_kidneys_tissue * K_SP + V_ML_kidneys / V_kidneys_tissue * K_ML # Kidneys-water partition coefficient (cm?/cm?)
K_rest        = V_water_rest / V_rest_tissue + V_FABP_rest / V_rest_tissue * K_FABP + V_SP_rest / V_rest_tissue * K_SP + V_ML_rest / V_rest_tissue * K_ML + V_SA_rest / V_rest_tissue * K_SA # rest-water partition coefficient (cm?/cm?)

# Free and bound fractions in tissues
f_free_blood       = 1/(1 + K_blood * V_sorb_blood / V_water_blood)
f_bound_blood      = 1 - f_free_blood
f_free_liver       = 1/(1 + K_liver * V_sorb_liver / V_water_liver)
f_bound_liver      = 1 - f_free_liver
f_free_gut         = 1/(1 + K_gut * V_sorb_gut / V_water_gut)
f_bound_gut        = 1 - f_free_gut
f_free_kidneys     = 1/(1 + K_kidneys * V_sorb_kidneys / V_water_kidneys)
f_bound_kidneys    = 1 - f_free_kidneys
f_free_rest        = 1/(1 + K_rest * V_sorb_rest / V_water_rest)
f_bound_rest       = 1 - f_free_rest
f_free_filtrate    = f_free_blood

# Sorption and desorption rates from and to tissue constituents (1/s)
k_des_blood       = 0.118                                                              # Desorption rate of chemical from blood colloids (1/s)
k_des_liver       = 0.118                                                              # Desorption rate of chemical from liver colloids (1/s)
k_des_bile        = 0.118                                                              # Desorption rate of chemical from bile (1/s)
k_ab_bile         = (k_des_bile * V_liver_tissue) / (V_bile * K_bile_liver)            # Absorption rate of chemical to bile (1/s)
k_des_gut         = 0.118                                                              # Desorption rate of chemical from gut tissue (1/s)
k_des_kidneys     = 0.118                                                              # Desorption rate of chemical from gut tissue (1/s)
k_des_rest        = 0.118                                                              # Desorption rate of chemical from gut tissue (1/s)

#### SET ORAL AND/OR IV DOSE PARAMETERS #####
# Single IV dose (set to "0" if not applicable)
total_IV_dose    = 0 * bw/1000 # mg per kg body weight
C_blood_t0       = total_IV_dose / V_blood # Starting concentration in blood (mg/cm3) 
C_free_blood_t0  = C_blood_t0 * f_free_blood * V_blood / V_water_blood  # Starting free concentration in blood (mg/cm3)
C_bound_blood_t0 = C_blood_t0 * f_bound_blood * V_blood / V_sorb_blood  # Starting bound concentration in blood (mg/cm3)

# Single oral dose (set to "0" if not applicable)
total_oral_dose    = 1000 * bw/1000 # mg per kg body weight
C_gut_lumen_t0     = total_oral_dose / V_gut_lumen  # mg/cm3
total_dose         = total_IV_dose + total_oral_dose

# Constant intake (for diffusive uptake, set to "0" if not applicable)
daily_IV_dose          = 0 * bw/1000/84600         # mg per kg body weight per second
amount_in_blood        = daily_IV_dose             # intake of PFAS in blood (mg/s) 
daily_oral_dose        = 0 * bw/1000/84600         # mg per kg body weight per second
amount_in_gut          = daily_oral_dose           # daily oral doses (mg) 

#### SIMULATION #####
rigidode <- function(t, y, parms) {
  C_free_blood               = y[1] 
  C_bound_blood              = y[2]
  C_free_blood_liver         = y[3]
  C_bound_blood_liver        = y[4]
  C_free_blood_liver_hep     = y[5]
  C_bound_blood_liver_hep    = y[6]
  C_free_blood_gut           = y[7]
  C_bound_blood_gut          = y[8]
  C_free_blood_kidneys       = y[9]
  C_bound_blood_kidneys      = y[10]
  C_free_blood_rest          = y[11]
  C_bound_blood_rest         = y[12]
  C_free_liver               = y[13]
  C_bound_liver              = y[14]
  C_bile                     = y[15]
  C_free_gut                 = y[16]
  C_bound_gut                = y[17]
  C_free_kidneys             = y[18]
  C_bound_kidneys            = y[19]
  C_filtrate                 = y[20]
  C_free_rest                = y[21]
  C_bound_rest               = y[22]
  C_gut_lumen                = y[23]
  J_blood_to_filtrate        = y[24]
  J_liver_to_bile            = y[25]
  Excreted_feces             = y[26]
  Excreted_urine             = y[27]
  Absorbed_total             = y[28]
 
 P_app     <- parms$P_app
 K_blood   <- parms$K_blood
 K_liver   <- parms$K_liver
 K_gut     <- parms$K_gut
 K_kidneys <- parms$K_kidneys
 K_rest    <- parms$K_rest
 P_OATP1B2 <- parms$P_OATP1B2
 P_OATP2B1 <- parms$P_OATP2B1
 P_NTCP    <- parms$P_NTCP
 P_OAT1    <- parms$P_OAT1
 P_OAT2    <- parms$P_OAT2
 P_OAT3    <- parms$P_OAT3

 # Incoming fluxes (mg/s)
 J_in_blood_free         = amount_in_blood * f_free_blood
 J_in_blood_bound        = amount_in_blood * f_bound_blood
 
 J_in_gut_lumen          = amount_in_gut
 
 # General blood
 J_bound_free_blood      = k_des_blood * V_sorb_blood * (C_bound_blood - C_free_blood * K_blood)                      # Flux between free and bound chemicals in blood (mg/s)
 
 # Blood perfusing the liver (hepatic arteries)
 J_blood_liver_free_in     = Q_blood_liver * V_water_blood_liver / V_blood_liver * (C_free_blood - C_free_blood_liver)        # Influx free chemicals in blood perfusing the liver (mg/s)
 J_blood_liver_bound_in    = Q_blood_liver * V_sorb_blood_liver / V_blood_liver * (C_bound_blood - C_bound_blood_liver)       # Influx bound chemicals in blood perfusing the liver (mg/s)
 J_bound_free_blood_liver  = k_des_blood * V_sorb_blood_liver * (C_bound_blood_liver - C_free_blood_liver * K_blood)          # Flux between free and bound chemicals in liver (mg/s)
 
 # Distribution between free and bound chemical in hepatic portal vein
 J_bound_free_blood_liver_hep  = k_des_blood * V_sorb_blood_liver_hep * (C_bound_blood_liver_hep - C_free_blood_liver_hep * K_blood)        # Flux between free and bound chemicals in gut (mg/s)
 
 # Flow from hepatic portal vein to liver
 J_hep_vein_to_liver_Papp  = P_app * A_liver_hep * (C_free_blood_liver_hep - C_free_liver)
 J_hep_vein_to_liver_OATPs = (P_OATP1B2 + P_OATP2B1 + P_NTCP) * A_liver_hep * C_free_blood_liver_hep
 
 # Blood perfusing the gut
 J_blood_gut_free_in     = Q_blood_gut * V_water_blood_gut / V_blood_gut * (C_free_blood - C_free_blood_gut)        # Influx free chemicals in blood perfusing the gut (mg/s)
 J_blood_gut_bound_in    = Q_blood_gut * V_sorb_blood_gut / V_blood_gut * (C_bound_blood - C_bound_blood_gut)       # Influx bound chemicals in blood perfusing the gut (mg/s)
 J_bound_free_blood_gut  = k_des_blood * V_sorb_blood_gut * (C_bound_blood_gut - C_free_blood_gut * K_blood)        # Flux between free and bound chemicals in gut (mg/s)
 
 # Blood perfusing the kidneys
 J_blood_kidneys_free_in     = Q_blood_kidneys * V_water_blood_kidneys / V_blood_kidneys * (C_free_blood - C_free_blood_kidneys)        # Influx free chemicals in blood perfusing the kidneys (mg/s)
 J_blood_kidneys_bound_in    = Q_blood_kidneys * V_sorb_blood_kidneys / V_blood_kidneys * (C_bound_blood - C_bound_blood_kidneys)       # Influx bound chemicals in blood perfusing the kidneys (mg/s)
 J_bound_free_blood_kidneys  = k_des_blood * V_sorb_blood_kidneys * (C_bound_blood_kidneys - C_free_blood_kidneys * K_blood)        # Flux between free and bound chemicals in kidneys (mg/s)
 
 # Blood perfusing the rest
 J_blood_rest_free_in     = Q_blood_rest * V_water_blood_rest / V_blood_rest * (C_free_blood - C_free_blood_rest)        # Influx free chemicals in blood perfusing the rest (mg/s)
 J_blood_rest_bound_in    = Q_blood_rest * V_sorb_blood_rest / V_blood_rest * (C_bound_blood - C_bound_blood_rest)       # Influx bound chemicals in blood perfusing the rest (mg/s)
 J_bound_free_blood_rest  = k_des_blood * V_sorb_blood_rest * (C_bound_blood_rest - C_free_blood_rest * K_blood)        # Flux between free and bound chemicals in gut (mg/s)
 
 # Fluxes to and from liver (mg/s)
 J_blood_liver_Papp    = P_app * A_liver * (C_free_blood_liver - C_free_liver)                               # Flux of free chemicals between blood and liver by passive diffusion (mg/s)
 J_blood_liver_OATPs   = (P_OATP1B2 + P_OATP2B1 + P_NTCP) * A_liver * C_free_blood_liver         # Flux of free chemicals between blood and liver by active transport (mg/s)
 J_bound_free_liver    = k_des_liver * V_sorb_liver * (C_bound_liver - C_free_liver * K_liver)               # Flux between free and bound chemicals in liver (mg/s)
 J_liver_to_bile       = k_ab_bile * V_water_bile * (C_free_liver - C_bile / K_bile)                         # Flux between bound and free chemicals in liver (mg/s)
 J_bile_to_gut         = Q_bile * C_bile
 
 # Fluxes to and from gut (from/to hepatic portal vein)                       
 J_gut_to_hep_blood_Papp = P_app * A_gut * (C_free_gut - C_free_blood_liver_hep)
 J_gut_to_hep_blood_AT   = (P_OATP2B1) * A_gut * C_free_gut
 J_bound_free_gut        = k_des_gut * V_sorb_gut * (C_bound_gut - C_free_gut * K_gut)               # Flux between free and bound chemicals in liver (mg/s)
 
 # Fluxes to and from gut lumen
 J_gut_lumen_to_gut      = P_app * A_gut_lumen * (C_gut_lumen - C_free_gut)
 J_gut_to_feces          = Q_feces * C_gut_lumen # Flux of chemicals out of the gut through feces (mg/s)
 
 # Fluxes to and from kidneys
 J_blood_kidneys_Papp     = P_app * A_kidneys * (C_free_blood_kidneys - C_free_kidneys)                           # Flux of free chemicals between blood and liver by passive diffusion (mg/s)
 J_blood_kidneys_OAT      = (P_OAT1 + P_OAT2 + P_OAT3) * A_kidneys * C_free_blood_kidneys
 J_kidneys_filtrate       = P_app * A_tubular * (C_filtrate * f_free_filtrate * 1/VF_water_filtrate - C_free_kidneys)
 J_bound_free_kidneys     = k_des_kidneys * V_sorb_kidneys * (C_bound_kidneys - C_free_kidneys * K_kidneys)       # Flux between free and bound chemicals in liver (mg/s)
 
 # Glomerular filtration and renal reabsorption
 J_GlomFil                 = P_app * A_GF * C_free_blood_kidneys
 J_filtrate_to_urine       = Q_urine * C_filtrate
 
 # Fluxes to and from rest
 J_blood_rest_Papp     = P_app * A_rest * (C_free_blood_rest - C_free_rest)                           # Flux of free chemicals between blood and liver by passive diffusion (mg/s)
 J_bound_free_rest     = k_des_rest * V_sorb_rest * (C_bound_rest - C_free_rest * K_rest)       # Flux between free and bound chemicals in liver (mg/s)
 
 # Calculate mass transfer
 # Central blood component
 dC_free_blood  = (J_in_blood_free + J_bound_free_blood - J_blood_liver_free_in - J_blood_gut_free_in - J_blood_kidneys_free_in - J_blood_rest_free_in) / V_water_blood 
 dC_bound_blood = (J_in_blood_bound - J_bound_free_blood - J_blood_liver_bound_in - J_blood_gut_bound_in - J_blood_kidneys_bound_in - J_blood_rest_bound_in) / V_sorb_blood
 
 # Blood in liver
 dC_free_blood_liver  = (J_blood_liver_free_in + J_bound_free_blood_liver - J_blood_liver_Papp - J_blood_liver_OATPs) / V_water_blood_liver
 dC_bound_blood_liver = (J_blood_liver_bound_in - J_bound_free_blood_liver) / V_sorb_blood_liver
 
 # Blood in hepatic vein reaching liver
 dC_free_blood_liver_hep  = (J_gut_to_hep_blood_AT + J_gut_to_hep_blood_Papp + J_bound_free_blood_liver_hep - J_hep_vein_to_liver_Papp - J_hep_vein_to_liver_OATPs) / V_water_blood_liver_hep
 dC_bound_blood_liver_hep = (- J_bound_free_blood_liver_hep) / V_sorb_blood_liver_hep
 
 # Liver tissue
 dC_free_liver    = (J_blood_liver_Papp + J_blood_liver_OATPs + J_bound_free_liver - J_liver_to_bile + J_hep_vein_to_liver_Papp + J_hep_vein_to_liver_OATPs) / V_water_liver
 dC_bound_liver   = (- J_bound_free_liver) / V_sorb_liver
 
 # Bile
 dC_bile = (J_liver_to_bile - J_bile_to_gut) / V_bile
 
 # Blood in gut
 dC_free_blood_gut  = (J_blood_gut_free_in + J_bound_free_blood_gut) / V_water_blood_gut
 dC_bound_blood_gut = (J_blood_gut_bound_in - J_bound_free_blood_gut) / V_sorb_blood_gut
 
 # Gut tissue
 dC_free_gut    = (J_bound_free_gut - J_gut_to_hep_blood_Papp - J_gut_to_hep_blood_AT + J_gut_lumen_to_gut) / V_water_gut
 dC_bound_gut   = (- J_bound_free_gut) / V_sorb_gut
 
 # Gut lumen
 dC_gut_lumen   = (J_in_gut_lumen + J_bile_to_gut - J_gut_lumen_to_gut - J_gut_to_feces) / V_gut_lumen
 
 # Blood in kidneys
 dC_free_blood_kidneys  = (J_blood_kidneys_free_in + J_bound_free_blood_kidneys - J_blood_kidneys_Papp - J_blood_kidneys_OAT - J_GlomFil) / V_water_blood_kidneys
 dC_bound_blood_kidneys = (J_blood_kidneys_bound_in - J_bound_free_blood_kidneys) / V_sorb_blood_kidneys
 
 # Kidney tissue
 dC_free_kidneys    = (J_blood_kidneys_Papp + J_bound_free_kidneys + J_blood_kidneys_OAT + J_kidneys_filtrate) / V_water_kidneys
 dC_bound_kidneys   = (- J_bound_free_kidneys) / V_sorb_kidneys
 
 # Filtrate
 dC_filtrate = (- J_kidneys_filtrate + J_GlomFil - J_filtrate_to_urine) / V_kidneys_lumen  
 
 # Blood in rest
 dC_free_blood_rest  = (J_blood_rest_free_in + J_bound_free_blood_rest - J_blood_rest_Papp) / V_water_blood_rest
 dC_bound_blood_rest = (J_blood_rest_bound_in - J_bound_free_blood_rest) / V_sorb_blood_rest
 
 # Rest tissue
 dC_free_rest    = (J_blood_rest_Papp + J_bound_free_rest) / V_water_rest
 dC_bound_rest   = (- J_bound_free_rest) / V_sorb_rest
 
 # Accumulate excretion
 dExcreted_feces = J_gut_to_feces
 dExcreted_urine = J_filtrate_to_urine
 
 # Accumulate absorption
 dAbsorbed_total = J_gut_to_hep_blood_Papp + J_gut_to_hep_blood_AT
 
 list(c(dC_free_blood, dC_bound_blood, dC_free_blood_liver, dC_bound_blood_liver, dC_free_blood_liver_hep, dC_bound_blood_liver_hep, dC_free_blood_gut, dC_bound_blood_gut, dC_free_blood_kidneys, 
        dC_bound_blood_kidneys, dC_free_blood_rest, dC_bound_blood_rest, dC_free_liver, dC_bound_liver, dC_bile, dC_free_gut, dC_bound_gut, 
        dC_free_kidneys, dC_bound_kidneys, dC_filtrate, dC_free_rest, dC_bound_rest, dC_gut_lumen, J_blood_to_filtrate, J_liver_to_bile, dExcreted_feces, dExcreted_urine, dAbsorbed_total))
}
yini <- c(C_free_blood = C_free_blood_t0, C_bound_blood = C_bound_blood_t0, C_free_blood_liver = C_free_blood_t0, C_bound_blood_liver = C_bound_blood_t0, C_free_blood_liver_hep = 0, C_bound_blood_liver_hep = 0, C_free_blood_gut = C_free_blood_t0, 
          C_bound_blood_gut = C_bound_blood_t0, C_free_blood_kidneys = C_free_blood_t0, C_bound_blood_kidneys = C_bound_blood_t0, C_free_blood_rest = C_free_blood_t0, C_bound_blood_rest = C_bound_blood_t0,
          C_free_liver = 0, C_bound_liver = 0, C_bile = 0, C_free_gut = 0, C_bound_gut = 0, C_free_kidneys = 0, C_bound_kidneys = 0, C_filtrate = 0, 
          C_free_rest = 0, C_bound_rest = 0, C_gut_lumen = C_gut_lumen_t0, J_blood_to_filtrate = 0, J_liver_to_bile = 0, Excreted_feces = 0, Excreted_urine = 0, Absorbed_total = 0) 

times <- seq(0, t_end, length.out = 1000)  # length.out = number of sampled data, decrease to improve performance
out <- ode(y = yini, times = times, func = rigidode, parms = list(P_app = P_app, K_blood = K_blood, K_liver = K_liver, K_gut = K_gut, K_kidneys = K_kidneys, K_rest = K_rest,
                                                                  P_OATP1B2 = P_OATP1B2,
                                                                  P_OATP2B1 = P_OATP2B1,
                                                                  P_NTCP    = P_NTCP,
                                                                  P_OAT1    = P_OAT1,
                                                                  P_OAT2    = P_OAT2,
                                                                  P_OAT3    = P_OAT3), method = "lsoda")

# Function to sample new parameter values based on priors
sample_params <- function() {
  # Define prior distributions for P_app, K_ML, K_SA, and K_SP
  P_app <- rnorm(1, mean = P_app, sd = 3.67*10^-7) # Adjust mean and sd as per your prior knowledge
  K_ML   <- rlnorm(1, meanlog = 11.23, sdlog = 0.1148)
  K_SA   <- rlnorm(1, meanlog = 10.47, sdlog = 0.1148)
  K_Glob <- rlnorm(1, meanlog = 7.67,  sdlog = 0.0460)
  K_SP   <- rlnorm(1, meanlog = 6.71,  sdlog = 0.3357)
  P_OATP1B2 <- rnorm(1, mean = P_OATP1B2, sd = 0)
  P_OATP2B1 <- rnorm(1, mean = P_OATP2B1, sd = 0)
  P_NTCP <- rnorm(1, mean = P_NTCP, sd = 1.13*10^-7)
  P_OAT1 <- rnorm(1, mean = P_OAT1, sd = 0)
  P_OAT2 <- rnorm(1, mean = P_OAT2, sd = 0)
  P_OAT3 <- rnorm(1, mean = P_OAT3, sd = 3.08*10^-7)
  
  return(list(P_app = P_app, K_ML = K_ML, K_SA = K_SA, K_SP = K_SP, K_Glob = K_Glob,
              P_OATP1B2 = P_OATP1B2, P_OATP2B1 = P_OATP2B1,
              P_NTCP = P_NTCP, P_OAT1 = P_OAT1, P_OAT2 = P_OAT2, P_OAT3 = P_OAT3))
}

# Function to recalculate partition coefficients dynamically
calculate_partition_coefficients <- function(params) {
  K_ML   <- params$K_ML
  K_SA   <- params$K_SA
  K_SP   <- params$K_SP
  K_Glob <- params$K_Glob
  
  # Recalculate K_blood, K_liver, K_gut, etc. based on the new values of K_ML, K_SA, K_SP
  K_blood       = V_water_blood / V_blood + V_SA_blood / V_blood * K_SA + V_Glob_blood / V_blood * K_Glob + V_SP_blood / V_blood * K_SP + V_ML_blood / V_blood * K_ML  # Blood-water partition coefficient (cm?/cm?), equal for all blood components
  K_liver       = V_water_liver / V_liver_tissue + V_FABP_liver / V_liver_tissue * K_FABP + V_SA_liver / V_liver_tissue * K_SA + V_SP_liver / V_liver_tissue * K_SP + V_ML_liver / V_liver_tissue * K_ML # Liver-water partition coefficient (cm?/cm?)
  K_bile        = V_water_bile / V_bile + V_SA_bile / V_bile * K_SA + V_ML_bile / V_bile * K_ML # Bile-water partition coefficient (cm?/cm?)  
  K_bile_liver  = K_bile / K_liver
  K_gut         = V_water_gut / V_gut_tissue + V_FABP_gut / V_gut_tissue * K_FABP + V_SP_gut / V_gut_tissue * K_SP + V_ML_gut / V_gut_tissue * K_ML + V_SA_gut / V_gut_tissue * K_SA # Gut-water partition coefficient (cm?/cm?)
  K_kidneys     = V_water_kidneys / V_kidneys_tissue + V_SA_kidneys / V_kidneys_tissue * K_SA + V_FABP_kidneys / V_kidneys_tissue * K_FABP + V_SP_kidneys / V_kidneys_tissue * K_SP + V_ML_kidneys / V_kidneys_tissue * K_ML # Kidneys-water partition coefficient (cm?/cm?)
  K_rest        = V_water_rest / V_rest_tissue + V_FABP_rest / V_rest_tissue * K_FABP + V_SP_rest / V_rest_tissue * K_SP + V_ML_rest / V_rest_tissue * K_ML + V_SA_rest / V_rest_tissue * K_SA # rest-water partition coefficient (cm?/cm?)

  return(list(K_blood = K_blood, K_liver = K_liver, K_gut = K_gut, K_kidneys = K_kidneys, K_rest = K_rest))
}

# MCMC function
run_mcmc <- function(n_iter = 100) {
  results <- list() # Store the results from each iteration
  
  for (i in 1:n_iter) {
    # Sample new parameter values
    params <- sample_params()
    
    # Recalculate partition coefficients based on the sampled parameters
    partition_coeffs <- calculate_partition_coefficients(params)
    
    # Set sampled values and partition coefficients to the parameters
    P_app     <- params$P_app
    K_blood   <- partition_coeffs$K_blood
    K_liver   <- partition_coeffs$K_liver
    K_gut     <- partition_coeffs$K_gut
    K_kidneys <- partition_coeffs$K_kidneys
    K_rest    <- partition_coeffs$K_rest
    P_OATP1B2 <- params$P_OATP1B2
    P_OATP2B1 <- params$P_OATP2B1
    P_NTCP    <- params$P_NTCP
    P_OAT1    <- params$P_OAT1
    P_OAT2    <- params$P_OAT2
    P_OAT3    <- params$P_OAT3
    
    # Update your model code here with these new values
    yini <- c(C_free_blood = C_free_blood_t0, C_bound_blood = C_bound_blood_t0, C_free_blood_liver = C_free_blood_t0, C_bound_blood_liver = C_bound_blood_t0, C_free_blood_liver_hep = 0, C_bound_blood_liver_hep = 0, C_free_blood_gut = C_free_blood_t0, 
              C_bound_blood_gut = C_bound_blood_t0, C_free_blood_kidneys = C_free_blood_t0, C_bound_blood_kidneys = C_bound_blood_t0, C_free_blood_rest = C_free_blood_t0, C_bound_blood_rest = C_bound_blood_t0,
              C_free_liver = 0, C_bound_liver = 0, C_bile = 0, C_free_gut = 0, C_bound_gut = 0, C_free_kidneys = 0, C_bound_kidneys = 0, C_filtrate = 0, 
              C_free_rest = 0, C_bound_rest = 0, C_gut_lumen = C_gut_lumen_t0, J_blood_to_filtrate = 0, J_liver_to_bile = 0, Excreted_feces = 0, Excreted_urine = 0, Absorbed_total = 0) 
    
    times <- seq(0, t_end, length.out = 1000)
    
    # Integrate ODE system
    out <- ode(y = yini, times = times, func = rigidode, parms = list(P_app = P_app, K_blood = K_blood, K_liver = K_liver, K_gut = K_gut, K_kidneys = K_kidneys, K_rest = K_rest,
                                                                      P_OATP1B2 = P_OATP1B2,
                                                                      P_OATP2B1 = P_OATP2B1,
                                                                      P_NTCP    = P_NTCP,
                                                                      P_OAT1    = P_OAT1,
                                                                      P_OAT2    = P_OAT2,
                                                                      P_OAT3    = P_OAT3), method = "lsoda")
    # Print some key concentrations at certain time points
    print(out[1:5,2])  # Print the first few rows to see initial concentrations
    
    # Store output for this iteration
    results[[i]] <- out
  }
  
  return(results)
}

# Function to extract concentration profiles from MCMC results
extract_concentrations <- function(mcmc_results, compartment_index) {
  # Extract the concentrations from the MCMC results for a specific compartment
  # compartment_index: column index of the compartment in the ODE result (e.g., 1 for C_free_blood)
  concentration_matrix <- sapply(mcmc_results, function(res) res[, compartment_index])
  return(concentration_matrix)
}

# Run MCMC
mcmc_results <- run_mcmc(n_iter = 100)

calculate_total_blood_concentration <- function(mcmc_results) {
  total_blood_concentration <- matrix(NA, nrow = nrow(mcmc_results[[1]]), ncol = length(mcmc_results))  # Pre-allocate matrix
  
  for (i in 1:length(mcmc_results)) {
    C_free_blood <- mcmc_results[[i]][, 2]  # Extract C_free_blood from each iteration
    C_bound_blood <- mcmc_results[[i]][, 3] # Extract C_bound_blood from each iteration
    
    # Calculate total blood concentration
    total_blood_concentration[, i] <- (C_free_blood * V_water_blood + C_bound_blood * V_sorb_blood) / V_blood
  }
  
  return(total_blood_concentration)
}

# Calculate total blood concentration for all iterations
total_blood_concentrations <- calculate_total_blood_concentration(mcmc_results)
free_blood_concentrations <- extract_concentrations(mcmc_results, compartment_index = 2)

# Calculate the mean total concentration for each time point across the 100 iterations
mean_total_c_blood <- apply(total_blood_concentrations, 1, mean)

# Calculate the 95% confidence intervals for each time point across the 100 iterations
ci_lower_total_c_blood <- apply(total_blood_concentrations, 1, function(x) quantile(x, 0.025))
ci_upper_total_c_blood <- apply(total_blood_concentrations, 1, function(x) quantile(x, 0.975))

# Assuming 'time' is a vector that represents the time points (in days)
time <- seq(0, days, length.out = nrow(total_blood_concentrations))  # Adjust based on your data

# Create a data frame for plotting
plot_data <- data.frame(
  time = time,
  mean = mean_total_c_blood,
  ci_lower = ci_lower_total_c_blood,
  ci_upper = ci_upper_total_c_blood
)

# Plot
ggplot(plot_data, aes(x = time)) +
  geom_line(aes(y = mean), color = "blue") +  # Plot the mean total concentration
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), fill = "blue", alpha = 0.3) +  # Plot the confidence interval
  labs(title = "Mean Total C_blood with 95% Confidence Interval",
       x = "Time (days)",
       y = "Total C_blood (concentration units)") +
  theme_minimal()

# Save the plot data to an Excel file
write.xlsx(plot_data, file = "plot_data_total_c_blood.xlsx", rowNames = FALSE)

# Function to calculate half-life using linear regression in the elimination phase
calculate_half_life_elimination <- function(time, concentration) {
  # Create a data frame for time and concentration
  data <- data.frame(time = time, concentration = concentration)
  
  # Identify the peak time to define the elimination phase
  peak_time <- time[which.max(concentration)]
  elimination_phase <- data %>% filter(time >= peak_time + 3)
  
  # Filter out near-zero concentrations
  elimination_phase <- elimination_phase %>%
    filter(concentration > 1e-8) %>%
    mutate(log_concentration = log(concentration))
  
  # Ensure sufficient data points
  if (nrow(elimination_phase) < 3) {
    warning("Insufficient data points in the elimination phase.")
    return(NA)
  }
  
  # Perform linear regression on log-transformed concentrations
  elimination_model <- lm(log_concentration ~ time, data = elimination_phase)
  
  # Extract the slope and calculate kel
  kel <- -coef(elimination_model)[2]  # Ensure correct index for time coefficient
  
  # Calculate the half-life
  half_life <- log(2) / kel
  
  return(half_life)
}

# Extract half-lives from MCMC results
extract_half_lives_elimination <- function(mcmc_results) {
  time <- seq(0, days, length.out = nrow(mcmc_results[[1]]))  # Adjust based on your data
  half_lives <- sapply(mcmc_results, function(res) {
    concentration <- res[, 2]  # Assume column 2 is C_free_blood or total blood concentration
    calculate_half_life_elimination(time, concentration)
  })
  
  return(half_lives)
}

# Calculate half-lives for each iteration in MCMC results
half_lives_elimination <- extract_half_lives_elimination(mcmc_results)

# Calculate the mean half-life and 95% confidence intervals
mean_half_life_elimination <- mean(half_lives_elimination, na.rm = TRUE)
ci_lower_half_life_elimination <- quantile(half_lives_elimination, 0.025, na.rm = TRUE)
ci_upper_half_life_elimination <- quantile(half_lives_elimination, 0.975, na.rm = TRUE)

# Print the results
cat("Mean elimination half-life:", mean_half_life_elimination, "\n")
cat("95% CI for elimination half-life:", ci_lower_half_life_elimination, "-", ci_upper_half_life_elimination, "\n")

extract_absorption_excretion <- function(mcmc_results) {
  # Initialize the vectors to store results
  absorption <- numeric(length(mcmc_results))
  feces_excretion <- numeric(length(mcmc_results))
  urine_excretion <- numeric(length(mcmc_results))
  
  # Loop through mcmc_results to process each iteration
  for (i in 1:length(mcmc_results)) {
    results <- mcmc_results[[i]]
    
    # Debugging: Show which iteration we are processing
    print(paste("Processing iteration:", i))  
    
    # Convert the matrix to a data frame for easier handling
    results_df <- as.data.frame(results)
    
    # Ensure the column names are correct for access
    colnames(results_df) <- c("time", "C_free_blood", "C_bound_blood", "C_free_blood_liver", 
                              "C_bound_blood_liver", "C_free_blood_liver_hep", "C_bound_blood_liver_hep",
                              "C_free_blood_gut", "C_bound_blood_gut", "C_free_blood_kidneys", 
                              "C_bound_blood_kidneys", "C_free_blood_rest", "C_bound_blood_rest",
                              "C_free_liver", "C_bound_liver", "C_bile", "C_free_gut", "C_bound_gut", 
                              "C_free_kidneys", "C_bound_kidneys", "C_filtrate", "C_free_rest", "C_bound_rest", "C_gut_lumen", 
                              "J_blood_to_filtrate", "J_liver_to_bile", "Excreted_feces", "Excreted_urine", "Absorbed_total")
    
    # Find the time at which blood concentration is maximum (T_max)
    T_max <- results_df$time[which.max(results_df$C_free_blood + results_df$C_bound_blood)]
    
    # Extract concentrations at T_max
    results_T_max <- results_df %>% filter(time == T_max)
    
    # Calculate absorption (the total amount at T_max)
    amount_blood_T_max    = (results_T_max$C_free_blood * V_water_blood + results_T_max$C_bound_blood * V_sorb_blood)
    
    amount_liver_T_max    = (results_T_max$C_free_liver * V_water_liver + results_T_max$C_bound_liver * V_sorb_liver +
                               results_T_max$C_free_blood_liver * V_water_blood_liver + results_T_max$C_bound_blood_liver * V_sorb_blood_liver +
                               results_T_max$C_free_blood_liver_hep * V_water_blood_liver_hep + results_T_max$C_bound_blood_liver_hep * V_sorb_blood_liver_hep +
                               results_T_max$C_bile * V_bile)
    
    amount_kidneys_T_max  = (results_T_max$C_free_kidneys * V_water_kidneys + results_T_max$C_bound_kidneys * V_sorb_kidneys +
                               results_T_max$C_free_blood_kidneys * V_water_blood_kidneys + results_T_max$C_bound_blood_kidneys * V_sorb_blood_kidneys)
    
    amount_gut_T_max      = (results_T_max$C_free_gut * V_water_gut + results_T_max$C_bound_gut * V_sorb_gut +
                               results_T_max$C_free_blood_gut * V_water_blood_gut + results_T_max$C_bound_blood_gut * V_sorb_blood_gut)
    
    amount_rest_T_max     = (results_T_max$C_free_rest * V_water_rest + results_T_max$C_bound_rest * V_sorb_rest +
                               results_T_max$C_free_blood_rest * V_water_blood_rest + results_T_max$C_bound_blood_rest * V_sorb_blood_rest)

    # Calculate total amount at T_max
    total_amount_at_T_max = amount_blood_T_max + amount_liver_T_max + amount_kidneys_T_max + amount_rest_T_max
    
    # Absorbed fraction (as a percentage of total oral dose)
    absorption[i] <- total_amount_at_T_max / total_oral_dose * 100
    
    # Calculate excretion (feces and urine)
    feces_excretion[i] <- results_df$Excreted_feces[nrow(results_df)] / total_dose * 100
    urine_excretion[i] <- results_df$Excreted_urine[nrow(results_df)] / total_dose * 100
  }
  
  return(list(absorption = absorption, feces_excretion = feces_excretion, urine_excretion = urine_excretion))
}

# Run the function and store results
absorption_excretion_results <- extract_absorption_excretion(mcmc_results)

# Print the structure of the results
print(str(absorption_excretion_results))

# Calculate the mean and confidence intervals for absorption, excretion via feces, and excretion via urine
mean_absorption <- mean(absorption_excretion_results$absorption, na.rm = TRUE)
ci_lower_absorption <- quantile(absorption_excretion_results$absorption, 0.025, na.rm = TRUE)
ci_upper_absorption <- quantile(absorption_excretion_results$absorption, 0.975, na.rm = TRUE)

mean_feces_excretion <- mean(absorption_excretion_results$feces_excretion, na.rm = TRUE)
ci_lower_feces_excretion <- quantile(absorption_excretion_results$feces_excretion, 0.025, na.rm = TRUE)
ci_upper_feces_excretion <- quantile(absorption_excretion_results$feces_excretion, 0.975, na.rm = TRUE)

mean_urine_excretion <- mean(absorption_excretion_results$urine_excretion, na.rm = TRUE)
ci_lower_urine_excretion <- quantile(absorption_excretion_results$urine_excretion, 0.025, na.rm = TRUE)
ci_upper_urine_excretion <- quantile(absorption_excretion_results$urine_excretion, 0.975, na.rm = TRUE)

# Print the results
cat("Mean absorption:", mean_absorption, "%\n")
cat("95% CI for absorption:", ci_lower_absorption, "% -", ci_upper_absorption, "%\n")
cat("Mean excretion via feces:", mean_feces_excretion, "%\n")
cat("95% CI for feces excretion:", ci_lower_feces_excretion, "% -", ci_upper_feces_excretion, "%\n")
cat("Mean excretion via urine:", mean_urine_excretion, "%\n")
cat("95% CI for urine excretion:", ci_lower_urine_excretion, "% -", ci_upper_urine_excretion, "%\n")

# Create a data frame with the results in a row-wise format (Mean, Lower CI, Upper CI)
results_df <- data.frame(
  Metric = c("Absorption", "Feces Excretion", "Urine Excretion"),
  Mean = c(mean_absorption, mean_feces_excretion, mean_urine_excretion),
  Upper_CI = c(ci_upper_absorption, ci_upper_feces_excretion, ci_upper_urine_excretion),
  Lower_CI = c(ci_lower_absorption, ci_lower_feces_excretion, ci_lower_urine_excretion)
)

# Write the results to an Excel file
write.xlsx(results_df, file = "Absorption_Excretion_Results.xlsx", rowNames = FALSE)

# Optional: Print confirmation
cat("Results written to 'Absorption_Excretion_Results.xlsx' \n")