#!/bin/bash

set -e

THISDIR=`dirname "$0"`
cd $THISDIR

# settings (common)
file=backup.tar.gz.gpg
recipients="-r B8440253"
targetdirs="data data2"
sudoroot="sudo"
sudocmd="sudo -u core"
splitsize=1024m
uploadto=s3
#uploadto=torrentsync

# settings (s3)
s3Key=xxxxxxxxxxxxxxxxxxxx
s3Secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
bucket=sighash

# settings (torrentsync)
lim="1m"
tracker="http://torrent.example.com:6969/announce"
datestr=`date +%Y%m%d_%H%M%S`
prefix="snapshot_${datestr}_"
uploader="http://torrentsync.example.com/upload"

if [ -e settings ]; then
  . ./settings
fi

taropt=""
suffix=full
fullname="${file}.${suffix}.aa"
if [ -e "${fullname}" ]; then
  mtime=`ls -on --time-style=+%s "${fullname}" | awk '{print $5}'`
  set +e
  rand=$((16#$(openssl rand -hex 1)))
  ((rand=rand%7))
  ((expires=mtime+(rand+30)*24*60*60))
  set -e
  if [ `date +%s` -lt $expires ]; then
    after=`ls -on --fu "${fullname}" | awk '{print $5}'`
    taropt="--newer-mtime ${after}"
    suffix=diff
  fi
fi
file="${file}.${suffix}"

${sudoroot} rm -f ${file}.*
${sudoroot} tar -c --gzip ${taropt} --exclude-caches ${targetdirs} \
  | ${sudocmd} gpg -e ${recipients} \
  | split -b ${splitsize} - "${file}."

upload() {
  name="$1"
  case $uploadto in
    s3)
      resource="/${bucket}/${name}"
      contentType="application/octet-stream"
      dateValue=`date -R`
      stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
      signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
      curl -X PUT -T "${name}" \
        -H "Host: ${bucket}.s3.amazonaws.com" \
        -H "Date: ${dateValue}" \
        -H "Content-Type: ${contentType}" \
        -H "Authorization: AWS ${s3Key}:${signature}" \
        https://${bucket}.s3.amazonaws.com/${name}
      ;;
    torrentsync)
      file="$1"
      name="${prefix}$1"
      curl --limit-rate ${lim} \
        -F "tracker=${tracker}" \
        -F "file=@${file};filename=${name}" \
        "${uploader}"
      ;;
  esac
}

for splitfile in ${file}.*; do
  upload $splitfile
done
