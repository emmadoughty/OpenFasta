# OpenFasta

**Rearranges and re-orientates fasta files**

OpenFasta rearranges and re-orientates fasta files to begin with a user-provided "opening sequence" and proceed in the same direction (forward/reverse) as that opening sequence. The opening sequence file contains only the nuleotide sequence where you'd like your rearranged fasta file to begin. The script can be applied to a single file or a directory containing multiple fasat files with any file ending.



**Usage:**

NB: Do not use both -f and -d 

OpenFasta.sh -o [FILE] -f [FILE] -d [DIRECTORY]
  -o \t File containing opening sequence only
  -f \t Fasta file to reorientate
  -d \t Directory of fasta files to reorientate

Written for use with Ubuntu 16.
