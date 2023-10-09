# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import json
import logging.handlers
import os
import sys
from urllib.request import urlopen

from flask import Flask, render_template, request


##
# Classes and misc
class ClockMetadata:

    details = None
    clock_error_bound = None
    reference_timestamp = None
    clock_sync_status = None

    def __init__(self, metadata_uri=None):

        metadata_uri = os.getenv("ECS_CONTAINER_METADATA_URI_V4", default=None)

        if metadata_uri and metadata_uri.lower().startswith('http'):
            endpoint = f"{metadata_uri}/task"
        else:
            server_logger.error(
                f"The metadata URI is undefined! Probably this is not an ECS Task.")

            self.details = 'Not Available'
            self.clock_error_bound = 'Not Available'
            self.reference_timestamp = 'Not Available'
            self.clock_sync_status = 'Not Available'
            return

        server_logger.info(f"Metadata endpoint - {endpoint}")
        response = urlopen(f"{endpoint}")
        data_json = json.loads(response.read())

        self.details = str(data_json['TaskARN']).rsplit('/', 1)[1]
        self.clock_error_bound = data_json['ClockDrift']['ClockErrorBound']
        self.reference_timestamp = data_json['ClockDrift']['ReferenceTimestamp']
        self.clock_sync_status = data_json['ClockDrift']['ClockSynchronizationStatus']


##
# Set-up Flask server
server_logger = None
app = Flask(__name__)

##
# Render the HTML content
@app.route("/", methods=['GET'])
def index():

    # Retrieve clock data from the endpoint
    clock_data = ClockMetadata()

    #  Return HTML
    return render_template('index.html',
                           details=clock_data.details,
                           clock_error_bound=clock_data.clock_error_bound,
                           reference_timestamp=clock_data.reference_timestamp,
                           clock_sync_status=clock_data.clock_sync_status
                           )

##
# Refresh action
@app.route("/refresh", methods=['POST'])
def refresh():

    # Processing request
    server_logger.info("Processing method - [%s]", request.method)

    # Retrieve clock data from the endpoint
    clock_data = ClockMetadata()

    #  Return HTML
    return render_template('index.html',
                           details=clock_data.details,
                           clock_error_bound=clock_data.clock_error_bound,
                           reference_timestamp=clock_data.reference_timestamp,
                           clock_sync_status=clock_data.clock_sync_status
                           )


##
# Main
if __name__ == '__main__':
    ##
    # Local logging
    server_logger = logging.getLogger(__name__)
    server_logger.setLevel(logging.INFO)
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    server_logger.addHandler(handler)

    ##
    # Local run
    app.run(host='0.0.0.0', port=80)

else:
    ##
    # Set-up logging for Gunicorn
    server_logger = logging.getLogger('gunicorn.error')
    server_logger.setLevel(logging.INFO)
    app.logger.handlers = server_logger.handlers
