#
# Container Image UniFi
#

FROM alpine:3.16.2

ARG PROJ_NAME
ARG PROJ_VERSION
ARG PROJ_BUILD_NUM
ARG PROJ_BUILD_DATE
ARG PROJ_REPO
ARG OPENJDK_VERSION

LABEL org.opencontainers.image.authors="V10 Solutions"
LABEL org.opencontainers.image.title="${PROJ_NAME}"
LABEL org.opencontainers.image.version="${PROJ_VERSION}"
LABEL org.opencontainers.image.revision="${PROJ_BUILD_NUM}"
LABEL org.opencontainers.image.created="${PROJ_BUILD_DATE}"
LABEL org.opencontainers.image.description="Container image for UniFi"
LABEL org.opencontainers.image.source="${PROJ_REPO}"

RUN apk update \
	&& apk add --no-cache "shadow" "bash" \
	&& usermod -s "$(command -v "bash")" "root"

SHELL [ \
	"bash", \
	"--noprofile", \
	"--norc", \
	"-o", "errexit", \
	"-o", "nounset", \
	"-o", "pipefail", \
	"-c" \
]

ENV LANG "C.UTF-8"
ENV LC_ALL "${LANG}"
ENV UNIFI_HOME "/opt/unifi"
ENV PATH "${UNIFI_HOME}/bin:${PATH}"

RUN apk add --no-cache \
	"ca-certificates" \
	"curl" \
	"openjdk${OPENJDK_VERSION}-jre-base" \
	"java-snappy"

RUN groupadd -r -g "480" "unifi" \
	&& useradd \
		-r \
		-m \
		-s "$(command -v "nologin")" \
		-g "unifi" \
		-c "UniFi" \
		-u "480" \
		"unifi"

WORKDIR "/tmp"

RUN curl -L -f -o "unifi.zip" "https://dl.ubnt.com/unifi/${PROJ_VERSION}/UniFi.unix.zip" \
	&& unzip "unifi.zip" \
	&& mv "UniFi" "${UNIFI_HOME}" \
	&& cp "/usr/share/java/snappy-java.jar" "$(find "${UNIFI_HOME}/lib" -maxdepth "1" -type "f" -iname "snappy-java*" -print0 | xargs -0)" \
	&& rm "unifi.zip"

WORKDIR "${UNIFI_HOME}"

RUN folders=("data" "logs" "run") \
	&& for folder in "${folders[@]}"; do \
		mkdir -p "${folder}" \
		&& chmod "700" "${folder}" \
		&& chown -R "480":"480" "${folder}"; \
	done

WORKDIR "/"
