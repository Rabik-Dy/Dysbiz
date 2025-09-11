# Use official Python slim image
FROM python:3.11-slim-bullseye

ENV ODOO_VERSION=18.0
ENV ODOO_USER=odoo
ENV ODOO_HOME=/opt/odoo

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential curl git libldap2-dev libpq-dev libsasl2-dev libssl-dev \
    libxml2-dev libxslt1-dev node-less npm postgresql-client python3-dev \
    python3-pip python3-wheel python3-setuptools wkhtmltopdf \
    xfonts-75dpi xfonts-base \
 && rm -rf /var/lib/apt/lists/*

# Create Odoo user and directories
RUN useradd -m -d $ODOO_HOME -U -r -s /bin/bash $ODOO_USER \
 && mkdir -p /etc/odoo /var/lib/odoo /var/log/odoo $ODOO_HOME/addons $ODOO_HOME/custom-addons \
 && chmod 755 /etc/odoo

# Download Odoo source
RUN git clone --depth 1 --branch $ODOO_VERSION https://github.com/odoo/odoo.git $ODOO_HOME/odoo

# Install Python dependencies
RUN pip3 install --no-cache-dir -r $ODOO_HOME/odoo/requirements.txt \
 && pip3 install --no-cache-dir num2words phonenumbers xlwt xlrd psycopg2-binary

# Set ownership
RUN chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME /var/lib/odoo /var/log/odoo

# Copy your odoo.conf
COPY odoo.conf /etc/odoo/odoo.conf
RUN chmod 644 /etc/odoo/odoo.conf && chown root:root /etc/odoo/odoo.conf

# Expose ports (Railway will override)
EXPOSE 8069 8072

# Switch to Odoo user
USER $ODOO_USER
WORKDIR $ODOO_HOME

# Run Odoo on Railway PORT
CMD ["python3", "/opt/odoo/odoo/odoo-bin", "-c", "/etc/odoo/odoo.conf", "--http-port", "${PORT}"]
