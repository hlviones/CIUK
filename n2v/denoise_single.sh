#!/bin/bash
#SBATCH --job-name="SLURMGUI_DENOISE_BENCHMARK"
#SBATCH --mem=16GB
#SBATCH --cpus-per-task=4

cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}
echo "Loading Modules"
echo "module load unzip"
source /etc/profile.d/lmod.sh
module load unzip
module load parallel



# Staging Steps

# Prepare Staging Folders
staging_folder="output/staging"
mkdir -p $staging_folder
# Prepare Output Folders
fiji_folder="output/fiji"
mkdir -p $fiji_folder
n2v_folder="output/n2v"
mkdir -p $n2v_folder

echo -e "\n\n"

cp Full-Stack-Data-PB.tif output/staging

apptainer run --containall --bind ./:/input,output/fiji:/output /mnt/hc-storage/users/hlviones/containers/cbf_tiffsplit.sif /input/Full-Stack-Data-PB.tif /output/Full-Stack-Data-PB_1



num_lines=$(ls $fiji_folder | wc -l)

echo "Training Model"
# Moving required scripts to working dir


export TF_FORCE_GPU_ALLOW_GROWTH=true
time apptainer run --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /mnt/hc-storage/users/hlviones/containers/cbf_n2v.sif --train --dataPath /fiji --baseDir /n2v --epochs 10




echo "Spliting Denoise Jobs"

directory="output/fiji" 



time for folder in "$directory"/*; do
    folder_name=$(basename "$folder")

    n2v_base_dir="output/n2v"
    ## Run n2v
    echo "Running n2v"
    echo "apptainer run --nv --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /home/hlviones/apptainer/containers/cbf_n2v.sif --predict --fileName *.tif --dataPath /fiji --baseDir /n2v --output /n2v --fileName $folder_name "
    apptainer run --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /mnt/hc-storage/users/hlviones/containers/cbf_n2v.sif --predict --fileName *.tif --dataPath /fiji --baseDir /n2v --output /n2v --fileName $folder_name 
done

echo "COMPLETED JOB"
exit 0






