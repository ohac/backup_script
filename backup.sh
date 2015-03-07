#!/bin/sh -e

set -e

THISDIR=`dirname "$0"`
cd $THISDIR

# settings
file=backup.tar.gz.gpg
recipient=B8440253
s3Key=xxxxxxxxxxxxxxxxxxxx
s3Secret=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
bucket=sighash
targetdir=data
sudocmd="sudo -u core"

if [ -e settings ]; then
  . ./settings
fi

taropt=""
if [ -e "${file}" ]; then
  if [ `date +%d` -ne '01' ]; then
    after=`ls -on --fu ${file} | awk '{print $5}'`
    taropt="-N ${after}"
    file="diff-${file}"
  fi
fi

sudo tar -c --gzip ${taropt} "${targetdir}" \
  | ${sudocmd} gpg -e -r "${recipient}" > "${file}"
name="${file}"
resource="/${bucket}/${name}"
contentType="application/pgp-encrypted"
dateValue=`date -R`
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`
curl -X PUT -T "${file}" \
  -H "Host: ${bucket}.s3.amazonaws.com" \
  -H "Date: ${dateValue}" \
  -H "Content-Type: ${contentType}" \
  -H "Authorization: AWS ${s3Key}:${signature}" \
  https://${bucket}.s3.amazonaws.com/${name}
