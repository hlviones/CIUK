#!/bin/bash
#SBATCH --cpus-per-task=4
#SBATCH --job-name=DECONWOLF_4_CORE_CLUSTER_BENCHMARK
cd () { 
  builtin cd "$@" 
  if [[ "$PWD" == *"/home/hlviones"* ]]
  then
    echo "In the /home/hlviones directory. Exiting the script."
    exit 1
  fi
}

# Initialize our own variables:
lambda=""
input_file=""

# Parse the command-line arguments
while (( "$#" )); do
  case "$1" in
    --lambda)
      if [[ $2 =~ ^[0-9]+$ ]] ; then
        lambda="$2"
        shift 2
      else
        echo "Error: --lambda requires a numeric argument"
        exit 1
      fi
      ;;
    --input_file)
      if [[ -n $2 ]] ; then
        input_file="$2"
        shift 2
      else
        echo "Error: --input_file requires a file name"
        exit 1
      fi
      ;;
    *)
      echo "Error: Invalid argument"
      exit 1
      ;;
  esac
done

# Check if the variables are set
if [[ -z $lambda ]]; then
  echo "Error: --lambda argument not set"
  exit 1
fi

if [[ -z $input_file ]]; then
  echo "Error: --input_file argument not set"
  exit 1
fi

TIMEFORMAT=%R

mkdir output/



# Prepare Staging Folders
staging_folder="output/staging"
mkdir -p $staging_folder
cp $input_file output/staging/
mkdir -p $fiji_folder
mkdir -p "output/deconwolf"
echo -e "\n\n"




echo $num_lines



time apptainer run --nv --containall --bind output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw_bw --lambda $lambda --NA 1.0 --ni 1.33 --resxy 510 --resz 1250 /deconwolf/PSF_$lambda.tif --verbose 2


echo -e "\nSplitting Deconwolf Jobs"


time apptainer run --containall --bind output/staging/:/staging,output/deconwolf/:/deconwolf /mnt/hc-storage/users/hlviones/containers/cbf_deconwolf_0.3.2.sif dw /staging/$input_file /deconwolf/PSF_$lambda.tif --out /deconwolf/dw_$input_file




 


echo -e "\nCOMPLETED JOB"
exit 0
