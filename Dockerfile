FROM docker:dind

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV BUILD_PACKAGES git bash curl-dev ruby-dev build-base libxml2-dev libxslt-dev libffi-dev
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

RUN apk update && \
	apk upgrade && \
	apk add $BUILD_PACKAGES	&& \
	apk add $RUBY_PACKAGES && \
	rm -rf /var/cache/apk/*

RUN mkdir /pdk
ENV PATH /pdk/bin:$PATH
WORKDIR pdk
COPY . /pdk
RUN bundle install
RUN bundle binstubs pdk --path /pdk/bin
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
VOLUME /usr/src/app

CMD ["pdk"]
