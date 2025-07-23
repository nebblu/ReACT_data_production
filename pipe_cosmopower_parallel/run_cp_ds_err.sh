#!/bin/bash


echo "Initializing training data"
echo ""


project_root="$HOME/ACTio-ReACTio/reactions/examples/pipe_cosmopower_parallel"

# Change to project root directory
cd "$project_root" || {
  echo "Failed to cd to project root: $project_root"
  exit 1
}


# Confirm current directory
echo "Working directory: $(pwd)"


# Give absolute directories to avoid issues with processes 
param_path="$project_root/params/cosmo.txt"
settings_path="$project_root/parameters.dat"
template_path="$project_root/templates/ds"

# Record errors 
failed_log_path_verb="$HOME/ACTio-ReACTio/reactions/examples/logs/failed_iterations_verb.log"
failed_log_path="$HOME/ACTio-ReACTio/reactions/examples/logs/failed_iterations.log"


# Script to produce HMCode_pseudo/HMCode_LCDM x reaction (preset for Dark Scattering)

# Read in minimum and maximum scale, and number of bins to logarithmically sample in range
kmin=`awk 'NR==1 {print $3}' "$settings_path"`
kmax=`awk 'NR==2 {print $3}' "$settings_path"`
NK=`awk 'NR==3 {print $3}' "$settings_path"`

# Read in camb, ReACT, HMCode2020 and EuclidEmulator2 directories
cambdir=`awk 'NR==4 {print $3}' "$settings_path"`
reactdir=`awk 'NR==5 {print $3}' "$settings_path"`
hmcodedir=`awk 'NR==6 {print $3}' "$settings_path"`
classdir=`awk 'NR==7 {print $3}' "$settings_path"`



# Command line arguments
## process number is first argument in terminal command
procno=$1
## total number of processes
noproc=$2
## total number of cosmologies in parameter file
nocos=$3
## starting cosmology (default would be 1)
startcos=$4

## Output file indexing
boostindex=$(($procno))

## Create output file
touch boost$boostindex.dat

#Move file to the cosmopower data directory
mv boost$boostindex.dat data/

# Make a working directory for react output in the react directory
mkdir ${reactdir}/examples/working_cp


# Start the loop over parameter values
#1:process number
#2:number of processes
#3:number of cosmologies

echo "Process number: ${procno}"
echo "Number of cosmologies: ${nocos}"
echo "Number of processes: ${noproc}"


noofiters=$(( $nocos/$noproc ))

echo "Number of cosmologies per process: ${noofiters}"

startp=$(( $procno*$noofiters-$noofiters+$startcos))
endp=$(( $procno*$noofiters + $startcos - 1 ))

echo "From ${startp} to ${endp} "

# We loop over cosmologies specified in the cosmo.txt file
for iteration in $(seq $startp 1 $endp)
#for iteration in $(seq 1 1 1)
do

echo "Starting iteration $iteration on proaess $procno" >> "$HOME/ACTio-ReACTio/reactions/examples/logs/iteration_tracking.log"


# PART 1: SETUP

# Create MGCAMB files - DS+mnu cosmology, LCDM+mnu cosmology and LCDM cosmology
cp "$template_path/dsclass.ini_template" dsclass_params_$iteration.ini
cp "$template_path/mgcamb_lcdm.ini_template" mgcamb_lcdm_params_$iteration.ini
cp "$template_path/mgcamb_lcdm_nonu.ini_template" mgcamb_lcdm_nonu_params_$iteration.ini



echo "Creating training data number: ${iteration}"
echo ""

# Create a cosmology file using  params/create_params.py

# Assumed format of the file:
#Index, Omega_m, Omega_b, Omega_nu, H0, n_s, AS, w0, wa, xi, redshift
omm=`awk 'NR=='${iteration}' {print $2}' "$param_path"`
omb=`awk 'NR=='${iteration}' {print $3}' "$param_path"`
omnu=`awk 'NR=='${iteration}' {print $4}' "$param_path"`
hubble=`awk 'NR=='${iteration}' {print $5}' "$param_path"`
hnorm=100
smallh=`awk 'NR=='${iteration}' {print $5/'${hnorm}'}' "$param_path"`
ns=`awk 'NR=='${iteration}' {print $6}' "$param_path"`
As=`awk 'NR=='${iteration}' {print $7}' "$param_path"`
param1=`awk 'NR=='${iteration}' {print $8}' "$param_path"`
param2=`awk 'NR=='${iteration}' {print $9}' "$param_path"`
param3=`awk 'NR=='${iteration}' {print $10}' "$param_path"`
z1=`awk 'NR=='${iteration}' {print $11}' "$param_path"`



