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
            ngx.say(ngx_user_args.." �ļ�����Ϊ:\n\n"..out1)
        end
    elseif 1 == tonumber(out)  then
        local status1, out1, err1 = shell.execute("`[ -d " .. ngx_user_args .. " ]` && echo 2 || echo 1", args)
        if status1 then
            if 2 == tonumber(out1) then
                local dir = "cd ".. ngx.var.user_args
                local cmd = dir .. " && ls -l"
                local status2, out2, err2 = shell.execute(cmd, args)
                if status2 then
                    ngx.say(ngx_user_args.."Ŀ¼���������ļ�:\n\n"..out2)
                end
            else
                ngx.say("�޴��ļ���Ŀ¼��/"..ngx_user_args)
            end
        end
    end
end