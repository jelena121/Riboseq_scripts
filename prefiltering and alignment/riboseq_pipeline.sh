#rename files
#requires the file naming_scheme.txt as input
# 1st column = old name
# 2nd column = desired new name
perl ~/software/scripts/renamefiles.pl

# initial QC
PATH=$PATH\:~/software/fastqc ; export PATH
fastqc raw_data/*
mkdir raw_data_qc
mv raw_data/*fastqc* raw_data_qc

# adapter trimming