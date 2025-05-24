# ──────────────────────────────────────────────────────────────────────────────
# 1) Base image – pin the exact Python version you need
# ──────────────────────────────────────────────────────────────────────────────
FROM python:3.8-alpine   
# ──────────────────────────────────────────────────────────────────────────────
# 2) Runtime utilities (wget + wait-for) – unchanged from your original file
# ──────────────────────────────────────────────────────────────────────────────
RUN apk add --no-cache wget bash && \
    wget -O /usr/local/bin/wait-for \
        https://raw.githubusercontent.com/eficode/wait-for/master/wait-for && \
    chmod +x /usr/local/bin/wait-for

# ──────────────────────────────────────────────────────────────────────────────
# 3) Build dependencies: everything psycopg2 / PyYAML want
#    • build-base: gcc, libc headers, make, etc.
#    • python3-dev: CPython headers for native extensions
#    • postgresql-dev: libpq headers + pg_config
#    • libyaml-dev: fast C loader / dumper for PyYAML
# We install them in a *virtual* package “.build-deps” so they’re easy to
# uninstall in one shot later.
# ──────────────────────────────────────────────────────────────────────────────
RUN apk add --no-cache --virtual .build-deps \
      build-base \
      python3-dev \
      postgresql-dev \
      libyaml-dev

# ──────────────────────────────────────────────────────────────────────────────
# 4) Python deps
#    - Keep a pip version that still supports Python 3.8
#      (pip 25+ will drop 3.8 support in late-2025).
# ──────────────────────────────────────────────────────────────────────────────
COPY requirements.txt /tmp/requirements.txt

RUN pip install --upgrade "pip<24.1" setuptools wheel && \
    pip install --no-cache-dir -r /tmp/requirements.txt

# ──────────────────────────────────────────────────────────────────────────────
# 5) Clean-up: remove compiler tool-chain & build cache
# ──────────────────────────────────────────────────────────────────────────────
RUN apk del .build-deps && \
    rm -rf /root/.cache/pip /tmp/requirements.txt

# ──────────────────────────────────────────────────────────────────────────────
# 6) Your app
# ──────────────────────────────────────────────────────────────────────────────
WORKDIR /app
COPY ./run.py          /app/
COPY ./sqli            /app/sqli
COPY ./config          /app/config

# If run.py spins up the aiohttp server, this is fine.
# Otherwise replace with your preferred entry point (e.g. gunicorn).
CMD ["python", "run.py"]

