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

# clean cloudinit files (Assuming we are on ubuntu)
echo <<'EOF' > /var/lib/cloud/instance/user-data.txt.i
Content-Type: multipart/mixed; boundary="===============6152687179676181889=="
MIME-Version: 1.0
Number-Attachments: 1

--===============6152687179676181889==
MIME-Version: 1.0
Content-Type: text/x-shellscript
Content-Disposition: attachment; filename="part-001"

#!/bin/bash
--===============6152687179676181889==--
EOF

echo <<'EOF' > /var/lib/cloud/instance/user-data.txt
#!/bin/bash
EOF

echo <<'EOF' > /var/lib/cloud/instance/scripts/part-001
#!/bin/bash
EOF
cloud-init clean
rm -- "$0" 