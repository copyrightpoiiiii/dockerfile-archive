FROM openjdk:11-jdk-buster

RUN apt-get update && apt-get install -y libc6-dev --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV JRUBY_VERSION 9.3.0.0
ENV JRUBY_SHA256 2dc1f85936d3ff3adc20d90e5f4894499c585a7ea5fedec67154e2f9ecb1bc9b
RUN mkdir /opt/jruby \
  && curl -fSL https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz -o /tmp/jruby.tar.gz \
  && echo "$JRUBY_SHA256 /tmp/jruby.tar.gz" | sha256sum -c - \
  && tar -zx --strip-components=1 -f /tmp/jruby.tar.gz -C /opt/jruby \
  && rm /tmp/jruby.tar.gz \
  && update-alternatives --install /usr/local/bin/ruby ruby /opt/jruby/bin/jruby 1
ENV PATH /opt/jruby/bin:$PATH

# skip installing gem documentation
RUN mkdir -p /opt/jruby/etc \
 && { \
  echo 'install: --no-document'; \
  echo 'update: --no-document'; \
 } >> /opt/jruby/etc/gemrc

RUN gem install bundler rake net-telnet xmlrpc

# don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 \
 BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $GEM_HOME/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"

CMD [ "irb" ]
