#!/bin/bash
# Open a fasta file at any given position
# Script by Emma Doughty (e.doughty@bham.ac.uk)
####################################################################
## Set-up for running script

set -e # Causes script to abort if any command exits with a non-zero exit status (i.e. if it fails)

## Function for displaying help message
usage() {
  echo -e "\nUsage: $0 -o [FILE] -f [FILE] -d [DIRECTORY]\n
\t-o \t File containing opening sequence only
\t-f \t Fasta file to reorientate
\t-d \t Directory of fasta files to reorientate \n
NB: Do not use both -f and -d \n" 1>&2
}

## Sets options for running script as described above
while getopts "o:f:d:h" opt; do
  case "${opt}" in
  o )
  open="$OPTARG"; len=$(cat "$open" | wc -c)
  ;;
  f )
  ori_init="$OPTARG";
  ;;
  d )
  dir="$OPTARG";
  ;;
  h )
  usage
  exit 0
  ;;
  esac
done

####################################################################
### Opens the plasmid fasta at the opening sequence, if possible

## Defines the header and sequence section of the plasmid fasta
define_sections() {
  # Sequence is either whitespace or start of line followed by unbroken non-whitespace, possibly followed by more whitespace
  seq=$(grep -o '\(^\|\s\)\S\+\s*$' "${to_def}" | tail -n1 | sed 's/\s//g')
  # Find the first line that is not blank or just whitespace
  header=''
  headline=0
  while [[ -z "${header}" ]]
  do
    # Add 1 to the number of lines to check (starts at 0, so becomes 1 first time through)
    headline=$(( "${headline}" + 1 ))
    # Get the first $headline lines, take the last of them and trim off any trailing whitespace
    header=$(head -n"${headline}" "${to_def}" | tail -n1 | sed 's/\s*$//')
    # End of loop, will now test if the last line read is blank again, if not loop ends and sets the header
  done
   # Header now contains the first non-blank line of the file.  Need to remove the seq if single line fasta
   header=${header%"s/\s*${seq}\s*$"}
}

## Unsets the variables for header and seq
unset_vars() {
unset header
unset seq
}

## Rearranges the plasmid fasta to the correct opening position
process() {
  out="${ori%.*}"; out="${out}"_open.fa; tmp="${out}"_tmp
  to_def="${ori}"; define_sections
  echo -e "${header}" > "${tmp}"
  grep -o "${open}.*$" "${ori}" >> "${tmp}"
  str=$(grep -o "\S*${open}" "${ori}"); beg=${str%%"${open"}}
  sed -e "$ s/$/${beg}/" "${tmp}" > "${out}"
  rm "${tmp}"
  echo -e "\nRearranging ${ori} and saving as ${out}"
}
## Gets the fasta into the correct orientation to be rearranged and sends to process, or confirms that opening sequence cannot be found once in fasta in any orientation/split pattern
reverse() {
  rev_init="${init%.*}"_rev.fa
  to_def="${init}"; define_sections
  echo "${header}" > "${rev_init}"
  echo "${seq}" | tr "[ATGCatgc]" "[TACGtacg]" | rev >> "${rev_init}"
  unset_vars
}
split() {
  spl_init="${to_spl%.*}"_spl.fa
  to_def="${to_spl}"; define_sections
  first=$(echo "${seq}" | cut -c1-"${len}"); last="${seq#"first"}"
  echo -e "${header}\n${last}${first}" > ${spl_init}
  unset_vars
}
identify_ori() {
  if [[ $(grep -c "${open}" "${init}") -eq 1 ]]; then
    ori="${init}"; process;
  else
    reverse;
    if [[ $(grep -c "${open}" "${rev_init}") -eq 1 ]]; then
      ori="${rev_init}"; process; rm "${rev_init}"
    else
      rm "${rev_init}"; to_spl="${init}"; split
      if [[ $(grep -c "${open}" "${spl_init}") -eq 1 ]]; then
        ori="${spl_init}"; process; rm "${spl_init}"
      else
        rm "${spl_init}"; reverse; to_spl="${rev_init}"; split
        if [[ $(grep -c "$open" "${spl_init}") -eq 1 ]]; then
          ori="${spl_init}"; process; rm "${spl_init}"; rm "${rev_init}"
        else
          rm "${spl_init}"; rm "${rev_init}"
          echo -e "\n${init} does not contain the specified opening sequence or it is present in more than one copy"
        fi
      fi
    fi
  fi
}
####################################################################
### Checks script input files/directory
## Checks that the input fasta is indeed a single fasta or else tells you that its a multifasta or not a fasta at all
check_file() {
  if [[ $(head -c 1 "${ori_init}") == '>' ]]; then # Is it a fasta file? (first character is >)
    if [[ $(grep -c ">" "${ori_init}") -eq 1 ]]; then
      if [[ $(cat "${ori_init}" | wc -l) -gt 2 ]]; then
        echo "rearranging"
        init="${ori_init}_rearranged"
        awk '/^>/ {printf("%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < "$ori_init" > $init
        else init="${ori_init}"
      fi
      identify_ori
    else # Is fasta but not exactly 1 >, therefore multifasta
      echo -e "\nWARNING:"${ori_init}" is a multifa! Split and try again."
    fi
  else
    echo -e "\nWARNING:"${ori_init}" is not a fasta file!"
  fi
}
#Makes multiline fasta into single line fasta
## Checks that the necessary input files have been given to the script and selects to run through whole directory of files if an individual file is not specified
if [[ -z "${open}" ]]; then
  usage; exit 0
else
  open="$(< "${open}")" # Stores the content of the file as the variable (i.e. doesn't save the file name as the variable)
fi
if [[ -n "$ori_init" && -n "$dir" ]]; then # Exits if both -f and -d are set
  usage; exit 1
fi
if [[ -z "${ori_init}" ]]; then
  if [[ -z "${dir}" ]]; then
    usage; exit 1 # Exits if  neither -f nor -d are set
  else
    for f in "${dir}"/*; do ori_init=$f; check_file; done # Proceeds for directory of files
  fi
else
  check_file # Proceeds for single file input
fi
