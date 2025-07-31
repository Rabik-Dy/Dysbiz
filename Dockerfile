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
 
# Create directories with proper permissions
RUN mkdir -p /etc/odoo \
&& mkdir -p /var/lib/odoo \
&& mkdir -p /var/log/odoo \
&& mkdir -p $ODOO_HOME/addons \
&& mkdir -p $ODOO_HOME/custom-addons \
&& chmod 755 /etc/odoo
 
# Download and install Odoo
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME/odoo
 
# Install Python dependencies
RUN pip3 install --no-cache-dir -r $ODOO_HOME/odoo/requirements.txt
 
# Install additional Python packages
RUN pip3 install --no-cache-dir \
    num2words \
    phonenumbers \
    xlwt \
    xlrd
 
# Set ownership for data directories only (config file should be readable by all)
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME \
&& chown -R $ODOO_USER:$ODOO_USER /var/lib/odoo \
&& chown -R $ODOO_USER:$ODOO_USER /var/log/odoo
 
# Create default configuration file
RUN cat > /etc/odoo/odoo.conf << 'EOF' && \
[options] && \
admin_passwd = admin_password_change_me && \
db_host = db && \
db_port = 5432 && \
db_user = odoo && \
db_password = odoo_password && \
addons_path = /opt/odoo/odoo/addons,/opt/odoo/custom-addons && \
data_dir = /var/lib/odoo && \
logfile = /var/log/odoo/odoo.log && \
log_level = info && \
http_interface = 0.0.0.0 && \
http_port = 8069 && \
longpolling_port = 8072 && \
db_maxconn = 64 && \
db_template = template0 && \
list_db = True && \
proxy_mode = False && \
EOF
 
# Set proper permissions for config file
RUN chmod 644 /etc/odoo/odoo.conf \
&& chown root:root /etc/odoo/odoo.conf
 
# Expose Odoo port
EXPOSE 8069 8071 8072
 
# Set user
USER $ODOO_USER
 
# Set working directory
WORKDIR $ODOO_HOME
 
# Run Odoo
CMD ["python3", "/opt/odoo/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf"]