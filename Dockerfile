# 使用輕量級的 Nginx Alpine 映像
FROM nginx:alpine

# 維護者資訊
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
LABEL org.opencontainers.image.description="井字遊戲 - 靜態網頁應用"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk update && apk add --no-cache libxml2

# 移除預設的 Nginx 網頁
RUN rm -rf /usr/share/nginx/html/*

# 複製靜態檔案到 Nginx 目錄
COPY app/ /usr/share/nginx/html/

# 建立自訂的 Nginx 配置（監聽 8080 端口以支援非 root 用戶）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 修改 Nginx 配置以支援非 root 用戶運行
RUN sed -i 's/listen\s*80;/listen 8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf && \
    sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf && \
    sed -i '1s|^|user web;\n|' /etc/nginx/nginx.conf

# 建立非 root 帳號並修正目錄權限
RUN addgroup -S web && adduser -S web -G web && \
    mkdir -p /home/web /tmp/proxy_temp /tmp/client_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp && \
    chown -R web:web /usr/share/nginx/html /var/cache/nginx /tmp/proxy_temp /tmp/client_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp /tmp && \
    chmod -R 755 /usr/share/nginx/html

# 暴露 8080 端口（非特權端口）
EXPOSE 8080

# 使用非 root 帳號執行
USER web

# 啟動 Nginx
CMD ["nginx", "-g", "daemon off;"]