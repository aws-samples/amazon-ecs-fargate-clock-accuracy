FROM public.ecr.aws/docker/library/python:slim

# Add sample application files
COPY app/ /opt/app/

# Set working directory & install dependencies
WORKDIR /opt/app
RUN pip install --no-cache-dir --upgrade pip \
        && pip install --no-cache-dir -r requirements.txt

# Expose default port
EXPOSE 80

# Run the web app
ENTRYPOINT ["gunicorn", "--error-logfile",  "-",       \
                        "--access-logfile", "-",       \
                        "--capture-output",            \
                        "--bind", "0.0.0.0:80",        \
                        "wsgi:app"]
