import os
import numpy as np


# Defining a compound
class Compound:
    name = ""
    composition = ""
    enthalpy = 0
    num_atoms = 0
    ts_data = np.empty(0)
    gibbs_data = np.empty(0)
    temp_data = np.empty(0)


# Determining the ts data
def get_ts_data(compound, file_name):

    # Reads the TS data provided in the file (assumes specific formatting which may need to be changed if required)
    temperatures = np.loadtxt(file_name, delimiter=' ', dtype=str, max_rows=1)[1:]
    ts_data = np.loadtxt(file_name, delimiter=' ', dtype=str, skiprows=1)[1:-1]

    # Returns the required arrays in order to be added to the current compound's class instance
    compound.temp_data = temperatures.astype(float)
    compound.ts_data = ts_data.astype(float)

    return compound


# Making res file copies with enthalpy terms replaced with Free Energy terms
def get_res_copy(compound, required_res_file):

    # Stores the data of the original .res and makes a copy that can be updated
    in_file = np.loadtxt(required_res_file, delimiter='\n', dtype=str)
    data_copy = np.copy(in_file)

    for counter, line in enumerate(in_file):

        # Assumes AIRSS .res file formatting
        if line.startswith('TITL'):

            # Determines the current compound's enthalpy
            split_line = line.split()
            compound.enthalpy = float(split_line[4])

            # Locates the required TS data at the given temperature
            temp_pos = np.where($currTemp == compound.temp_data)[0][0]
            required_ts_data = compound.ts_data[temp_pos]

            # Replaces the enthalpy value with the compound's Gibbs Free Energy at the given temperature
            curr_gibbs = compound.enthalpy + required_ts_data
            split_line[4] = str(curr_gibbs)

            # Updates the copied file and leaves the original unchanged
            data_copy[counter] = ' '.join(split_line)

    return data_copy


##### Determining all the compounds for which TS data is provided  (assuming the dat file is formatted 'compound_name.dat')

all_compounds = []

for file in os.scandir(os.getcwd()):

    # Locating all the .dat files containing the TS data
    if '.dat' in file.name and 'output' not in file.name:

        # Creating a class instance for the given compound
        current_compound = Compound()
        current_compound.name = file.name[:-4]

        # Extracting and storing its TS data
        get_ts_data(current_compound, file)
        all_compounds.append(current_compound)


##### Creating an updated .res file which replaces each compounds enthalpy with its Gibbs Energy at the given temperature

for compound in all_compounds:

    # Assumes the .res files are formatted 'compound_name.res'
    required_res_file = compound.name + '.res'

    for file in os.scandir(os.getcwd()):

        # Locates the .res file for a given compound
        if file.name == required_res_file:

            # Gets a .res file copy with the enthalpy value replaced
            data_copy = get_res_copy(compound, required_res_file)

            # Creates the new file in the same repository
            with open(compound.name + '-copy.res', 'w') as out_file:
                out_file.writelines('\n'.join(data_copy))
