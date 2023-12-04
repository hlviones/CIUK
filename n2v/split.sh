#!/bin/bash
#SBATCH --cpus-per-task="1"
cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}

echo "Array ID: $SLURM_ARRAY_TASK_ID"

directory="output/fiji" 



for folder in "$directory"/*; do
  counter=$((counter + 1))
  folder_name=$(basename "$folder")
  if [ "$counter" == "$SLURM_ARRAY_TASK_ID" ]; then
    n2v_base_dir="output/n2v"
    ## Run n2v
    echo "Running n2v"
    echo $n2v_input_dir
    echo "apptainer run --nv --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /home/hlviones/apptainer/containers/cbf_n2v.sif --predict --fileName *.tif --dataPath /fiji --baseDir /n2v --output /n2v --fileName $folder_name "$@""
    apptainer run --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /mnt/hc-storage/users/hlviones/containers/cbf_n2v.sif --predict --fileName *.tif --dataPath /fiji --baseDir /n2v --output /n2v --fileName $folder_name "$@"
  else continue
  fi done



