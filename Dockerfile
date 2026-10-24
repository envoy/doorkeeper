FROM ruby:2.6.5-alpine
# CVE-2026-111943 / CVE-2026-114406: distrust the compromised eMudhra intermediates (emSign ECC Root CA - G3, Comodo AAA Services root)
RUN apk add --no-cache ca-certificates && \
    sed -i -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' /etc/ca-certificates.conf && \
    update-ca-certificates

RUN apk add --no-cache \
  ca-certificates \
  wget \
  openssl \ 
  bash \
  build-base \
  git \
  sqlite-dev \
  tzdata

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV BUNDLER_VERSION 2.1.4
RUN gem install bundler -v ${BUNDLER_VERSION} -i /usr/local/lib/ruby/gems/$(ls /usr/local/lib/ruby/gems) --force

WORKDIR /srv

COPY Gemfile doorkeeper.gemspec /srv/
COPY lib/doorkeeper/version.rb /srv/lib/doorkeeper/version.rb

RUN bundle install

COPY . /srv/

CMD ["rake"]
