# Setup users

# Process for installing Jenkins on a standalone server.
# Start with a base Ubuntu Xenial system
# install initial packages, including Java8
apt-get update &&\
 apt-get install -y wget apt-transport-https ca-certificates curl gnupg2 software-properties-common openjdk-8-jdk


# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update && apt-get install -y docker-ce

service docker start
# test docker
docker run hello-world

# install jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update && apt-get install -y jenkins

# add jenkins user to docker group
gpasswd -a jenkins docker

service jenkins start

# look for initial password in log file
cat /var/log/jenkins/jenkins.log

# access jenkins on http://<ip>:8080


# add github auth plugin and configure
# add blue ocean plugin
# add pipeline for test project that can be found here: https://github.com/InformaticsMatters/example-java-servlet
