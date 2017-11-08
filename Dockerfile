FROM docker:dind

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base libxml2-dev libxslt-dev libffi-dev
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler
ENV EXTRA_PACKAGES git bash

RUN apk update && \
	apk upgrade && \
	apk add $BUILD_PACKAGES	&& \
	apk add $RUBY_PACKAGES && \
	apk add $EXTRA_PACKAGES && \
	rm -rf /var/cache/apk/*

RUN mkdir /pdk
ENV PATH="/pdk/bin:${PATH}"
WORKDIR pdk
COPY . /pdk
RUN bundle install
RUN bundle binstubs pdk --path /pdk/bin
