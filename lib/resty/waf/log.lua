local _M = {}

local cjson         = require "cjson"
local file_logger   = require "resty.logger.file"
local socket_logger = require "resty.logger.socket"

_M.version = "0.8.1"

-- debug logger
function _M.log(waf, msg)
	if (waf._debug == true) then
		ngx.log(waf._debug_log_level, '[', waf.transaction_id, '] ', msg)
	end
end

-- warn logger
function _M.warn(waf, msg)
	ngx.log(ngx.WARN, '[', waf.transaction_id, '] ', msg)
end

-- fatal failure logger
function _M.fatal_fail(msg)
	ngx.log(ngx.ERR, error(msg))
	ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- event log writer lookup table
_M.write_log_events = {
	error = function(waf, t)
		ngx.log(waf._event_log_level, cjson.encode(t))
	end,
	file = function(waf, t)
		if (not file_logger.initted()) then
			file_logger.init({
				path           = waf._event_log_target_path,
				flush_limit    = waf._event_log_buffer_size,
				periodic_flush = waf._event_log_periodic_flush
			})
		end

		file_logger.log(cjson.encode(t) .. "\n")
	end,
	socket = function(waf, t)
		if (not socket_logger.initted()) then
			socket_logger.init({
				host           = waf._event_log_target_host,
				port           = waf._event_log_target_port,
				sock_type      = waf._event_log_socket_proto,
				ssl            = waf._event_log_ssl,
				ssl_verify     = waf._event_log_ssl_verify,
				sni_host       = waf._event_log_ssl_sni_host,
				flush_limit    = waf._event_log_buffer_size,
				periodic_flush = waf._event_log_periodic_flush
			})
		end

		socket_logger.log(cjson.encode(t) .. "\n")
	end
}

return _M
