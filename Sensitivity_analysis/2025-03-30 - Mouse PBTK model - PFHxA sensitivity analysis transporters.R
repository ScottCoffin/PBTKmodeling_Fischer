library(deSolve)
library(tictoc)
library(openxlsx)
library(ggplot2)
library(dplyr)
library(pracma)
library(readxl)
library(tidyr)
tic()

# Duration of simulation
days     = 52
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
P_app           = 1.16*10^-6             # apparent permeability of the chemical (passive membrane diffusion) (cm/s)

# Partition coefficients to tissue constituents
K_FABP          = 10^2.39                  # Fatty acid binding protein-water partition coefficient (L_w/L_FABP)
K_SA            = 10^3.89                  # Human serum albumin-water partition coefficient (L_w/L_SA)
K_Glob          = 10^1.73                  # Globulin-water partition coefficient (L_w/L_SP)
K_SP            = 10^0.64                  # Structural proteins-water partition coefficient (L_w/L_SP)
K_ML            = 10^2.31                  # Membrane lipid-water partition coefficient (L_w/L_ML)

# Membrane transporters (expressed as permeabilities)
P_OATP1B2       = 6.14*10^-7             # OATP1B3-mediated active transport membrane permeability (cm/s)
P_OATP2B1       = 2.27*10^-7             # OATP2B1-mediated active transport membrane permeability (cm/s)
P_NTCP          = 0                      # NTCP-mediated active transport membrane permeability (cm/s)
P_OAT1          = 3.80*10^-6             # OAT1-mediated active transport membrane permeability (cm/s)
P_OAT2          = 3.17*10^-7             # OAT2-mediated active transport membrane permeability (cm/s)
P_OAT3          = 1.76*10^-5             # OAT3-mediated active transport membrane permeability (cm/s)

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
total_oral_dose    = 5000 * bw/1000 # mg per kg body weight
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

# Store sensitivity coefficients and AUC changes
sensitivity_coefficients <- list()
AUC_sensitivity <- list()

# Base run without perturbation
out_base <- ode(y = yini, times = times, func = rigidode, parms = NULL, method = "lsoda")
results_base <- as.data.frame(out_base)
results_base$Total_blood_concentration <- (results_base$C_free_blood * V_water_blood + results_base$C_bound_blood * V_sorb_blood) / V_blood
AUC_base <- trapz(results_base$time, results_base$Total_blood_concentration)

# List of parameters to perturb individually
parameters <- c("P_app", "P_OATP1B2", "P_OATP2B1", "P_NTCP", "P_OAT1", "P_OAT2",
                "P_OAT3", "A_GF", "A_liver", "A_kidneys", "A_gut", "A_rest", "A_liver_hep", "A_liver",
                "Q_bile", "Q_blood_gut", "Q_blood_kidneys", "Q_blood_liver",
                "Q_blood_rest", "Q_feces", "Q_urine")
perturbation_factor <- 1.1  # perturbation

# Create an empty data frame to store sensitivity data for all parameters
combined_sensitivity_df <- data.frame(time = results_base$time / 86400)  # Convert time to days

calculate_half_life <- function(time, concentration) {
  # Select only positive concentrations
  positive_indices <- which(concentration > 0)
  time <- time[positive_indices]
  concentration <- concentration[positive_indices]
  
  # Define elimination phase (from half of the data to the end)
  midpoint <- floor(length(time) / 2)
  elimination_phase_indices <- seq(midpoint, length(time))  # From midpoint to the end
  elimination_time <- time[elimination_phase_indices]
  elimination_concentration <- concentration[elimination_phase_indices]
  
  # Log-transform the concentrations
  log_conc <- log(elimination_concentration)
  
  # Fit linear regression
  regression <- lm(log_conc ~ elimination_time)
  
  # Calculate half-life
  half_life <- log(2) / abs(coef(regression)[2])  # Slope of the regression line
  
  return(half_life)
}

# Calculate baseline half-life
half_life_base <- calculate_half_life(results_base$time, results_base$Total_blood_concentration)

