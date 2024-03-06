FROM ubuntu:20.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libicu66 \
    libunwind8 \
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Download and configure the Azure DevOps agent
ENV AZP_URL=${AZP_URL}
RUN echo "AZP_URL ${AZP_URL}"
ENV AZP_TOKEN=${AZP_TOKEN}
RUN echo "AZP_TOKEN ${AZP_TOKEN}"
ENV AZP_AGENT_NAME=${AZP_AGENT_NAME}
RUN echo "AZP_AGENT_NAME ${AZP_AGENT_NAME}"
ENV AZP_POOL=${AZP_POOL}
RUN echo "AZ_POOL ${AZP_POOL}"
RUN echo "getting pipeline agent for linux"


COPY resources /Files/resources
RUN tar -xz -C /Files/resources -f /Files/resources/vsts-agent-linux-x64-2.195.0.tar.gz
RUN chmod +x /Files/resources/start.sh

RUN groupadd -r azp && useradd -r -g azp azp
RUN chown -R azp:azp /Files/resources

USER azp
WORKDIR /Files/resources

CMD ["./start.sh"]