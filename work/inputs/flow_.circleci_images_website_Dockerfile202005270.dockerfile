FROM circleci/ruby:2.6-node
MAINTAINER Flow Team <flow@fb.com>

# s3_website needs Java
RUN sudo apt-get update && sudo apt-get install -y openjdk-11-jre-headless
