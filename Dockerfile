FROM golang:alpine AS builder
RUN apk update && apk add --no-cache git bash curl
WORKDIR /go/src/v2ray.com/core
RUN git clone --progress https://github.com/v2fly/v2ray-core.git . && \
    bash ./release/user-package.sh nosource noconf codename=$(git describe --tags) buildname=docker-fly abpathtgz=/tmp/v2ray.tgz

RUN set -ex \
        && mkdir -p /var/cache/apk/ \
        && apk update \
        && apk add nodejs npm git aria2 python3\
        && apk add ca-certificates mailcap curl bash \
        && apk add --no-cache --virtual .build-deps make gcc g++ \
        && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
        && echo "Asia/Shanghai" > /etc/timezone

ARG VERSION

RUN set -ex \
        && git clone  https://github.com/dissipator/gd-utils ${WORKDIR}/gd-utils \
	&& cd ${WORKDIR}/gd-utils \
        && git checkout dev \
        && ls -l  \
        && npm config set unsafe-perm=true \
        && npm install -g \
        && npm install pm2 -g 
        
FROM alpine
ENV CONFIG=https://raw.githubusercontent.com/yeahwu/kinto/master/config.json
COPY --from=builder /tmp/v2ray.tgz /tmp
RUN apk update && apk add --no-cache tor ca-certificates && \
    tar xvfz /tmp/v2ray.tgz -C /usr/bin && \
    rm -rf /tmp/v2ray.tgz
    
CMD nohup tor & \
    sed -i "s/bot_token/${BOT_TOKEN}/g" ${WORKDIR}/gd-utils/config.js  \
    sed -i "s/your_tg_userid/${TG_UID}/g" ${WORKDIR}/gd-utils/config.js  \
    sed -i "s/DEFAULT_TARGET = ''/DEFAULT_TARGET = '${DEFAULT_TARGET}'/g" ${WORKDIR}/gd-utils/config.js  \
    pm2 start ${WORKDIR}/gd-utils/index.js & \
    v2ray -config $CONFIG