# Additional parameters

#Omega_cdm
#let "omcdm = ${omm} - ${omnu} - ${omb}"
omcdm=`awk 'NR=='${iteration}' {print $2-'${omb}'-'${omnu}'}' "$param_path"`

# Omega_cdm without massive neutrinos (needed for LCDM spectrum)
omcdmnonu=`awk 'NR=='${iteration}' {print $2-'${omb}'}' "$param_path"`

# Omega_Lambda
ol=`awk 'NR=='${iteration}' {print '1'-$2}' "$param_path"`

# Small Ob, Onu, Oc
ombh2=`awk 'NR=='${iteration}' {print $3*'${smallh}'*'${smallh}'}' "$param_path"`
omnuh2=`awk 'NR=='${iteration}' {print $4*'${smallh}'*'${smallh}'}' "$param_path"`
omch2=`awk 'NR=='${iteration}' {print '${omcdm}'*'${smallh}'*'${smallh}'}' "$param_path"`

# Oc+Onu for LCDM spectrum
omch2nonu=`awk 'NR=='${iteration}' {print '${omcdmnonu}'*'${smallh}'*'${smallh}'}' "$param_path"`



# PART 2: Get linear transfers for nu-DS, nu-LCDM and LCDM cosmologies with 


#edit DS class .ini file with relevant params
sed -i "s/Omega_cdm =/Omega_cdm = ${omcdm}/g" dsclass_params_$iteration.ini
sed -i "s/Omega_b =/Omega_b = ${omb}/g" dsclass_params_$iteration.ini
sed -i "s/Omega_ncdm =/Omega_ncdm = ${omnu}/g" dsclass_params_$iteration.ini
sed -i "s/H0 =/H0 = ${hubble}/g" dsclass_params_$iteration.ini
sed -i "s/A_s =/A_s = ${As}/g" dsclass_params_$iteration.ini
sed -i "s/n_s =/n_s = ${ns}/g" dsclass_params_$iteration.ini
sed -i "s/w0_fld =/w0_fld = ${param1}/g" dsclass_params_$iteration.ini
sed -i "s/wa_fld =/wa_fld = ${param2}/g" dsclass_params_$iteration.ini
sed -i "s/xi_ds =/xi_ds = ${param3}/g" dsclass_params_$iteration.ini
sed -i "s/z_pk =/z_pk = ${z1}/g" dsclass_params_$iteration.ini


#edit LCDM  camb .ini file with relevant params
sed -i  "s/omch2 =/omch2 = ${omch2}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/ombh2 =/ombh2 = ${ombh2}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/omnuh2 =/omnuh2 = ${omnuh2}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/hubble =/hubble = ${hubble}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/scalar_spectral_index(1) =/scalar_spectral_index(1) = ${ns}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/scalar_amp(1) =/scalar_amp(1) = ${As}/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/transfer_redshift(1) =/transfer_redshift(1) = ${z1}/g" mgcamb_lcdm_params_$iteration.ini


#edit LCDM without massive neutrinos (for ratio) camb .ini file with relevant params at z=0
sed -i "s/omch2 =/omch2 = ${omch2nonu}/g" mgcamb_lcdm_nonu_params_$iteration.ini
sed -i "s/ombh2 =/ombh2 = ${ombh2}/g" mgcamb_lcdm_nonu_params_$iteration.ini
sed -i "s/hubble =/hubble = ${hubble}/g" mgcamb_lcdm_nonu_params_$iteration.ini
sed -i "s/scalar_spectral_index(1) =/scalar_spectral_index(1) = ${ns}/g" mgcamb_lcdm_nonu_params_$iteration.ini
sed -i "s/scalar_amp(1) =/scalar_amp(1) = ${As}/g" mgcamb_lcdm_nonu_params_$iteration.ini


#filenames
sed -i  "s/root =/root = dsclass_$iteration/g" dsclass_params_$iteration.ini
sed -i  "s/output_root =/output_root = lcdm_$iteration/g" mgcamb_lcdm_params_$iteration.ini
sed -i  "s/output_root =/output_root = lcdm_nonu_$iteration/g" mgcamb_lcdm_nonu_params_$iteration.ini


# Move the files to the MGCAMB directory for running
mv dsclass_params_$iteration.ini ${classdir}
mv mgcamb_lcdm_params_$iteration.ini ${cambdir}
mv mgcamb_lcdm_nonu_params_$iteration.ini ${cambdir}


# Go to the DSCLASS directory
cd ${classdir}

