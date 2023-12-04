#!/bin/bash
#SBATCH --job-name="SLURMGUI_SEGMENT_BENCH"
#SBATCH --cpus-per-task=4
#SBATCH --partition=gpu
# Enter working dir

cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}
module load unzip


# Prepare Staging Folders
mkdir -p output/cellpose

time unzip cellpose_morpho_test.zip -d output/
dir="output/"
# List all files in the directory
time for file in "$dir"/*; do
    filename=$(basename $file)
    apptainer run --containall --bind output/:/input,output/cellpose:/output /mnt/hc-storage/users/hlviones/containers/cellpose_latest.sif --verbose --image_path /input/$filename --savedir /cellpose_output --save_rois


done







echo -e "\nCOMPLETED JOB"
exit 0
