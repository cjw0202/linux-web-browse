# linux-web-browse
## Introduction

browse all files and directories in browser

The script depends on a daemon component that you would need to run on your webserver - [**sockproc**](https://github.com/juce/sockproc). The basic idea is that the shell library connects to the unix domain socket of sockproc daemon, sends the command along with any input data that the child program is expecting, and then reads back the exit code, output stream data, and error stream data of the child process. Because we use co-socket API, provided by [lua-nginx-module](https://github.com/openresty/lua-nginx-module), the nginx worker is never blocked.

More info on sockproc server, including complete source code here: https://github.com/juce/sockproc and [lua-resty-shell](https://github.com/juce/lua-resty-shell)

## Example usage

In your OpenResty config:

```nginx
server {
    server_name 10.53.1.16;
    listen 8080;
    default_type application/json;

    location ~* /shell/(.*) {
        set $user_args $1;
        access_by_lua_block {
            local shell = require "resty.shell"
            local args = {
                socket = "unix:/tmp/shell.sock",
            }
            local ngx_user_args = "/"..ngx.var.user_args
            local status, out, err = shell.execute("`[ -f " .. ngx_user_args .. " ]` && echo 2 || echo 1", args)
            if status then
                if 2 == tonumber(out) then
                    local status1, out1, err1 = shell.execute("cat ".. ngx_user_args, args)
                    if status1 then
                        ngx.say(ngx_user_args.." 文件内容为:\n\n"..out1)
                    end
                elseif 1 == tonumber(out)  then
                    local status1, out1, err1 = shell.execute("`[ -d " .. ngx_user_args .. " ]` && echo 2 || echo 1", args)
                    if status1 then
                        if 2 == tonumber(out1) then
                            local dir = "cd ".. ngx.var.user_args
                            local cmd = dir .. " && ls -l"
                            local status2, out2, err2 = shell.execute(cmd, args)
                            if status2 then
                                ngx.say(ngx_user_args.."目录下有以下文件:\n\n"..out2)
                            end
                        else
                            ngx.say("无此文件或目录：/"..ngx_user_args)
                        end
                    end
                end
            end
        }
    }
}

```