echo "Running DSCLASS with parameters:"
echo ""
echo "H0='${hubble}'"
echo "ns='${ns}'"
echo "Omega_b='${omb}'"
echo "Omega_m='${omm}'"
echo "Omega_nu='${omnu}'"
echo "Omega_L='${ol}'"
echo "As='${As}'"
echo "w0 ='${param1}'"
echo "wa ='${param2}'"
echo "xi ='${param3}'"
echo "Computed at redshifts: '${z1}' "
echo "Number of k values ='${NK}'"
echo ""


# Run MGCLASS
time ./class dsclass_params_$iteration.ini  #> /dev/null



if [ ! -s dsclass_${iteration}_tk.dat ]; then
    echo "CLASS produced no output for iteration ${iteration}" >> "$failed_log_path_verb"
    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
    rm -f dsclass_$iteration*
    rm -f dsclass_params_$iteration.ini
    rm -f ${cambdir}/mgcamb_lcdm_nonu_params_$iteration.ini
    rm -f ${cambdir}/mgcamb_lcdm_params_$iteration.ini
    continue  # Skip to next iteration
fi

# Safely process the output if it exists
tail -n +2 dsclass_${iteration}_tk.dat > test_${iteration}_transfer_1.tmp
if [ -s test_${iteration}_transfer_1.tmp ]; then
    mv test_${iteration}_transfer_1.tmp test_${iteration}_transfer.dat
else
    echo "CLASS output empty after tail for iteration ${iteration}" >> "$failed_log_path_verb"
    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
    rm -f test_${iteration}_transfer_1.tmp
    rm -f ${cambdir}/mgcamb_lcdm_nonu_params_$iteration.ini
    rm -f ${cambdir}/mgcamb_lcdm_params_$iteration.ini
    continue
fi

#tail -n +2 dsclass_$iteration\_tk.dat > test_$iteration\_transfer_1.tmp && mv test_$iteration\_transfer_1.tmp test_$iteration\_transfer.dat

# Safely handle the DSCLASS transfer output
#tail -n +2 dsclass_${iteration}_tk.dat > test_${iteration}_transfer_1.tmp
#if [ -s test_${iteration}_transfer_1.tmp ]; then
#    mv test_${iteration}_transfer_1.tmp test_${iteration}_transfer.dat
#else
#    echo "Warning: Missing or empty dsclass_${iteration}_tk.dat for iteration $iteration" >> "$failed_log_path"
#    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
#    rm -f test_${iteration}_transfer_1.tmp
#fi

mv test_$iteration\_transfer.dat ${reactdir}/examples/transfers


# Clean up
rm dsclass_$iteration\_*
rm dsclass_params_$iteration.ini


# Go to the MGCAMB directory
cd ${cambdir}

echo "Running MGCAMB with parameters:"
echo ""
echo "H0='${hubble}'"
echo "ns='${ns}'"
echo "Omega_b='${omb}'"
echo "Omega_m='${omm}'"
echo "Omega_nu='${omnu}'"
echo "Omega_L='${ol}'"
echo "As='${As}'"
echo "Computed at redshift: '${z1}' "
echo "Number of k values ='${NK}'"
echo ""

# Run MGCAMB
./camb mgcamb_lcdm_params_$iteration.ini # > /dev/null

./camb mgcamb_lcdm_nonu_params_$iteration.ini # > /dev/null



#Clip the headers from transfer functions and rename them
tail -n +2 lcdm_$iteration\_transfer.dat > lcdm_${iteration}_transfer.tmp && mv lcdm_${iteration}_transfer.tmp test_$iteration\_transfer_lcdm.dat
tail -n +2 lcdm_nonu_$iteration\_transfer.dat > lcdm_nonu_$iteration\_transfer.tmp && mv lcdm_nonu_$iteration\_transfer.tmp test_$iteration\_transfer_lcdm_nonu.dat

# Move them to the ReACT transfers folder
mv test_$iteration\_transfer_lcdm.dat ${reactdir}/examples/transfers
mv test_$iteration\_transfer_lcdm_nonu.dat ${reactdir}/examples/transfers


# Clean up
rm mgcamb_lcdm_params_$iteration.ini
rm mgcamb_lcdm_nonu_params_$iteration.ini
rm lcdm_$iteration\_*
rm lcdm_nonu_$iteration\_*



# PART 3: Get halo model reaction and linear pseudo spectra with ReACT

# Go to the react directory
cd ${reactdir}/examples


# Create the ReACT file to compute the reaction
echo "Editing ml_test_$iteration.cpp ... "
echo ""

