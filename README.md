# ega-file-uploader-c4gh-docker
## Example invocation
```
docker run -it \
   -e "SFTP_USER=XXX" \
   -e "SFTP_PASS=XXX" \
   -v <path_holding_data_folder>:/work \
   ah3inz3l/ega-file-uploader-c4gh \
   encrypt \
   upload \
   -C /work \
   -i ./<data> \
   -o ./<data_enc>
```

## Usage
```
USAGE: /entrypoint.sh encrypt|upload [encrypt|upload] -o output [-i input -j num_jobs -C work_dir]
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
environment variables SFTP_USER and SFTP_PAS
```