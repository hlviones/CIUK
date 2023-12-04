#!/bin/bash
#SBATCH --job-name="SLURMGUI_SEGMENT_%j"
#SBATCH --mem=40GB
#SBATCH --cpus-per-task=15
# Enter working dir


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



# Prepare Staging Folders
staging_folder=$SLURMGUI_OUTPUT_FOLDER"staging"
mkdir -p $staging_folder
# Prepare Output Folders
fiji_folder=$SLURMGUI_OUTPUT_FOLDER"fiji"
mkdir -p $fiji_folder

echo -e "\n\n"

time unzip cellpose_morpho_test.zip -d output/


# Initialize line count
num_lines=$(ls $fiji_folder | wc -l)





echo -e "\nSplitting Cellpose Jobs"


output=$(sbatch --array=1-"$num_lines" "../../scripts/segment/split.sh" $args)






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


echo -e "\nCOMPLETED JOB"
exit 0