cp "$template_path/ml_test.cpp_template" ml_test_$iteration.cpp

sed -i "s/int iteration =/int iteration = ${iteration};/g" ml_test_$iteration.cpp

sed -i "s/double redshift =/double redshift = ${z1};/g" ml_test_$iteration.cpp

sed -i "s/int Nk =/int Nk = ${NK};/g" ml_test_$iteration.cpp
sed -i "s/double kmax =/double kmax = ${kmax};/g" ml_test_$iteration.cpp
sed -i "s/double kmin =/double kmin = ${kmin};/g" ml_test_$iteration.cpp

sed -i "s/double h =/double h = ${smallh};/g" ml_test_$iteration.cpp
sed -i "s/double n_s =/double n_s = ${ns};/g" ml_test_$iteration.cpp
sed -i "s/double Omega_m =/double Omega_m = ${omm};/g" ml_test_$iteration.cpp
sed -i "s/double Omega_b =/double Omega_b = ${omb};/g" ml_test_$iteration.cpp
sed -i "s/double Omega_nu =/double Omega_nu = ${omnu};/g" ml_test_$iteration.cpp
sed -i "s/double As =/double As = ${As};/g" ml_test_$iteration.cpp
sed -i "s/double p1 =/double p1 = ${param1};/g" ml_test_$iteration.cpp
sed -i "s/double wa =/double wa = ${param2};/g" ml_test_$iteration.cpp
sed -i "s/double xi =/double xi = ${param3};/g" ml_test_$iteration.cpp


#echo "Running ReACT ... "
#echo ""

# Attempt compilation with timeout
#if timeout 10s g++ -I/${reactdir}/include -L/${reactdir}/lib ml_test_$iteration.cpp -lcopter -lgsl -lstdc++ -o test_$iteration; then
#    echo "Compilation succeeded for iteration ${iteration}"

    # Attempt to run the binary with a timeout
#    if timeout 30s ./test_$iteration; then
#        echo "Execution succeeded for iteration ${iteration}"
#        rm test_$iteration
#    else
#        echo "Execution timed out or failed for iteration ${iteration}"
#        awk "NR==${iteration}" pipe_cosmopower_parallel/"$param_path" >> "$failed_log_path"
 #   fi

#else
#    echo "Compilation failed or timed out for iteration ${iteration}"
#    awk "NR==${iteration}" pipe_cosmopower_parallel/"$param_path" >> "$failed_log_path"
#fi


# Clean up
#rm test_$iteration
#rm transfers/test_$iteration\_transfer.dat
#rm transfers/test_$iteration\_transfer_lcdm.dat
#rm transfers/test_$iteration\_transfer_lcdm_nonu.dat
#rm ml_test_$iteration.cpp



echo "Running ReACT ... "
echo ""

# Attempt to compile ReACT C++ file
if timeout 10s g++ -I/${reactdir}/include -L/${reactdir}/lib ml_test_$iteration.cpp -lcopter -lgsl -lstdc++ -o test_$iteration; then
    echo "Compilation succeeded for iteration ${iteration}"

    # Attempt to run the compiled binary
    if timeout 30s ./test_$iteration; then
        echo "Execution succeeded for iteration ${iteration}"
    else
        echo "ReACT timed out for iteration ${iteration}" >> "$failed_log_path_verb"
        awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
        rm -f test_$iteration
        rm -f ml_test_$iteration.cpp
        rm -f transfers/test_${iteration}_transfer*.dat
        continue
    fi

else
    echo "ReACT compilation failed or timed out for iteration ${iteration}" >> "$failed_log_path_verb"
    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
    rm -f test_$iteration
    rm -f ml_test_$iteration.cpp
    rm -f transfers/test_${iteration}_transfer*.dat
    continue
fi

# Clean up after success
rm -f test_$iteration
rm -f ml_test_$iteration.cpp
rm -f transfers/test_${iteration}_transfer*.dat



# PART 4: Get non-linear LCDM and pseudo spectra with HMCODE2020

echo ""

# Move pseudos and lcdm linear spectra to hmcode directory
mv working_cp/pseudo_$iteration.txt ${hmcodedir}
mv working_cp/lcdm_$iteration.txt ${hmcodedir}


# Go to the HMCode2020 directory
cd ${hmcodedir}


# Specific scalefactor for hmcode
a1=$(awk "BEGIN {print 1/($z1 + 1)}")

echo "Running HMCode2020 for redshift ${z1}"
echo ""