# Store sensitivity coefficients for elimination half-life
half_life_sensitivity <- list()

# Loop over each parameter to calculate sensitivity and store results
for (param in parameters) {
  
  # Get the original value of the parameter
  param_original <- get(param)
  
  # Perturb the parameter by 10%
  assign(param, param_original * perturbation_factor)
  
  # Recalculate partition coefficients if needed
  if (param == "K_ML" || param == "K_SA" || param == "K_FABP" || param == "K_Glob" || param == "K_SP") {
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
  }
  
  # Rerun the ODE model with the perturbed parameter
  out_perturbed <- ode(y = yini, times = times, func = rigidode, parms = NULL, method = "lsoda")
  results_perturbed <- as.data.frame(out_perturbed)
  
  # Calculate total blood concentration for perturbed run
  results_perturbed$Total_blood_concentration <- (results_perturbed$C_free_blood * V_water_blood + results_perturbed$C_bound_blood * V_sorb_blood) / V_blood
  
  # Calculate sensitivity coefficients for Total_blood_concentration over time
  delta_Total_blood_concentration <- results_perturbed$Total_blood_concentration - results_base$Total_blood_concentration
  S_Total_blood_concentration <- (delta_Total_blood_concentration / (param_original * (perturbation_factor - 1))) *
    (param_original / results_base$Total_blood_concentration)
  
  # Store the sensitivity in the combined data frame
  combined_sensitivity_df[[param]] <- S_Total_blood_concentration
  
  # Store AUC sensitivity
  AUC_perturbed <- trapz(results_perturbed$time, results_perturbed$Total_blood_concentration)
  AUC_sensitivity[[param]] <- (AUC_perturbed - AUC_base) / AUC_base
  
  # Calculate half-life for perturbed run
  half_life_perturbed <- calculate_half_life(results_perturbed$time, results_perturbed$Total_blood_concentration)
  
  # Calculate half-life sensitivity
  delta_half_life <- half_life_perturbed - half_life_base
  S_half_life <- delta_half_life / half_life_base
  half_life_sensitivity[[param]] <- S_half_life
  
  # Reset the parameter to its original value
  assign(param, param_original)
}

# Convert half-life sensitivity list to a data frame
half_life_sensitivity_df <- as.data.frame(t(as.data.frame(half_life_sensitivity))) * 100
colnames(half_life_sensitivity_df) <- c("Half_Life_Sensitivity (%)")

# Print AUC sensitivities for all parameters
print(AUC_sensitivity)

# Convert AUC_sensitivity list to a data frame
AUC_sensitivity_df <- as.data.frame(t(as.data.frame(AUC_sensitivity))) * 100
colnames(AUC_sensitivity_df) <- c("AUC_Sensitivity")

# Multiply sensitivity coefficients over time by 100 to express as percentages
combined_sensitivity_df[, -1] <- combined_sensitivity_df[, -1] * 100  # exclude the 'time' column

# Save the sensitivity coefficients over time and AUC sensitivities into an Excel file
output_file <- "sensitivity_analysis_results_blood.xlsx"

# Save half-life sensitivity data
write.xlsx(list("Half_Life_Sensitivity" = half_life_sensitivity_df), file = "sensitivity_analysis_half_life.xlsx", rowNames = TRUE)


# Combine baseline and perturbed results into one data frame for plotting
results_base$Run <- "Baseline"
results_perturbed$Run <- "Perturbed"

combined_results <- rbind(
  data.frame(Time = results_base$time / 86400,  # Convert time to days
             Total_Blood_Concentration = results_base$Total_blood_concentration,
             Run = results_base$Run),
  data.frame(Time = results_perturbed$time / 86400,  # Convert time to days
             Total_Blood_Concentration = results_perturbed$Total_blood_concentration,
             Run = results_perturbed$Run)
)

# Plot total blood concentrations over time
ggplot(combined_results, aes(x = Time, y = Total_Blood_Concentration, color = Run)) +
  geom_line(size = 1.2) +
  labs(title = "Total Blood Concentrations Over Time",
       x = "Time (days)",
       y = "Total Blood Concentration (mg/cm?)",
       color = "Simulation") +
  theme_minimal() +
  theme(legend.position = "top")

