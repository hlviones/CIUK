#!/bin/bash
#SBATCH --cpus-per-task=40
#SBATCH --mem=60GB
#SBATCH --job-name=CLEMREG_BENCHMARK

time apptainer run --containall --nv --bind ./:/input /mnt/hc-storage/users/hlviones/containers/cbf_clem_reg.sif --lm_input /input/EM04468_2_63x_pos8T_LM_raw.tif --em_input /input/em_20nm_z_40_145.tif --registration_algorithm 'Rigid CPD' --mito_channel 2 