#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y &&
DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y tzdata \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null &&
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt install openjdk-11-jre -y
sudo apt install jenkins -y
sudo curl -fsSL http://0.0.0.0:8080/jnlpJars/jenkins-cli.jar --output /var/lib/jenkins/jenkins-cli.jar
export VERSION=$(wget -q -O - https://github.com/jenkinsci/plugin-installation-manager-tool/releases/latest | grep -E "<h1 data-view-component.*>.*</h1>" | grep -E -o "[0-9]{1,}.[0-9]{1,}.[0-9]{1,}")
curl -fsSL https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/$VERSION/jenkins-plugin-manager-$VERSION.jar --output /tmp/jenkins-plugin-manager.jar
sudo cp /tmp/jenkins-plugin-manager.jar /var/lib/jenkins/
sudo mkdir -p /var/lib/jenkins/plugins /var/lib/jenkins/init.groovy.d
sudo -i -u jenkins java -jar /var/lib/jenkins/jenkins-plugin-manager.jar -f /tmp/plugins.txt -d /var/lib/jenkins/plugins/
sudo service jenkins stop
sudo curl -fsSL https://updates.jenkins-ci.org/latest/configuration-as-code.hpi --output /var/lib/jenkins/plugins/configuration-as-code.hpi
sudo echo `jenkins --version` > /var/lib/jenkins/jenkins.install.UpgradeWizard.state
sudo mv /var/lib/jenkins /opt
sudo chown -R jenkins: /opt/jenkins
sudo ln -s /opt/jenkins /var/lib/jenkins
sudo service jenkins start
pass=`sudo cat /var/lib/jenkins/secrets/initialAdminPassword` && echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("${username}", "${password}")' | sudo java -jar /var/lib/jenkins/jenkins-cli.jar -auth admin:$pass -s http://localhost:8080/ groovy =
