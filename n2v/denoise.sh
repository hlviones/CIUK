#!/bin/bash
#SBATCH --partition=gpu
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
time apptainer run --nv --containall --bind output/fiji/:/fiji,output/n2v/:/n2v /mnt/hc-storage/users/hlviones/containers/cbf_n2v.sif --train --dataPath /fiji --baseDir /n2v --epochs 10




echo "Spliting Denoise Jobs"


output=$(sbatch --array=1-"$num_lines" "split.sh")



if [[ $output =~ ([0-9]+) ]]; then
    job_id="${BASH_REMATCH[1]}"
    echo "Submitted batch job $job_id"
else
    echo "Failed to submit the batch job"
fi

# Run the squeue command and count the number of lines
count_jobs() {
    squeue_output=$(squeue --job "$job_id")
    num_lines=$(echo "$squeue_output" | wc -l)
    # Subtract 1 to exclude the header line
    num_jobs=$((num_lines - 1))
    echo "$num_jobs"
}

# Loop until there is only one job left
echo "Starting wait for split jobs"
time while true; do
    num_jobs=$(count_jobs)
    if [ "$num_jobs" -eq 0 ]; then
        break
    fi
    sleep 5  # Wait for 5 seconds before checking again
done



echo "COMPLETED JOB"
exit 0