# Run HMCode to get pseudos
./bin/HMcode ${omm} ${omb} ${smallh} ${ns} 0.8 -1.0 pseudo_${iteration}.txt 1e8 ${a1} ${NK} ${kmin} ${kmax} hmcode_${iteration}.txt > /dev/null

# clip header
#tail -n +2 hmcode_${iteration}.txt > hmcode_$iteration.tmp && mv hmcode_$iteration.tmp hmcode_$iteration.dat

# Handle the file safely
tail -n +2 hmcode_${iteration}.txt > hmcode_${iteration}.tmp
if [ -s hmcode_${iteration}.tmp ]; then
    mv hmcode_${iteration}.tmp hmcode_${iteration}.dat
else
    echo "Warning: Empty or missing hmcode_${iteration}.txt for iteration $iteration" >> "$failed_log_path"
    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
    rm -f hmcode_${iteration}.tmp
fi


# Move pseudos to the ReACT working directory for combination with the reaction
mv hmcode_$iteration.dat ${reactdir}/examples/working_cp

echo "Running HMCode2020 for redshift ${z1}"
echo ""

# Run HMCode to get LCDM
./bin/HMcode ${omm} ${omb} ${smallh} ${ns} 0.8 -1.0 lcdm_${iteration}.txt 1e8 ${a1} ${NK} ${kmin} ${kmax} hmcode_lcdm_${iteration}.txt > /dev/null

# clip header
#tail -n +2 hmcode_lcdm_${iteration}.txt > hmcode_lcdm_$iteration.tmp && mv hmcode_lcdm_$iteration.tmp hmcode_lcdm_$iteration.dat


# Clip and handle the file safely
tail -n +2 hmcode_lcdm_${iteration}.txt > hmcode_lcdm_${iteration}.tmp
if [ -s hmcode_lcdm_${iteration}.tmp ]; then
    mv hmcode_lcdm_${iteration}.tmp hmcode_lcdm_${iteration}.dat
else
    echo "Warning: Empty or missing hmcode_lcdm_${iteration}.txt for iteration $iteration" >> "$failed_log_path"
    awk "NR==${iteration}" "$param_path" >> "$failed_log_path"
    rm -f hmcode_lcdm_${iteration}.tmp
fi


# Move LCDM spectra  to the ReACT directory
mv hmcode_lcdm_$iteration.dat ${reactdir}/examples/working_cp

# Clean up
echo "Clearing HMcode directory"

rm pseudo_$iteration.txt
rm hmcode_$iteration.txt
rm lcdm_$iteration.txt
rm hmcode_lcdm_$iteration.txt


# PART 5: Combine pseudo with reaction and LCDM non-linear to get Boost

# Back to pipeline directory
cd ${reactdir}/examples


# get combine script from template
cp "$template_path/combine.cpp_template" combine_$iteration.cpp

echo "Editing combine_$iteration.cpp ... "
echo ""

# Edit combine file
sed -i  "s/int batchno =/int batchno = ${boostindex};/g" combine_$iteration.cpp
sed -i  "s/int iteration =/int iteration = ${iteration};/g" combine_$iteration.cpp
sed -i  "s/double H0 =/double H0 = ${hubble};/g" combine_$iteration.cpp
sed -i  "s/double ns =/double ns = ${ns};/g" combine_$iteration.cpp
sed -i  "s/double Omega_m =/double Omega_m = ${omm};/g" combine_$iteration.cpp
sed -i  "s/double Omega_b =/double Omega_b = ${omb};/g" combine_$iteration.cpp
sed -i  "s/double Omega_nu =/double Omega_nu = ${omnu};/g" combine_$iteration.cpp
sed -i  "s/double As =/double As = ${As};/g" combine_$iteration.cpp
sed -i  "s/double p1 =/double p1 = ${param1};/g" combine_$iteration.cpp
sed -i "s/double wa =/double wa = ${param2};/g" combine_$iteration.cpp
sed -i "s/double xi =/double xi = ${param3};/g" combine_$iteration.cpp

sed -i  "s/double z =/double z = ${z1};/g" combine_$iteration.cpp


echo "Running combine script for P-non-lin ${iteration}"

g++ -I/${reactdir}/include -lgsl -lstdc++ -L/${reactdir}/lib -lcopter combine_$iteration.cpp -o combine_$iteration

time ./combine_$iteration

echo "Cleaning up"

# Clean up
rm combine_$iteration.cpp
rm combine_$iteration

rm working_cp/reaction_$iteration.dat
rm working_cp/hmcode_$iteration.dat
rm working_cp/hmcode_lcdm_$iteration.dat

echo "Done"
echo ""
echo ""
echo ""

# back to CP directory 
cd "$project_root"


done
