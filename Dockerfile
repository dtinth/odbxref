
FROM dtinth/ruby
MAINTAINER Thai Pangsakulyanont <org.yi.dttvb@gmail.com>

RUN apt-get install ruby2.1-dev -y
RUN apt-get install build-essential curl -y
RUN apt-get install git-core -y

ADD . /odbxref
RUN (cd /odbxref && bundle install && cd / && rm -rf odbxref)

