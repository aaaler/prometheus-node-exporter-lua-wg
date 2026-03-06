-- WireGuard / Amnezia WG collector for prometheus-node-exporter-lua.
-- Exports wg_latest_handshake_seconds from wg and amneziawg CLIs.

local WG_BIN = "/usr/bin/wg"
local AMNEZIAWG_BIN = "/usr/bin/amneziawg"

local function binary_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

local function parse_handshakes(output, tool_type)
  local result = {}
  for line in output:gmatch("[^\r\n]+") do
    local parts = {}
    for part in line:gmatch("%S+") do
      parts[#parts + 1] = part
    end
    if #parts >= 3 then
      local device = parts[1]
      local public_key = parts[2]
      local timestamp = tonumber(parts[3])
      if timestamp then
        result[#result + 1] = {
          device = device,
          public_key = public_key,
          type = tool_type,
          value = timestamp,
        }
      end
    end
  end
  return result
end

local function run_handshakes(cmd)
  local f = io.popen(cmd)
  if not f then
    return {}
  end
  local output = f:read("*a")
  f:close()
  return output
end

local function scrape()
  local wg_metric = metric("wg_latest_handshake_seconds", "gauge")

  if binary_exists(WG_BIN) then
    local out = run_handshakes(WG_BIN .. " show all latest-handshakes 2>/dev/null")
    for _, row in ipairs(parse_handshakes(out, "wireguard")) do
      wg_metric(
        { device = row.device, public_key = row.public_key, type = row.type },
        row.value
      )
    end
  end

  if binary_exists(AMNEZIAWG_BIN) then
    local out = run_handshakes(AMNEZIAWG_BIN .. " show all latest-handshakes 2>/dev/null")
    for _, row in ipairs(parse_handshakes(out, "amneziawg")) do
      wg_metric(
        { device = row.device, public_key = row.public_key, type = row.type },
        row.value
      )
    end
  end
end

return { scrape = scrape }
