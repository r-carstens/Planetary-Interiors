#!/bin/bash

# Initialising the temperature range
tempRange=`seq 0 100 5000`

# Looping through each temperature in the range

for currTemp in $tempRange; do
echo $currTemp

##### Creating a python file to update the output file at a given temperature
cat > updated_get_new_output_data.py << EOF
import os
import numpy as np
import matplotlib.pyplot as plt

# Definining a compound
class Compound:

    name = ""
    composition = ""
    enthalpy = 0
    ts_data = np.empty(0)
    gibbs_data = ""
    temp_data = np.empty(0)
    num_atoms = 0

# Determining the ts data
def get_ts_data():

    all_compounds = []

    for file in os.scandir(os.getcwd()):
        if '.dat' in file.name and 'output' not in file.name:

            curr_compound = Compound()
            curr_compound.name = file.name[:-4]

            with open(file, 'r') as f:

                stripped_temps = f.readline().strip()
                temps = stripped_temps.split()[1:]

                for line in f.readlines():

                    ts_data = line.split()[1:]

            curr_compound.temp_data = np.array(temps, dtype=float)
            curr_compound.ts_data = np.array(ts_data, dtype=float)

            all_compounds.append(curr_compound)

    return all_compounds


# Making res file copies with enthalpy terms replaced with Free Energy terms
def get_res_copy(all_compounds):

    for compound in all_compounds:
        required_res_file = compound.name + '.res'

        for file in os.scandir(os.getcwd()):
            if file.name == required_res_file:

                out_file = open(compound.name + '-copy.res', 'w')

                with open(file.name, 'r') as in_file:
                    for line in in_file.readlines():

                        if line.startswith("TITL"):

                            split_line = line.split()
                            compound.enthalpy = float(split_line[4])

                            temp_pos = np.where($currTemp == compound.temp_data)[0][0]
                            ts_data = compound.ts_data[temp_pos]
                            
                            # Determining the Gibbs value
                            curr_gibbs = compound.enthalpy + compound.ts_data[temp_pos]
                            split_line[4] = str(curr_gibbs)

                            new_line = ' '.join(split_line) + '\n'
                            out_file.write(new_line)

                        else:

                            out_file.write(line)

                out_file.close()


all_compounds = get_ts_data()
get_res_copy(all_compounds)

EOF

python3 updated_get_new_output_data.py

# Moving all the copied res files elsewhere
mv *-copy.res ../new_output_files/
cd ../new_output_files

# Producing the convex hull using AIRSS
ca -m -l | sort -n -k6 -k5 > "new_data_$currTemp.dat"

rm *-copy.res
cd ../dat_files

done

