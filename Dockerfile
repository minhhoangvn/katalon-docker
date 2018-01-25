FROM ubuntu:16.04
LABEL author="minhhoang"

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu xenial main universe\n" > /etc/apt/sources.list \
    && echo "deb http://archive.ubuntu.com/ubuntu xenial-updates main universe\n" >> /etc/apt/sources.list \
    && echo "deb http://security.ubuntu.com/ubuntu xenial-security main universe\n" >> /etc/apt/sources.list

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    bzip2 \
    ca-certificates \
    openjdk-8-jre-headless \
    tzdata \
    sudo \
    unzip \
    wget \
    vim \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

#===================
# Timezone settings
# Possible alternative: https://github.com/docker/docker/issues/3359#issuecomment-32150214
#===================
ENV TZ "UTC"
RUN echo "${TZ}" > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata


#========================================
# Add normal user with passwordless sudo
#========================================
RUN useradd katalonuser \
         --shell /bin/bash  \
         --create-home \
  && usermod -a -G sudo katalonuser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'katalonuser:secret' | chpasswd

#==========
# Selenium
#==========
USER katalonuser
RUN  sudo mkdir -p /opt/selenium \
    && sudo chown katalonuser:katalonuser /opt/selenium \
    && wget --no-verbose https://selenium-release.storage.googleapis.com/3.8/selenium-server-standalone-3.8.1.jar \
    -O /opt/selenium/selenium-server-standalone.jar


#==============
# VNC and Xvfb
#==============
USER root
RUN apt-get update -qqy \
    && apt-get -qqy install \
    locales \
    xvfb \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#==============
# Python and Pip
#==============
RUN apt-get update -qqy \
    && apt-get -qqy install \
    python-pip \
    xvfb \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN pip install --upgrade pip
RUN pip install selenium

#============================
# Some configuration options
#============================
ENV SCREEN_WIDTH 1080
ENV SCREEN_HEIGHT 1920
ENV SCREEN_DEPTH 24
ENV DISPLAY :99

#============================
## Chrome
#============================

#============================================
# Google Chrome
#============================================
# can specify versions by CHROME_VERSION;
#  e.g. google-chrome-stable=53.0.2785.101-1
#       google-chrome-beta=53.0.2785.92-1
#       google-chrome-unstable=54.0.2840.14-1
#       latest (equivalent to google-chrome-stable)
#       google-chrome-beta  (pull latest beta)
#============================================
USER root
ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qqy \
    && apt-get -qqy install \
    ${CHROME_VERSION:-google-chrome-stable} \
    && rm /etc/apt/sources.list.d/google-chrome.list \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

#============================================
# Chrome webdriver
#============================================
# can specify versions by CHROME_DRIVER_VERSION
# Latest released version will be used by default
#============================================
USER root
ARG CHROME_DRIVER_VERSION="latest"
RUN CD_VERSION=$(if [ ${CHROME_DRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- https://chromedriver.storage.googleapis.com/LATEST_RELEASE); else echo $CHROME_DRIVER_VERSION; fi) \
    && echo "Using chromedriver version: "$CD_VERSION \
    && wget --no-check-certificate --no-verbose -O /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CD_VERSION/chromedriver_linux64.zip \
    && rm -rf /opt/selenium/chromedriver \
    && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
    && rm /tmp/chromedriver_linux64.zip \
    && mv /opt/selenium/chromedriver /opt/selenium/chromedriver-$CD_VERSION \
    && chmod 755 /opt/selenium/chromedriver-$CD_VERSION \
    && sudo ln -fs /opt/selenium/chromedriver-$CD_VERSION /usr/bin/chromedriver


#=========
# Firefox
#=========
USER root
ARG FIREFOX_VERSION=57.0.4
RUN FIREFOX_DOWNLOAD_URL=$(if [ $FIREFOX_VERSION = "nightly" ]; then echo "https://download.mozilla.org/?product=firefox-nightly-latest-ssl&os=linux64&lang=en-US"; else echo "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2"; fi) \
    && apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install firefox \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
    && apt-get -y purge firefox \
    && rm -rf /opt/firefox \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
    && rm /tmp/firefox.tar.bz2 \
    && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
    && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox

#============
# GeckoDriver
#============
USER root
ARG GECKODRIVER_VERSION=latest
RUN GK_VERSION=$(if [ ${GECKODRIVER_VERSION:-latest} = "latest" ]; then echo $(wget -qO- "https://api.github.com/repos/mozilla/geckodriver/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([0-9.]+)".*/\1/'); else echo $GECKODRIVER_VERSION; fi) \
  && echo "Using GeckoDriver version: "$GK_VERSION \
  && wget --no-verbose -O /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/v$GK_VERSION/geckodriver-v$GK_VERSION-linux64.tar.gz \
  && rm -rf /opt/geckodriver \
  && tar -C /opt -zxf /tmp/geckodriver.tar.gz \
  && rm /tmp/geckodriver.tar.gz \
  && mv /opt/geckodriver /opt/geckodriver-$GK_VERSION \
  && chmod 755 /opt/geckodriver-$GK_VERSION \
  && ln -fs /opt/geckodriver-$GK_VERSION /usr/bin/geckodriver

# Install 'pulseaudio' package to support WebRTC audio streams
RUN apt-get update && apt-get install -y pulseaudio


#================================
# Create virtual display service
#================================

USER katalonuser

COPY xvfb-service /etc/init.d/xvfb-service
RUN sudo chmod +x /etc/init.d/xvfb-service

RUN sudo chown katalonuser:katalonuser /etc/bash.bashrc \
    && sudo chown katalonuser:katalonuser /etc/rc.local

RUN sudo echo "service xvfb-service start" >> /etc/bash.bashrc

RUN echo "service xvfb-service start" > /etc/rc.local

#============================
# Create Katalon
#============================
USER root

# Setup katalon stand alone folder and config
RUN mkdir -p /katalontemp \
    mkdir -p /katalon

WORKDIR /katalon
RUN wget --no-verbose -O /tmp/katalon.zip http://download.katalon.com/5.2.0.1/Katalon_Studio_Linux_64-5.2.0.1.zip \
    && unzip /tmp/katalon.zip -d /katalontemp \
    && cp -r /katalontemp/Katalon_Studio_\ Linux_64-5.2.0.1/. /katalon/ \
    && rm -rf /katalontemp

COPY test.py ./
COPY entry_point ./
RUN chmod +x entry_point
RUN chmod +x katalon

RUN echo "export PATH=$PATH:/katalon/" >> /etc/rc.local
RUN echo "export PATH=$PATH:/katalon/" >> /etc/bash.bashrc

RUN service xvfb-service start

#=============================================
# Wrap chrome binary to run without sandbox
#=============================================
USER root
COPY wrap_chrome_binary /opt/bin/wrap_chrome_binary
RUN chmod +x /opt/bin/wrap_chrome_binary \
    && /opt/bin/wrap_chrome_binary

ENTRYPOINT ["/bin/sh", "./entry_point"]