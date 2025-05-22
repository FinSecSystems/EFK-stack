FROM fluent/fluentd:v1.16.8-1.0
USER root
RUN apk add --update --virtual .build-deps \
    sudo build-base ruby-dev \
    && gem update --system 3.6.9 \
    && sudo gem install \
    fluent-plugin-elasticsearch --version 6.0.0 \
    && sudo gem sources --clear-all \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/* \
    /home/fluent/.gem/ruby/2.3.0/cache/*.gem 
#RUN fluent-gem install elasticsearch --no-document --version 9.0.0 \
#    && fluent-gem uninstall elasticsearch --version 9.0.2    \
#    && fluent-gem uninstall elasticsearch-api --version 9.0.2