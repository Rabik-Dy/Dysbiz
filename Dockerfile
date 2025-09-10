FROM python:3.11-slim-bullseye

# Set environment variables
ENV ODOO_VERSION=18.0
ENV ODOO_USER=odoo
ENV ODOO_HOME=/opt/odoo
ENV ODOO_CONFIG=/etc/odoo/odoo.conf

# Install system dependencies
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

# Create odoo user
RUN useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER

# Create directories
RUN mkdir -p /etc/odoo \
    /var/lib/odoo \
    /var/log/odoo \
    $ODOO_HOME/addons \
    $ODOO_HOME/custom-addons \
 && chmod 755 /etc/odoo

# Download Odoo source
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME/odoo

# Install Python dependencies
RUN pip3 install --no-cache-dir -r $ODOO_HOME/odoo/requirements.txt \
 && pip3 install --no-cache-dir num2words phonenumbers xlwt xlrd

# Set ownership
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME /var/lib/odoo /var/log/odoo

# Create Odoo config file with Railway Postgres details
RUN cat > /etc/odoo/odoo.conf << 'EOF'
[options]
; Admin password
admin_passwd = admin_password_change_me

; Database connection (from your Railway Postgres URL)
db_host = postgres.railway.internal
db_port = 5432
db_user = postgres
db_password = XOXOhOHhCwoOTISJopYYasNbTLOpWCbE
db_name = railway

; Odoo paths
addons_path = /opt/odoo/odoo/addons,/opt/odoo/custom-addons
data_dir = /var/lib/odoo
logfile = /var/log/odoo/odoo.log
log_level = info

; Network
http_interface = 0.0.0.0
http_port = 8069
longpolling_port = 8072
db_maxconn = 64
db_template = template0
list_db = True
proxy_mode = False
EOF

# Set config permissions
RUN chmod 644 /etc/odoo/odoo.conf && chown root:root /etc/odoo/odoo.conf

# Expose ports
EXPOSE 8069 8072

# Switch to Odoo user
USER $ODOO_USER

# Working directory
WORKDIR $ODOO_HOME

# Run Odoo
CMD ["python3", "/opt/odoo/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf"]
