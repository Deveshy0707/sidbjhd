FROM deveshy/compiler:ruby2 AS production

ENV JUDGE0_HOMEPAGE "https://judge0.com"
LABEL homepage=$JUDGE0_HOMEPAGE

ENV JUDGE0_SOURCE_CODE "https://github.com/judge0/judge0"
LABEL source_code=$JUDGE0_SOURCE_CODE

ENV JUDGE0_MAINTAINER "Herman Zvonimir Došilović <hermanz.dosilovic@gmail.com>"
LABEL maintainer=$JUDGE0_MAINTAINER


# ENV RUBY_VERSIONS \
#       2.7.0
# RUN set -xe && \
#     for VERSION in $RUBY_VERSIONS; do \
#       curl -fSsL "https://cache.ruby-lang.org/pub/ruby/${VERSION%.*}/ruby-$VERSION.tar.gz" -o /tmp/ruby-$VERSION.tar.gz && \
#       mkdir /tmp/ruby-2.7.0 && \
#       tar -xf /tmp/ruby-.tar.gz -C /tmp/ruby-2.7.0 --strip-components=1 && \
#       rm /tmp/ruby-2.7.0.tar.gz && \
#       cd /tmp/ruby-2.7.0 && \
#       ./configure --disable-install-doc --prefix=/usr/local/ruby-2.7.0 && \
#       make -j$(nproc) && \
#       make -j$(nproc) install && \
#       rm -rf /tmp/*; \
#     done

# ENV PATH "/usr/local/ruby-3.3.0/bin:/opt/.gem/bin:$PATH"
ENV PATH "/usr/local/ruby-2.7.0/bin:/opt/.gem/bin:$PATH"
ENV GEM_HOME "/opt/.gem/"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron \
      libpq-dev \
      sudo && \
    rm -rf /var/lib/apt/lists/* && \
    echo "gem: --no-document" > /root/.gemrc && \
    gem install bundler:2.1.4 && \
    npm install -g --unsafe-perm aglio@2.3.0

ENV VIRTUAL_PORT 2358
EXPOSE $VIRTUAL_PORT

WORKDIR /api

COPY Gemfile* ./
RUN RAILS_ENV=production bundle



COPY cron /etc/cron.d
RUN cat /etc/cron.d/* | crontab -

COPY . .

ENTRYPOINT ["/api/docker-entrypoint.sh"]
CMD ["/api/scripts/server"]
RUN chmod +x /api/docker-entrypoint.sh
RUN chmod +x /api/scripts/workers


ENV JUDGE0_VERSION "1.13.0"
LABEL version=$JUDGE0_VERSION


FROM production AS development

ARG DEV_USER=judge0
ARG DEV_USER_ID=1000

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tmux \
        vim && \
    useradd -u $DEV_USER_ID -m -r $DEV_USER && \
    echo "$DEV_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers

RUN groupadd crond-users && \
    mkdir -p /var/run && \
    touch /var/run/crond.pid && \
    chgrp crond-users /var/run/crond.pid && \
    usermod -a -G crond-users $DEV_USER

USER $DEV_USER

CMD ["sleep", "infinity"]
