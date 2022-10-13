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
curl -fsSL https://updates.jenkins-ci.org/latest/configuration-as-code.hpi --output /tmp/configuration-as-code.hpi &&
sudo apt-get update &&
sudo apt install openjdk-11-jre -y &&
sudo apt install jenkins -y &&
sudo service jenkins stop &&
sudo tar cvfJ /tmp/configuration-as-code.hpi /var/lib/jenkins/plugins/ &&
sudo mv /var/lib/jenkins /home &&
sudo ln -s /home/jenkins /var/lib/jenkins &&
sudo service jenkins start
