#!/bin/bash
#SBATCH --cpus-per-task=1

cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}
module load unzip

# Define the directories
zip_dir="output/fiji"
tmp_dir="output/cellpose/tmp"
roi_dir="output/cellpose/roi"
SLURM_ARRAY_TASK_ID=$((SLURM_ARRAY_TASK_ID - 1))

# Get a list of all zip files
echo "zip_files=($zip_dir/*.zip)"
zip_files=($zip_dir/*.zip)

# Get the zip file for this array task
zip_file=${zip_files[$SLURM_ARRAY_TASK_ID]}  
echo $zip_file
# Get the base name of the zip file
base_name=$(basename $zip_file)
base_name="${base_name%_rois.zip}"
echo $base_name
# Create a temporary directory for this zip file
mkdir -p $tmp_dir/$base_name

echo $zip_file

# Unzip the file into the temporary directory
unzip -q $zip_file -d $tmp_dir/$base_name

# Initialize a counter
counter=0

# Loop over each file in the temporary directory
# Check if there are files in the directory
if [[ -n $(ls -A $tmp_dir/$base_name) ]]; then
  # Loop over each file in the temporary directory
  for file in $tmp_dir/$base_name/*; do
    # Increment the counter
    counter=$((counter + 1))
    echo $file
    # Move and rename the file to the roi directory
    mv $file $roi_dir/$base_name"_"$counter".roi"
  done
else
  echo "No files found in the directory."
fi  

# Remove the temporary directory for this zip file