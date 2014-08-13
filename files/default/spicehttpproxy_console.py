# vim: tabstop=4 shiftwidth=4 softtabstop=4

# Copyright (c) 2013 OpenStack Foundation
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

"""
A simple HTTP CONNECT proxy using OpenStack console tokens as host
names.
"""

import BaseHTTPServer
import errno
import select
import socket
import SocketServer
import urlparse

from nova.consoleauth import rpcapi as consoleauth_rpcapi
from nova import context
from nova.openstack.common.gettextutils import _
from nova.openstack.common import log as logging
from oslo.config import cfg

CONF = cfg.CONF
CONF.import_opt('enabled', 'nova.spice', group='spice')

LOG = logging.getLogger(__name__)


class RequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_GET(self):
        query = urlparse.parse_qs(urlparse.urlparse(self.path).query)
        try:
            token = query['token'][0]
            self.send_response(200)
            self.send_header('Content-type', "application/x-virt-viewer")
            self.end_headers()
            self.wfile.write('[virt-viewer]\n')
            self.wfile.write('type=spice\n')
            self.wfile.write('proxy=%s\n' % CONF.spice.httpproxy_base_url)
            self.wfile.write('host=%s\n' % token)
            self.wfile.write('port=5900\n')
            return
        except IOError:
            self.send_error(404)

    def do_CONNECT(self):
        token = self.path
        i = token.find(':')
        if i >= 0:
            token = token[:i]

        ctxt = context.get_admin_context()
        rpcapi = consoleauth_rpcapi.ConsoleAuthAPI()
        connect_info = rpcapi.check_token(ctxt, token=token)

        if not connect_info:
            LOG.audit(_("Invalid Token: %s"), token)
            raise Exception(_("Invalid Token"))

        host = connect_info['host']
        port = int(connect_info['port'])

        # Connect to the target
        LOG.audit(_("connecting to: %(host)s:%(port)s"),
                  {'host': host, 'port': port})

        tsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            try:
                tsock.connect((host, port))
            except socket.error:
                self.send_error(404, _("Failed to connect to target"))
                raise

            self.log_request(200)
            self.wfile.write(self.protocol_version +
                             " 200 Connection established\r\n")
            try:
                self._recv_send(tsock)
            except IOError as e:
                # server closed?
                if e.errno != errno.EPIPE:
                    raise
        finally:
            tsock.close()
            self.connection.close()

    def _recv_send(self, tsock):
        iw = [self.connection, tsock]
        ow = []
        while 1:
            (ins, _, exs) = select.select(iw, ow, iw)
            if exs:
                break
            if ins:
                for i in ins:
                    if i is tsock:
                        out = self.connection
                    else:
                        out = tsock
                    data = i.recv(8192)
                    if data:
                        out.send(data)
                    else:
                        return


class ThreadingHTTPServer(SocketServer.ThreadingMixIn,
                          BaseHTTPServer.HTTPServer):
    def serve_forever(self):
        self.is_running = True
        self.timeout = 1
        while self.is_running:
            self.handle_request()

    def shutdown(self):
        self.is_running = False


class HTTPProxy:
    def __init__(self, server_address):
        self.server = ThreadingHTTPServer(server_address, RequestHandler)

    def start_server(self):
        self.server.serve_forever()
