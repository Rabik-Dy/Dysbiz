# Use official Python slim image
FROM python:3.11-slim-bullseye

# -------------------------
# Environment variables
# -------------------------
ENV ODOO_VERSION=18.0
ENV ODOO_USER=odoo
ENV ODOO_HOME=/opt/odoo
ENV ODOO_CONFIG=/etc/odoo/odoo.conf
ENV DB_HOST=mainline.proxy.rlwy.net
ENV DB_PORT=59964
ENV DB_USER=postgres
ENV DB_PASSWORD=NmSUMGhtUuqrjSnGzKHxxpDGCNmlnZfx
ENV DB_NAME=railway

# -------------------------
# Install system dependencies
# -------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libldap2-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    node-less \
    npm \
    postgresql-client \
    python3-dev \
    python3-pip \
    python3-wheel \
    python3-setuptools \
    wkhtmltopdf \
    xfonts-75dpi \
    xfonts-base \
 && rm -rf /var/lib/apt/lists/*

# -------------------------
# Create Odoo user and directories
# -------------------------
RUN useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER \
 && mkdir -p /etc/odoo /var/lib/odoo /var/log/odoo $ODOO_HOME/addons $ODOO_HOME/custom-addons \
 && chmod 755 /etc/odoo

# -------------------------
# Download Odoo source
# -------------------------
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME/odoo

# -------------------------
# Install Python dependencies
# -------------------------
RUN pip3 install --no-cache-dir -r $ODOO_HOME/odoo/requirements.txt \
 && pip3 install --no-cache-dir num2words phonenumbers xlwt xlrd

# -------------------------
# Set ownership
# -------------------------
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME /var/lib/odoo /var/log/odoo

# -------------------------
# Create Odoo config file
# -------------------------
RUN printf '%s\n' \
"[options]" \
"admin_passwd = admin" \
"db_host = ${DB_HOST}" \
"db_port = ${DB_PORT}" \
"db_user = ${DB_USER}" \
"db_password = ${DB_PASSWORD}" \
"db_name = ${DB_NAME}" \
"db_template = template0" \
"db_sslmode = prefer" \
"addons_path = /opt/odoo/odoo/addons,/opt/odoo/custom-addons" \
"data_dir = /var/lib/odoo" \
"logfile = /var/log/odoo/odoo.log" \
"log_level = info" \
"http_interface = 0.0.0.0" \
"http_port = 8069" \
"longpolling_port = 8072" \
"proxy_mode = False" \
"list_db = True" \
"workers = 0" \
"max_cron_threads = 2" \
> /etc/odoo/odoo.conf

# Set config permissions
RUN chmod 644 /etc/odoo/odoo.conf && chown root:root /etc/odoo/odoo.conf

# -------------------------
# Expose ports
# -------------------------
EXPOSE 8069 8072

# -------------------------
# Switch to Odoo user
# -------------------------
USER $ODOO_USER
WORKDIR $ODOO_HOME

# -------------------------
# Run Odoo
# -------------------------
#CMD ["python3", "/opt/odoo/odoo/odoo-bin",
     "-c", "/etc/odoo/odoo.conf",
     "--no-database-checks"]
CMD ["python3", "/opt/odoo/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf", "--no-database-checks"]
