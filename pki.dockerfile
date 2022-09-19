#
# Container Image UniFi
#

FROM golang:1.19.0-alpine3.16 AS base

ARG PROJ_NAME
ARG CFSSL_VERSION
ARG OPENJDK_VERSION

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

RUN apk add --no-cache \
	"ca-certificates" \
	"gcc" \
	"openssl" \
	"libc-dev" \
	"openjdk${OPENJDK_VERSION}-jre-base"

RUN bins=("cfssl" "cfssljson") \
	&& for bin in "${bins[@]}"; do \
		go install "github.com/cloudflare/cfssl/cmd/${bin}@v${CFSSL_VERSION}"; \
	done

WORKDIR "/tmp/${PROJ_NAME}"

RUN mkdir ".output"

########################################################################################################################

FROM base AS do-tls

ARG KEYSTORE_PASS

COPY "pki/tls-config.json" "./"
COPY "pki/tls-csr.json" "./"

RUN cfssl selfsign -config "tls-config.json" "." "tls-csr.json" \
	| cfssljson -bare ".output/tls" \
	&& mv ".output/tls.csr" ".output/tls-csr.pem" \
	&& mv ".output/tls.pem" ".output/tls-cer.pem" \
	&& cat ".output/tls-cer.pem" > ".output/ca.pem" \
	&& cat ".output/tls-key.pem" ".output/tls-cer.pem" > ".output/tls-bundle.pem"

RUN openssl pkcs12 \
	-export \
	-in ".output/tls-bundle.pem" \
	-out ".output/tls-bundle.pfx" \
	-name "unifi" \
	-passout "pass":""

RUN keytool \
	-importkeystore \
	-destkeystore ".output/tls-bundle.keystore" \
	-deststoretype "JKS" \
	-destkeypass "${KEYSTORE_PASS}" \
	-deststorepass "${KEYSTORE_PASS}" \
	-srckeystore ".output/tls-bundle.pfx" \
	-srcstoretype "PKCS12" \
	-srckeypass "" \
	-srcstorepass "" \
	-alias "unifi" \
	-noprompt

########################################################################################################################

FROM scratch AS tls

ARG PROJ_NAME

COPY --from="do-tls" "/tmp/${PROJ_NAME}/.output" "."
