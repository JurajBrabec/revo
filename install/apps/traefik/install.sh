#!/bin/bash

if [ ! -d ${PROJECT_ROOT}/config ]; then
  echo -e "\nRun setup.sh." | tee -a $log_file
  exit
fi

conf=${PROJECT_ROOT}/config/traefik

mkdir -p $conf/certs
cp -rf ./config/* $conf

sed -i 's/${DOMAIN}/'${DOMAIN}'/' $conf/traefik.yml

#generate-certificates

certs=${conf}/certs
ext_file=/tmp/domains.ext
names=($SERVICES)

if [ ! -f $certs/RootCA.crt ]; then
  echo -e "Generating root cerificates for ${ROOT_CA_SUBJECT} ..." | tee -a $log_file
  openssl req -x509 -nodes -new -sha256 -days 1024 -newkey rsa:2048 -keyout $certs/RootCA.key -out $certs/RootCA.pem -subj ${ROOT_CA_SUBJECT} >>$log_file 2>&1
  openssl x509 -outform pem -in $certs/RootCA.pem -out $certs/RootCA.crt >>$log_file 2>&1
fi

echo -e "Generating certificates for ${CERT_SUBJECT} ..." | tee -a $log_file

cat > $ext_file << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
EOF

for i in ${!names[@]}; do
  echo DNS.$(($i+1)) = ${names[$i]}.${DOMAIN} >> $ext_file
done

openssl req -new -nodes -newkey rsa:2048 -keyout $certs/traefik.key -out $certs/traefik.csr -subj ${CERT_SUBJECT} >>$log_file 2>&1
openssl x509 -req -sha256 -days 1024 -in $certs/traefik.csr -CA $certs/RootCA.pem -CAkey $certs/RootCA.key -CAcreateserial -extfile $ext_file -out $certs/traefik.crt >>$log_file 2>&1

rm $ext_file