write.xlsx(list("Time_Sensitivity_Coefficients" = combined_sensitivity_df,
                "AUC_Sensitivities" = AUC_sensitivity_df),
           file = output_file, 
           rowNames = TRUE)

# Calculate total tissue volumes
total_tissue_volume <- V_liver + V_kidneys + V_gut + V_rest

# Function to compute normalized tissue amount over time
calculate_normalized_tissue_amount <- function(results) {
  total_tissue_amount <- (
    results$C_free_liver * V_water_liver + results$C_bound_liver * V_sorb_liver +
      results$C_free_gut * V_water_gut + results$C_bound_gut * V_sorb_gut +
      results$C_free_kidneys * V_water_kidneys + results$C_bound_kidneys * V_sorb_kidneys +
      results$C_free_rest * V_water_rest + results$C_bound_rest * V_sorb_rest
  )
  normalized_tissue_amount <- total_tissue_amount / total_tissue_volume
  return(normalized_tissue_amount)
}

# Base run to calculate AUC for normalized tissue amount
results_base$Normalized_Tissue_Amount <- calculate_normalized_tissue_amount(results_base)
AUC_tissue_base <- trapz(results_base$time, results_base$Normalized_Tissue_Amount)

# Sensitivity analysis for AUC in all tissues
AUC_tissue_sensitivity <- list()

for (param in parameters) {
  
  # Get the original value of the parameter
  param_original <- get(param)
  
  # Perturb the parameter by 10%
  assign(param, param_original * perturbation_factor)
  
  # Recalculate partition coefficients if needed
  if (param == "K_ML" || param == "K_SA" || param == "K_FABP" || param == "K_Glob" || param == "K_SP") {
    K_blood       = V_water_blood / V_blood + V_SA_blood / V_blood * K_SA + V_Glob_blood / V_blood * K_Glob + V_SP_blood / V_blood * K_SP + V_ML_blood / V_blood * K_ML
    K_liver       = V_water_liver / V_liver_tissue + V_FABP_liver / V_liver_tissue * K_FABP + V_SA_liver / V_liver_tissue * K_SA + V_SP_liver / V_liver_tissue * K_SP + V_ML_liver / V_liver_tissue * K_ML
    K_bile        = V_water_bile / V_bile + V_SA_bile / V_bile * K_SA + V_ML_bile / V_bile * K_ML 
    K_bile_liver  = K_bile / K_liver
    K_gut         = V_water_gut / V_gut_tissue + V_FABP_gut / V_gut_tissue * K_FABP + V_SP_gut / V_gut_tissue * K_SP + V_ML_gut / V_gut_tissue * K_ML + V_SA_gut / V_gut_tissue * K_SA
    K_kidneys     = V_water_kidneys / V_kidneys_tissue + V_SA_kidneys / V_kidneys_tissue * K_SA + V_FABP_kidneys / V_kidneys_tissue * K_FABP + V_SP_kidneys / V_kidneys_tissue * K_SP + V_ML_kidneys / V_kidneys_tissue * K_ML
    K_rest        = V_water_rest / V_rest_tissue + V_FABP_rest / V_rest_tissue * K_FABP + V_SP_rest / V_rest_tissue * K_SP + V_ML_rest / V_rest_tissue * K_ML + V_SA_rest / V_rest_tissue * K_SA
    
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
  }
  
  # Rerun the ODE model with the perturbed parameter
  out_perturbed <- ode(y = yini, times = times, func = rigidode, parms = NULL, method = "lsoda")
  results_perturbed <- as.data.frame(out_perturbed)
  
  # Calculate normalized tissue amount for perturbed run
  results_perturbed$Normalized_Tissue_Amount <- calculate_normalized_tissue_amount(results_perturbed)
  
  # Calculate AUC for normalized tissue amount
  AUC_tissue_perturbed <- trapz(results_perturbed$time, results_perturbed$Normalized_Tissue_Amount)
  AUC_tissue_sensitivity[[param]] <- (AUC_tissue_perturbed - AUC_tissue_base) / AUC_tissue_base
  
  # Reset the parameter to its original value
  assign(param, param_original)
}

