FROM amclubs/freebsd:14.1

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

RUN pkg update && \
    pkg install -y go wget unzip

WORKDIR /workspace

COPY . .

CMD ["/bin/sh", "-c", "CGO_ENABLED=1 GOOS=freebsd GOARCH=amd64 go build -o xui-release -v main.go && mkdir x-ui && cp xui-release x-ui/xui-release && cp x-ui.service x-ui/x-ui.service && cp x-ui.sh x-ui/x-ui.sh && cd x-ui && mv xui-release x-ui && mkdir bin && cd bin && wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-freebsd-64.zip && unzip Xray-freebsd-64.zip && rm -f Xray-freebsd-64.zip geoip.dat geosite.dat && wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat && wget https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat && mv xray xray-freebsd-amd64"]
