# Setup users and turn off ssh login with root account and for all users with passwords (ssh keys only)
adduser USERNAME
adduser USERNAME sudo
echo YOUR-SSH-PUBLIC-KEY > ~/.ssh/authorized_keys
# at this point try if you can login via ssh with your ssh key loaded into the ssh agent (or pagaeant on windows)
# once this wors, edit /etc/ssh/sshd_config and disabled password login and login of the root user
sudo nano /etc/ssh/sshd_config
# comment out this section: PermitRootLogin without-password
# UsePAM no
# PasswordAuthentication no

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


# add github auth plugin and configure (under "Configure Global Security")
#    * you need to log in to github and at the OpenRiskNet organization under settings create a new OAuth application
#      and note the client id and secret
#    * Put in this information into jenkins, and set the desired permissions (e.g. make some github users admins in jenkins, 
#      give everyone the right to see jobs and create new ones)
# add blue ocean plugin
# add pipeline for test project that can be found here: https://github.com/InformaticsMatters/example-java-servlet

# Finally, set up nginx with lets encrypt for https access and enable this for jenkins by following these two walkthroughs:
# https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04
# https://www.digitalocean.com/community/tutorials/how-to-configure-jenkins-with-ssl-using-an-nginx-reverse-proxy
