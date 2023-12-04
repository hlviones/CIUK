#!/bin/bash
#SBATCH --cpus-per-task=4

cd() { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]; then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}

echo "Array ID: $SLURM_ARRAY_TASK_ID"
directory="output/fiji"

counter=0
for folder in "${directory}"/*; do
  counter=$((counter + 1))
  folder_name=$(basename "${folder}")
  if [ "${counter}" == "$SLURM_ARRAY_TASK_ID" ]; then
    echo "Running deconwolf"
    echo "${n2v_input_dir}"
    echo "apptainer run --nv --containall --bind output/fiji/:/fiji,output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw /fiji/${folder_name} /deconwolf/PSF_561.tif --out /deconwolf/${folder_name} --threads 32"
    apptainer run --nv --containall --bind output/fiji/:/fiji,output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw /fiji/"${folder_name}" /deconwolf/PSF_561.tif --out /deconwolf/"${folder_name}" --threads 32
  else
    continue
  fi
done
