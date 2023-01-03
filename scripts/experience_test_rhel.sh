#!/usr/bin/env bash

# https://developers.supportbee.com/blog/setting-up-cucumber-to-run-with-Chrome-on-Linux/
# https://gist.github.com/curtismcmullan/7be1a8c1c841a9d8db2c
# http://stackoverflow.com/questions/10792403/how-do-i-get-chrome-working-with-selenium-using-php-webdriver
# http://stackoverflow.com/questions/26133486/how-to-specify-binary-path-for-remote-chromedriver-in-codeception
# http://stackoverflow.com/questions/40262682/how-to-run-selenium-3-x-with-chrome-driver-through-terminal
# http://askubuntu.com/questions/760085/how-do-you-install-google-chrome-on-ubuntu-16-04

# Versions
CHROME_DRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`
SELENIUM_STANDALONE_VERSION=3.8.1
SELENIUM_SUBDIR=$(echo "$SELENIUM_STANDALONE_VERSION" | cut -d"." -f-2)

echo "Downloading and installing dependencies..."
# subscription-manager repos --enable rhel-8-server-extras-rpms
# subscription-manager repos --enable rhel-8-server-optional-rpms
# cp ./google-chrome.repo /etc/yum.repos.d/google-chrome.repo
cat << EOF > /etc/yum.repos.d/google-chrome.repo
[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

# Remove existing downloads and binaries so we can start from scratch.
yum remove google-chrome-stable
rm ~/selenium-server-standalone-*.jar
rm ~/chromedriver_linux64.zip
rm /usr/local/bin/chromedriver
rm /usr/local/bin/selenium-server-standalone.jar

# Install dependencies.
yum update -y
yum install -y curl wget unzip java-1.8.0-openjdk-headless.x86_64 python3 python3-pip --skip-broken

# Install Chrome.
# yum install -y google-chrome-stable
wget https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
yum -y localinstall --enablerepo=ubi-8-appstream --enablerepo=ubi-8-baseos google-chrome-stable_current_x86_64.rpm

# Install ChromeDriver.
wget -N https://chromedriver.storage.googleapis.com/2.35/chromedriver_linux64.zip -P ~/
unzip ~/chromedriver_linux64.zip -d ~/
rm ~/chromedriver_linux64.zip
mv -f ~/chromedriver /usr/local/bin/chromedriver
chown root:root /usr/local/bin/chromedriver
chmod 0755 /usr/local/bin/chromedriver

# Install Selenium.
wget -N http://selenium-release.storage.googleapis.com/$SELENIUM_SUBDIR/selenium-server-standalone-$SELENIUM_STANDALONE_VERSION.jar -P ~/
mv -f ~/selenium-server-standalone-$SELENIUM_STANDALONE_VERSION.jar /usr/local/bin/selenium-server-standalone.jar
chown root:root /usr/local/bin/selenium-server-standalone.jar
chmod 0755 /usr/local/bin/selenium-server-standalone.jar

nohup java -jar /usr/local/bin/selenium-server-standalone.jar &

echo "Downloading and installing pip..."
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip -V

echo "Installing Selenium Python package..."
pip install selenium

echo "Running UI test using Selenium..."
python3 node_cloudant.py

