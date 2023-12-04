#!/bin/bash
#SBATCH --cpus-per-task=16
#SBATCH --partition=gpu
#SBATCH --job-name=DECONWOLF_FULL_CLUSTER_BENCHMARK

# Define variables
num_threads=48
lambda_value=561
NA_value=1.0
ni_value=1.33
resxy_value=510
resz_value=1250


cd() { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home"* ]]; then
    echo "In the /home directory. Exiting the script."
    exit 1
  fi
}

TIMEFORMAT=%R

# Create output directory if it doesn't exist
if [[ ! -e output ]]; then
    mkdir output
fi

# Prepare Staging Folders
staging_folder="output/staging"
if [[ ! -e "${staging_folder}" ]]; then
    mkdir -p "${staging_folder}"
fi
cp C2-FK-09-MV.tif $staging_folder
cp C1-FK-09-MV.tif $staging_folder
cp C3-FK-09-MV.tif $staging_folder

# Prepare Output Folders
fiji_folder="output/fiji"
if [[ ! -e "${fiji_folder}" ]]; then
    mkdir -p "${fiji_folder}"
fi


deconwolf_folder="output/deconwolf"
if [[ ! -e "${deconwolf_folder}" ]]; then
    mkdir -p "${deconwolf_folder}"
fi
echo -e "\n\n"

# Splitting Stack
echo "Starting Splitting Stack"
# List all files in the directory
for file in "${staging_folder}"/*; do
    # Split all TIFF's 
    time apptainer run --containall --bind output/:/output /mnt/hc-storage/users/hlviones/containers/cbf_tiffsplit.sif /"${file}" "${fiji_folder}"
done

# Initialize line count
num_lines=$(ls "${fiji_folder}" | wc -l)
echo "${num_lines}"

# Run Deconwolf
time apptainer run --nv --containall --bind output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw_bw --lambda "${lambda_value}" --NA "${NA_value}" --ni "${ni_value}" --resxy "${resxy_value}" --resz "${resz_value}" /deconwolf/PSF_561.tif --threads "${num_threads}" --verbose 2

echo -e "\nSplitting Deconwolf Jobs"
mkdir -p output/deconwolf
output=$(sbatch --array=1-"${num_lines}" "split.sh")

if [[ "${output}" =~ ([0-9]+) ]]; then
    job_id="${BASH_REMATCH[1]}"
    echo -e "\nSubmitted batch job ${job_id}"
else
    echo -e "\nFailed to submit the batch job"
fi

# Run the squeue command and count the number of lines
count_jobs() {
    squeue_output=$(squeue --job "${job_id}")
    num_lines=$(echo "${squeue_output}" | wc -l)
    # Subtract 1 to exclude the header line
    num_jobs=$((num_lines - 1))
    echo "${num_jobs}"
}

# Loop until there is only one job left
echo -e "\nStarting wait for split jobs"
time while true; do
    num_jobs=$(count_jobs)
    if [ "${num_jobs}" -eq 0 ]; then
        break
    fi
    sleep 5  # Wait for 5 seconds before checking again
done

rm output/ -rf
echo -e "\nCOMPLETED JOB"
exit 0