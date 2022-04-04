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
-- @file        main.lua
--

-- imports
import("core.base.option")
import("service")

function _start_service(opt)
    opt = opt or {}
    if opt.daemon then
        os.execv(os.programfile(), {"lua", path.join(os.scriptdir(), "service.lua")}, {detach = true})
    else
        service()
    end
end

function _restart_service()
end

function _show_service_logs()
end

function _show_service_status()
end

function main()
    cprint("${color.warning}It's experimental feature, still in development!")
    if option.get("start") then
        _start_service({daemon = true})
    elseif option.get("restart") then
        _restart_service()
    elseif option.get("logs") then
        _show_service_logs()
    elseif option.get("status") then
        _show_service_status()
    else
        _start_service()
    end
end

