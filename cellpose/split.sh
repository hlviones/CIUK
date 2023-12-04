#!/bin/bash
#SBATCH --mem=1GB
#SBATCH --cpus-per-task=1
cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}
time echo "Array ID: $SLURM_ARRAY_TASK_ID"



counter=0


# Get the current directory
dir="output/"


# Loop through all files in the current directory
for file in "$current_dir"/*; do
  file_extension="${file##*.}"
  if [ "$file_extension" == "tif" ] || [ "$file_extension" == "png" ]; then
    counter=$((counter + 1))
    if [ "$counter" == "$SLURM_ARRAY_TASK_ID" ]; then
      cellpose_input_dir=$(dirname "$file")
      filename=$(basename $file)
      echo "Matched file:" $filename
      ## Run cellpose
      echo "Running cellpose"

      apptainer -d run --containall --bind output/:/input,output/cellpose:/output /mnt/hc-storage/users/hlviones/containers/cellpose_latest.sif --verbose --image_path /input/$filename --savedir /output --save_rois
      break
    fi
  fi
done


