FROM node:22-bookworm-slim

ARG SUPERCRONIC_VERSION=v0.2.34

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        expect \
        git \
        openssh-client \
        ripgrep \
    && curl -fsSL "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-linux-amd64" -o /usr/local/bin/supercronic \
    && chmod +x /usr/local/bin/supercronic \
    && npm install -g @openai/codex @anthropic-ai/claude-code \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash agent

WORKDIR /app
COPY --chown=agent:agent . /app

RUN chmod +x /app/scripts/*.sh
RUN chmod +x /app/lib/*.expect

USER agent
ENV HOME=/home/agent \
    TZ=Europe/Istanbul \
    PATH=/home/agent/.local/bin:/usr/local/bin:/usr/bin:/bin

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["schedule"]
