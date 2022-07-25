#!/bin/bash
cat <<EOF >/home/ubuntu/user-data.sh
#!/bin/bash
wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x ./jq
sudo cp jq /usr/bin
curl --request POST 'https://api.github.com/repos/your_user/your_repository_name/actions/runners/registration-token' --header "Authorization: token ${personal_access_token}" > output.txt
runner_token=\$(jq -r '.token' output.txt)
mkdir ~/actions-runner
cd ~/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.263.0/actions-runner-linux-x64-2.263.0.tar.gz
tar xzf ~/actions-runner/actions-runner-linux-x64-2.263.0.tar.gz
rm ~/actions-runner/actions-runner-linux-x64-2.263.0.tar.gz
~/actions-runner/config.sh --url https://github.com/your_user/your_repository_name/ --token \$runner_token --name "Github EC2 Runner" --unattended
~/actions-runner/run.sh
EOF
cd /home/ubuntu
chmod +x user-data.sh
/bin/su -c "./user-data.sh" - ubuntu | tee /home/ubuntu/user-data.log