FROM ubuntu:latest
RUN apt-get update && apt-get -u dist-upgrade -y && apt-get clean && apt-get autoclean && apt-get autoremove
RUN apt-get install -y jq && apt-get clean && apt-get autoclean && apt-get autoremove
WORKDIR /root/
COPY vault-prem_1.4.0-hv1_amd64.deb /root/
RUN dpkg --install /root/vault-prem_1.4.0-hv1_amd64.deb
COPY start.sh /root/
RUN chmod 755 /root/start.sh
ENTRYPOINT ["/root/start.sh"]

