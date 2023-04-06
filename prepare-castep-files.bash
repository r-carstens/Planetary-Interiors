#!/bin/bash

# Loops through subdirectories (expects subdirectory to have the same name as the .res file)
for currDir in */; do

cd $currDir

# Coverts the .res file into a .cell file
cabal res cell < ${PWD##*/}.res > ${PWD##*/}.cell

# Appends the required blocks for the supercell method to the .cell file
cat << EOF >> ${PWD##*/}.cell

# This block can be filled in once the supercell matrix has been determined
%BLOCK PHONON_SUPERCELL_MATRIX
1 0 0
0 1 0
0 0 1
%ENDBLOCK PHONON_SUPERCELL_MATRIX

symmetry_tol 0.000001
symmetry_generate
snap_to_symmetry

KPOINT_MP_SPACING 0.04

SUPERCELL_KPOINTS_MP_SPACING 0.04

# Pseudopotentials for HCNO-Optimised dataset:
%block species_pot
O 2|1.1|15|18|20|20:21(qc=7)[]
N 2|1.1|14|16|18|20:21(qc=7)
H 1|0.6|13|15|17|10(qc=8)[]
C 2|1.4|10|12|13|20:21(qc=7)[]
%endblock species_pot

%BLOCK PHONON_GAMMA_DIRECTIONS
0 0 0
0 0 1
0 1 0
1 0 0
%ENDBLOCK PHONON_GAMMA_DIRECTIONS

EOF

# Creates a .param file with the same name as the directory and .cell file
cat > ${PWD##*/}.param << EOF 

task            : phonon
xc_functional        : PBE
cut_off_energy        : 1000
WRITE_CELL_STRUCTURE    : true
opt_strategy           : Speed
finite_basis_corr    :     2
finite_basis_npoints     :  3

# Phonon method
# Ultrasoft PP's - finite displacement
phonon_method  : finitedisplacement

# Phonon postprocessing on/off
PHONON_FINE_METHOD : SUPERCELL

continuation: default
BACKUP_INTERVAL: 3600
iprint: 1
run_time: 84600

EOF

# Returns to the main directory
cd ..

done
