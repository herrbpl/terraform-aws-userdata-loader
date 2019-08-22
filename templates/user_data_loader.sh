#!/bin/bash
# Load initial script from S3 bucket
exec > >(tee /var/log/user-data-loader.log|logger -t user-data -s 2>/dev/console) 2>&1

apt-get install s3cmd zip unzip -qq

# download script & execute
rm -f "./${bucket_key}"
rm -f "./${filename}"
s3cmd --access_key=${bucket_accesskey} --secret_key=${bucket_secret} get "s3://${bucket_name}/${bucket_key}" "${bucket_key}"

# decrypt & unzip
openssl aes-256-cbc -salt -a -d -pbkdf2 -k ${passphrase} -in "${bucket_key}" -out "./${filename}.zip"
unzip "./${filename}.zip"
rm -f "./${filename}.zip"
rm -f "./${bucket_key}"

# execute
echo "User data script starting"
chmod u+x "./${filename}"
./"${filename}"
echo "User data script completed"
rm -f "./${filename}"
rm -- "$0"