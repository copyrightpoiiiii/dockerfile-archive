FROM debian:jessie-backports

MAINTAINER Miguel Moquillon "miguel.moquillon@silverpeas.org"

LABEL name="Silverpeas 6" description="Image to install and to run Silverpeas 6" vendor="Silverpeas" version="6.0-alpha2" build=1

ENV TERM=xterm

#
# Install required and recommended programs for Silverpeas
#

# Installation of ImageMagick, Ghostscript, LibreOffice, and then
# the dependencies required to build SWFTools and PDF2JSON
RUN apt-get update && apt-get install -y \
    wget \
    locales \
    procps \
    net-tools \
    zip \
    unzip \
    openjdk-8-jdk \
    ffmpeg \
    imagemagick \
    ghostscript \
    libreoffice \
    ure \
    gpgv \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-ca-certificates -f

# Fetch and install SWFTools
RUN wget -nc https://www.silverpeas.org/files/swftools-bin-0.9.2.zip \
  && unzip swftools-bin-0.9.2.zip -d / \
  && rm -f swftools-bin-0.9.2.zip

# Fetch and install PDF2JSON
RUN wget -nc https://www.silverpeas.org/files/pdf2json-bin-0.68.zip \
  && unzip pdf2json-bin-0.68.zip -d / \
  && rm -f pdf2json-bin-0.68.zip

#
# Set up environment to install and to run Silverpeas
#

# Default locale of the platform. It can be overriden to build an image for a specific locale other than en_US.UTF-8.
ARG DEFAULT_LOCALE=en_US.UTF-8

# Generate locales and set the default one
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen \
  && update-locale LANG=${DEFAULT_LOCALE} LANGUAGE=${DEFAULT_LOCALE} LC_ALL=${DEFAULT_LOCALE}

ENV LANG ${DEFAULT_LOCALE}
ENV LANGUAGE ${DEFAULT_LOCALE}
ENV LC_ALL ${DEFAULT_LOCALE}

#
# Install Silverpeas and Wildfly
#

# Set up environment variables for Silverpeas
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV SILVERPEAS_HOME /opt/silverpeas
ENV JBOSS_HOME /opt/wildfly

ENV SILVERPEAS_VERSION=6.0-alpha2
ENV WILDFLY_VERSION=10.0.0

# Fetch both Silverpeas and Wildfly and unpack them into /opt
RUN wget -nc https://www.silverpeas.org/files/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip \
  && wget -nc https://www.silverpeas.org/files/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip.asc \
  && gpg --keyserver hkp://pgp.mit.edu --recv-keys 3DF442B6 \
  && gpg --batch --verify silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip.asc silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip \
  && wget -nc http://download.jboss.org/wildfly/${WILDFLY_VERSION}.Final/wildfly-${WILDFLY_VERSION}.Final.zip \
  && unzip silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?}.zip -d /opt \
  && unzip wildfly-${WILDFLY_VERSION}.Final.zip -d /opt \
  && mv /opt/silverpeas-${SILVERPEAS_VERSION}-wildfly${WILDFLY_VERSION%.?.?} /opt/silverpeas \
  && mv /opt/wildfly-${WILDFLY_VERSION}.Final /opt/wildfly \
  && rm *.zip \
  && mkdir -p ${HOME}/.m2 \

# Copy the Maven settings.xml required to install Silverpeas by fetching the software bundles from 
# the Silverpeas Nexus Repository
COPY src/settings.xml ${HOME}/.m2/

# Set the default working directory
WORKDIR ${SILVERPEAS_HOME}/bin

# Copy this container init script that will be run each time the container is ran
COPY src/run.sh /opt/
COPY src/ooserver /opt/

# Assemble, pre-configure and install Silverpeas
RUN ./silverpeas assemble \
  && rm ../log/build-* \
  && touch .install

#
# Expose image entries. By default, when running, the container will set up Silverpeas and Wildfly
# according to the host environment.
#

# Silverpeas listens port 8000 by default
EXPOSE 8000 9990

# The following Silverpeas folders are exposed by default so that you can access the logs, the data, the properties
# or the configuration of Silverpeas outside the container
VOLUME ["/opt/silverpeas/log", "/opt/silverpeas/data", "/opt/silverpeas/properties", "/opt/silverpeas/configuration", "/opt/silverpeas/xmlcomponents/workflows"]

# What to execute by default when running the container
CMD ["/opt/run.sh"]
