FROM debian:stable-slim

# ENV variables
ENV DEBIAN_FRONTEND noninteractive
ENV TZ "America/New_York"
ENV CUPSADMIN admin
ENV CUPSPASSWORD password


LABEL org.opencontainers.image.source="https://github.com/anujdatar/cups-docker"
LABEL org.opencontainers.image.description="CUPS Printer Server"
LABEL org.opencontainers.image.author="Anuj Datar <anuj.datar@gmail.com>"
LABEL org.opencontainers.image.url="https://github.com/anujdatar/cups-docker/blob/main/README.md"
LABEL org.opencontainers.image.licenses=MIT


# Install dependencies
RUN apt-get update -qq  && apt-get upgrade -qqy \
    && apt-get install --no-install-recommends -qqy \
    wget \
    vim \
    nano \
    apt-utils \
    moreutils \
    usbutils \
    cups \
    cups-browsed\
    samba \
    avahi-daemon \
    cups-filters \
    && apt-get clean 
# && rm -rf /var/lib/apt/lists/*

# Install old dependancies as latest ghostscript breaks cups
RUN echo 'deb http://http.us.debian.org/debian oldstable main' >> /etc/apt/sources.list && apt-get update && \
    apt-get install --no-install-recommends --allow-downgrades -qqy \
    ghostscript=9.27~dfsg-2+deb10u5 \
    libgs9=9.27~dfsg-2+deb10u5 \
    libgs9-common=9.27~dfsg-2+deb10u5 

# Install Samsung Linux Drivers M2020 Series
RUN mkdir /var/downloads/ && cd /var/downloads/ \
    && wget --no-check-certificate https://ftp.hp.com/pub/softlib/software13/printers/SS/SL-C4010ND/uld_V1.00.39_01.17.tar.gz \
    && tar -vxzf uld_V1.00.39_01.17.tar.gz && cd uld \
    && y y | rm ./noarch/license/* && \n y | ./install.sh

EXPOSE 631
EXPOSE 5353

# Baked-in config file changes
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
    sed -i 's/Browsing Off/Browsing Yes/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
    sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
    echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
    echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

# back up cups configs in case used does not add their own
RUN cp -rp /etc/cups /etc/cups-bak
VOLUME [ "/etc/cups" ]

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
