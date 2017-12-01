#!/usr/bin/env bash
# This needs JDK to be present. `sudo yum install -y java-1.8.0-openjdk`

set -e pipefail

./validate.sh



if [ ! -d certs ]; then
  mkdir certs
fi

cd certs
rm -f *

echo "Generating CA certificate"
openssl req -new -newkey rsa:4096 -x509 \
    -keyout xpaas.key -out xpaas.crt -days 365 \
    -subj "/CN=xpaas-sso-demo.ca"\
    -passout env:OC_CERTS_PASSWORD

echo "Generating SSL certificate"
keytool -genkeypair -keyalg RSA -keysize 2048 \
    -dname "CN=secure-sso-sso-app-demo.openshift32.example.com" \
    -alias sso-https-key -keystore sso-https.jks \
    -storepass $OC_CERTS_PASSWORD -keypass $OC_CERTS_PASSWORD

echo "Generating Certificate Sign Request"
keytool -certreq -keyalg rsa \
    -alias sso-https-key -keystore sso-https.jks -file sso.csr \
    -storepass $OC_CERTS_PASSWORD

echo "Signing the Certificate Sign Request"
openssl x509 -req -CA xpaas.crt \
    -CAkey xpaas.key -in sso.csr \
    -out sso.crt -days 365 -CAcreateserial \
    -passin env:OC_CERTS_PASSWORD

echo "Importing the CA into the SSL keystore"
keytool -import -file xpaas.crt \
    -alias xpaas.ca -keystore sso-https.jks \
    -storepass $OC_CERTS_PASSWORD -noprompt

echo "Importing the signed Certificate Sign Request into the SSL keystore"
keytool -import -file sso.crt \
    -alias sso-https-key -keystore sso-https.jks \
    -storepass $OC_CERTS_PASSWORD -noprompt

echo "Importing the CA into a new JGroups keystore"
keytool -import -file xpaas.crt \
    -alias xpaas.ca -keystore truststore.jks \
    -storepass $OC_CERTS_PASSWORD -noprompt

echo "Generating secure key for the JGroups keystore"
keytool -genseckey \
    -alias jgroups -storetype JCEKS -keystore jgroups.jceks \
    -storepass $OC_CERTS_PASSWORD -keypass $OC_CERTS_PASSWORD -noprompt

echo "Certificates generated. Find them in the certs directory"
cd ..