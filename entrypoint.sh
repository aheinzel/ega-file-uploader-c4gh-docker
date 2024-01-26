#!/bin/bash

set -e

USAGE=$(cat << EOF
USAGE: ${0} encrypt|upload [encrypt|upload] -o output [-i input -j num_jobs -C work_dir]
Actions:
 encrypt: run crypt4gh to encrypt all files in the input directory (-i)
 upload: upload the given output directory (-o) to EGA

Both actions can be run at once.

Options:
 -i input directory containing files to be encrytped
 -o output directory for encrypted files; when action encrypt
    is used this directory must not exist prior to the execution;
    command upload will upload the entire output directory to EGA
 -j number of files that will be processed in parallel by crypt4gh (default 1)
 -C change to directory before performing any work

EGA user credentials for uploading must be provided via the
environment variables SFTP_USER and SFTP_PASS
EOF
)

function print_usage_and_die(){
   echo "${USAGE}" >&2
   exit 1
}

#parse actions
while [[ $# -gt 0 ]] && { echo "${1}" | grep -v "^-" > /dev/null || [[ "${1}" == "-h" ]]; }
do
   case "$1" in
      encrypt)
         do_encrypt=1
         ;;
      upload)
         do_upload=1
         ;;
      -h)
         print_usage_and_die
         ;;
      *)
         echo "ERROR: unknown action ${1}" >&2
         print_usage_and_die
   esac

   shift
done

num_jobs=1
#parse options
while getopts "i:o:j:C:" option
do
   case "${option}" in
      i)
         input_dir="${OPTARG}"
         ;;
      o)
         output_dir="${OPTARG}"
         ;;
      j)
         num_jobs="${OPTARG}"
         ;;
      C)
         change_to="${OPTARG}"
         ;;
      *)
         echo "ERROR: invalid option encountered" >&2
         print_usage_and_die
   esac
done


if [[ -n "${change_to}" ]]
then
   cd "${change_to}"
fi


if [[ ! ( -v do_encrypt || -v do_upload ) ]]
then
   echo "ERROR: missing action" >&2
   print_usage_and_die
fi


if [[ -v do_encrypt ]]
then
   if [[ -z "${input_dir}" ]]
   then
      echo "ERROR: input dir (-i) must be set for encrypt" >&2
      print_usage_and_die
   fi

   if [[ -z "${output_dir}" ]]
   then
      echo "ERROR: output dir (-o) must be set for encrypt" >&2
      print_usage_and_die
   fi


   if [[ ! -d "${input_dir}" ]]
   then
      echo "ERROR: input dir (-i) must exist when encrypting" >&2
      print_usage_and_die
   fi


   if [[ -d "${output_dir}" ]]
   then
      echo "ERROR: output dir (-o) must not exist when encrypting" >&2
      print_usage_and_die
   fi
fi


if [[ -v do_upload ]]
then
   if [[ -z "${output_dir}" ]]
   then
      echo "ERROR: output dir (-o) must be set when uploading" >&2
      print_usage_and_die
   fi

   if [[ ! -v do_encrypt && ! -d "${output_dir}" ]]
   then
      echo "ERROR: output dir (-o) must exist when uploading" >&2
      print_usage_and_die
   fi

   if [[ -z "${SFTP_USER}" || -z "${SFTP_PASS}" ]]
   then
      echo "ERROR: EGA user credentials must be provided via env variables SFTP_USER and SFTP_PASS when uploading" >&2
      print_usage_and_die
   fi
fi


output_dir="$(readlink -f "${output_dir}")" #we later switch into the input dir, thus having an abs path for out ensure we will find the directory again


if [[ -v do_encrypt ]]
then
   mkdir "${output_dir}"
   cd "${input_dir}" #take care this would most likely break output paths unless we have an absolute path to the output folder
   find . -type f -print0 | parallel -0 -n 1 -j "${num_jobs}" crypt4gh_rec_ega --dest "${output_dir}"
fi


if [[ -v do_upload ]]
then
   export LFTP_PASSWORD="${SFTP_PASS}"
   lftp --env-password "sftp://${SFTP_USER}@inbox.ega-archive.org" -e "cd encrypted; mirror -R '""${output_dir}""'; bye"
fi
