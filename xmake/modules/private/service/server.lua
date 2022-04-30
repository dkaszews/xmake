--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        server.lua
--

-- imports
import("core.base.object")
import("core.base.bytes")
import("core.base.base64")
import("core.base.hashset")
import("core.base.socket")
import("core.base.scheduler")
import("private.service.config")
import("private.service.message")
import("private.service.stream", {alias = "socket_stream"})

-- define module
local server = server or object()

-- init server
function server:init(daemon)
    self._DAEMON = daemon

    -- init authorizations
    local auths = config.get("server.auths")
    self:auths_set(auths)
end

-- is daemon?
function server:daemon()
    return self._DAEMON
end

-- set handler
function server:handler_set(handler)
    self._HANDLER = handler
end

-- set the given listen address
function server:address_set(address)
    local splitinfo = address:split(':', {plain = true})
    if #splitinfo == 2 then
        self._ADDR = splitinfo[1]
        self._PORT = splitinfo[2]
    else
        self._ADDR = "127.0.0.1"
        self._PORT = splitinfo[1]
    end
    assert(self._ADDR and self._PORT, "invalid listen address!")
end

-- get the listen address
function server:addr()
    return self._ADDR
end

-- get the listen port
function server:port()
    return self._PORT
end

-- get authorizations
function server:auths()
    return self._AUTHS
end

-- set authorizations
function server:auths_set(auths)
    self._AUTHS = auths and hashset.from(auths) or hashset.new()
end

-- we need verify user
function server:need_verfiy()
    return not self:auths():empty()
end

-- verify user
function server:verify_user(auth)
    if not auth then
        return false, "client has no authorization, this remote server need user authorization!"
    end

    -- check authorization
    if not self:auths():has(auth) then
        return false, "user and password are incorrect!"
    end

    -- TODO check known_hosts
    return true
end

-- run main loop
function server:runloop()
    assert(self._HANDLER, "no handler found!")

    -- ensure only one server process
    local lock = io.openlock(self:lockfile())
    if not lock:trylock() then
        raise("%s: has been started!", self)
    end

    -- save the current pid for stopping service
    io.writefile(self:pidfile(), os.getpid())

    -- run loop
    local sock = socket.bind(self:addr(), self:port())
    sock:listen(100)
    print("%s: listening %s:%d ..", self, self:addr(), self:port())
    io.flush()
    while true do
        local sock_client = sock:accept()
        if sock_client then
            scheduler.co_start(function (sock)
                self:_handle_session(sock)
                sock:close()
            end, sock_client)
        end
    end
    io.flush()
    sock:close()
end

-- get class
function server:class()
    return server
end

-- get pid file
function server:pidfile()
    return path.join(self:workdir(), "server.pid")
end

-- get lock file
function server:lockfile()
    return path.join(self:workdir(), "server.lock")
end

-- get working directory
function server:workdir()
    return os.tmpfile(tostring(self)) .. ".dir"
end

-- handle session
function server:_handle_session(sock)
    print("%s: %s: session connected", self, sock)
    local stream = socket_stream(sock)
    while true do
        local msg = stream:recv_object()
        if msg then
            self:_HANDLER(stream, message(msg))
        else
            break
        end
    end
    print("%s: %s: session end", self, sock)
end

function server:__tostring()
    return "<server>"
end

function main()
    local instance = server()
    instance:init()
    return instance
end
