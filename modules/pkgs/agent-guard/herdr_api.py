"""Minimal client for herdr's JSON-lines socket API (~/.config/herdr/herdr.sock)."""

import json
import os
import socket


class HerdrError(Exception):
    pass


class HerdrClient:
    """Minimal client for herdr's JSON-lines socket API."""

    def __init__(self, path):
        self.path = path
        self._seq = 0

    def request(self, method, params=None, timeout=10.0):
        self._seq += 1
        req = {"id": f"agent-revive:{os.getpid()}:{self._seq}", "method": method, "params": params or {}}
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(timeout)
            try:
                s.connect(self.path)
                s.sendall((json.dumps(req) + "\n").encode())
                data = b""
                while not data.endswith(b"\n"):
                    chunk = s.recv(65536)
                    if not chunk:
                        break
                    data += chunk
            except OSError as err:
                raise HerdrError(f"{method}: {err}") from err
        try:
            reply = json.loads(data)
        except json.JSONDecodeError as err:
            raise HerdrError(f"{method}: unreadable reply") from err
        if "error" in reply:
            raise HerdrError(f"{method}: {reply['error'].get('message', reply['error'])}")
        return reply.get("result", {})
