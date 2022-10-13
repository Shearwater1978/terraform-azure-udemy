#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null &&
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null &&
sudo apt-get update &&
sudo apt install openjdk-11-jre -y &&
sudo apt install jenkins -y &&
sudo service jenkins stop &&
sudo mkdir -p /var/lib/jenkins/plugins &&
sudo curl -fsSL https://updates.jenkins-ci.org/latest/configuration-as-code.hpi --output /var/lib/jenkins/plugins/configuration-as-code.hpi &&
sudo mv /var/lib/jenkins /home &&
sudo ln -s /home/jenkins /var/lib/jenkins &&
sudo service jenkins start
