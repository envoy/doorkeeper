FROM ruby:3.1.7-slim-bookworm

# CVE-2026-111943 / CVE-2026-114406: upgrade ca-certificates and fail the build unless it
# distrusts the compromised eMudhra intermediates (fixed in Debian 12 20250419~deb12u2)
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  wget \
  openssl \
  build-essential \
  git \
  libsqlite3-dev \
  libyaml-dev \
  tzdata && \
  rm -rf /var/lib/apt/lists/* && \
  dpkg --compare-versions "$(dpkg-query -W -f='${Version}' ca-certificates)" ge 20250419~deb12u2

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV BUNDLER_VERSION 2.6.9
RUN gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force

WORKDIR /srv

COPY Gemfile doorkeeper.gemspec /srv/
COPY lib/doorkeeper/version.rb /srv/lib/doorkeeper/version.rb

RUN bundle install

COPY . /srv/

CMD ["rake"]
