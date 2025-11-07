FROM odoo:18.0

ARG LOCALE=en_US.UTF-8

ENV LANGUAGE=${LOCALE}
ENV LC_ALL=${LOCALE}
ENV LANG=${LOCALE}

# Temporarily switch to root for package installation
USER root

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    locales \
    netcat-openbsd \
    postgresql-client \
    && locale-gen ${LOCALE} \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Switch back to odoo user for runtime (security best practice)
USER odoo

ENTRYPOINT ["/bin/sh"]

CMD ["entrypoint.sh"]
