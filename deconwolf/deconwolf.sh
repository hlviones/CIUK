#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --partition=gpu
#SBATCH --job-name=DECONWOLF_FULL_CLUSTER_BENCHMARK

cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}
TIMEFORMAT=%R

mkdir output/



# Prepare Staging Folders
staging_folder="output/staging"
mkdir -p $staging_folder
cp C2-FK-09-MV.tif output/staging/
cp C1-FK-09-MV.tif output/staging/
cp C3-FK-09-MV.tif output/staging/
# Prepare Output Folders
fiji_folder="output/fiji"
mkdir -p $fiji_folder
mkdir -p "output/deconwolf"
echo -e "\n\n"

echo "Starting Splitting Stack"
dir="output/staging"
# List all files in the directory
for file in "$dir"/*; do
    time apptainer run --containall --bind output/:/output /mnt/hc-storage/users/hlviones/containers/cbf_tiffsplit.sif /$file /output/fiji/

done





# Initialize line count
num_lines=$(ls $fiji_folder | wc -l)

echo $num_lines



time apptainer run --nv --containall --bind output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw_bw --lambda 561 --NA 1.0 --ni 1.33 --resxy 510 --resz 1250 /deconwolf/PSF_561.tif --threads 48 --verbose 2


echo -e "\nSplitting Deconwolf Jobs"


mkdir -p output/deconwolf

output=$(sbatch --array=1-"$num_lines" "split.sh")






if [[ $output =~ ([0-9]+) ]]; then
    job_id="${BASH_REMATCH[1]}"
    echo -e "\nSubmitted batch job $job_id"
else
    echo -e "\nFailed to submit the batch job"
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
echo -e "\nStarting wait for split jobs"
time while true; do
    num_jobs=$(count_jobs)
    if [ "$num_jobs" -eq 0 ]; then
        break
    fi
    sleep 5  # Wait for 5 seconds before checking again
done



rm output/ -rf
echo -e "\nCOMPLETED JOB"
exit 0
