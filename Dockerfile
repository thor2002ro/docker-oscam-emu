FROM lsiobase/alpine:latest

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="saarg"

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	git \
	curl \
	gcc \
	g++ \
	libusb-dev \
	linux-headers \
	make \
	libressl-dev \
	pcsc-lite-dev \
	tar && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	ccid \
	libcrypto1.0 \
	libssl1.0 \
	libusb \
	pcsc-lite \
	pcsc-lite-libs && \
 echo "**** compile oscam ****" && \
 git clone https://github.com/oscam-emu/oscam-patched.git /tmp/oscam-emu && \
 cd /tmp/oscam-emu && \
 ./config.sh \
	--enable all \
	--disable \
	CARDREADER_DB2COM \
	CARDREADER_INTERNAL \
	CARDREADER_STINGER \
	CARDREADER_STAPI \
	CARDREADER_STAPI5 \
	IPV6SUPPORT \
	LCDSUPPORT \
	LEDSUPPORT \
	READ_SDT_CHARSETS && \
 make \
	CONF_DIR=/config \
	DEFAULT_PCSC_FLAGS="-I/usr/include/PCSC" \
	NO_PLUS_TARGET=1 \
	OSCAM_BIN=/usr/bin/oscam \
	pcsc-libusb && \
 echo "**** fix broken permissions from pcscd install ****" && \
 chown root:root \
	/usr/sbin/pcscd && \
 chmod 755 \
	/usr/sbin/pcscd && \
 echo "**** install PCSC drivers ****" && \
 mkdir -p \
	/tmp/omnikey && \
 curl -o \
 /tmp/omnikey.tar.gz -L \
	https://www.hidglobal.com/sites/default/files/drivers/ifdokccid_linux_x86_64-v4.2.8.tar.gz && \
 tar xzf \
 /tmp/omnikey.tar.gz -C \
	/tmp/omnikey --strip-components=2 && \
 cd /tmp/omnikey && \
 ./install && \
 echo "**** fix group for card readers and add abc to dialout group ****" && \
 groupmod -g 24 cron && \
 groupmod -g 16 dialout && \
 usermod -a -G 16 abc && \
 echo "**** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/tmp/*

# copy local files
COPY root/ /

# Ports and volumes
EXPOSE 8888
VOLUME /config