# Convert AUC tissue sensitivities to a data frame
AUC_tissue_sensitivity_df <- as.data.frame(t(as.data.frame(AUC_tissue_sensitivity))) * 100
colnames(AUC_tissue_sensitivity_df) <- c("AUC_Tissue_Sensitivity (%)")

# Save the AUC tissue sensitivities into an Excel file
write.xlsx(list("AUC_Tissue_Sensitivities" = AUC_tissue_sensitivity_df),
           file = "sensitivity_analysis_tissue_AUC.xlsx", 
           rowNames = TRUE)

bioavailability_sensitivity <- list()

# Calculate baseline bioavailability
bioavailability_base <- tail(results_base$Absorbed_total, 1) / total_dose

for (param in parameters) {
  
  # Get the original value of the parameter
  param_original <- get(param)
  
  # Perturb the parameter by 10%
  assign(param, param_original * perturbation_factor)
  
  # Recalculate partition coefficients if needed
  if (param == "K_ML" || param == "K_SA" || param == "K_FABP" || param == "K_Glob" || param == "K_SP") {
    K_blood       = V_water_blood / V_blood + V_SA_blood / V_blood * K_SA + V_Glob_blood / V_blood * K_Glob + V_SP_blood / V_blood * K_SP + V_ML_blood / V_blood * K_ML
    K_liver       = V_water_liver / V_liver_tissue + V_FABP_liver / V_liver_tissue * K_FABP + V_SA_liver / V_liver_tissue * K_SA + V_SP_liver / V_liver_tissue * K_SP + V_ML_liver / V_liver_tissue * K_ML
    K_bile        = V_water_bile / V_bile + V_SA_bile / V_bile * K_SA + V_ML_bile / V_bile * K_ML
    K_bile_liver  = K_bile / K_liver
    K_gut         = V_water_gut / V_gut_tissue + V_FABP_gut / V_gut_tissue * K_FABP + V_SP_gut / V_gut_tissue * K_SP + V_ML_gut / V_gut_tissue * K_ML + V_SA_gut / V_gut_tissue * K_SA
    K_kidneys     = V_water_kidneys / V_kidneys_tissue + V_SA_kidneys / V_kidneys_tissue * K_SA + V_FABP_kidneys / V_kidneys_tissue * K_FABP + V_SP_kidneys / V_kidneys_tissue * K_SP + V_ML_kidneys / V_kidneys_tissue * K_ML
    K_rest        = V_water_rest / V_rest_tissue + V_FABP_rest / V_rest_tissue * K_FABP + V_SP_rest / V_rest_tissue * K_SP + V_ML_rest / V_rest_tissue * K_ML + V_SA_rest / V_rest_tissue * K_SA
    
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
  }
  
  # Rerun the ODE model with the perturbed parameter
  out_perturbed <- ode(y = yini, times = times, func = rigidode, parms = NULL, method = "lsoda")
  results_perturbed <- as.data.frame(out_perturbed)
  
  # Calculate bioavailability for perturbed run
  bioavailability_perturbed <- tail(results_perturbed$Absorbed_total, 1) / total_dose
  
  # Calculate sensitivity for bioavailability
  bioavailability_sensitivity[[param]] <- (bioavailability_perturbed - bioavailability_base) / bioavailability_base * 100  # Convert to percentage
  
  # Reset the parameter to its original value
  assign(param, param_original)
}

# Convert bioavailability sensitivities to a data frame
bioavailability_sensitivity_df <- as.data.frame(t(as.data.frame(bioavailability_sensitivity)))
colnames(bioavailability_sensitivity_df) <- c("Bioavailability_Sensitivity (%)")

# Save bioavailability sensitivities into an Excel file
write.xlsx(list("Bioavailability_Sensitivity" = bioavailability_sensitivity_df),
           file = "sensitivity_analysis_bioavailability.xlsx",
           rowNames = TRUE)
