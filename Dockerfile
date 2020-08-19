FROM openresty/openresty:alpine

RUN \
     rm /etc/apk/repositories && \
     echo -e "https://mirrors.aliyun.com/alpine/v3.5/main\nhttps://mirrors.aliyun.com/alpine/v3.5/community" >> /etc/apk/repositories && \
     apk add --no-cache bash tzdata redis curl && \
     cp -rf /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime

LABEL \
description="公共网关" \
dependent=""

# 健康检查
HEALTHCHECK --interval=10s  --timeout=10s --retries=3 --start-period=120s \  
 CMD curl -f http://localhost/api/version || exit 1

# 配置版本号
ARG SERVICE_VERSION
ENV VERSION=${SERVICE_VERSION}

# 复制 lua-nginx 源代码到  /src 目录
COPY ./src /src

# 复制 nginx 配置文件到 /usr/local/openresty/nginx/conf 目录
COPY ./conf/nginx.conf /usr/local/openresty/nginx/conf

EXPOSE 80

WORKDIR /src

ENTRYPOINT /usr/local/openresty/bin/openresty -g "daemon off;"
