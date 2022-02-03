local packets = require('packets');

local tinc = {};
local tout = {};

-- table.insert(tinc, 0x029, function(id, size, packet)
--   string.char(id):hex()
--   print('IN: ' .. packet:hex());
-- end);

function string.tohex(str)
  return (str:gsub('.', function (c)
      return string.format('%02X ', string.byte(c))
  end))
end

-- table.insert(tout, packets.out.PACKET_NPC_INTERACTION, function(id, size, packet)
--   -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L349
--   local target = struct.unpack('L', packet, 0x04 + 1);
--   local tidx = struct.unpack('H', packet, 0x08 + 1);
--   local cat = struct.unpack('H', packet, 0x0A + 1);
--   local param = struct.unpack('H', packet, 0x0C + 1);
--   local unk = struct.unpack('H', packet, 0x0E + 1);
--
--   print(packet:hex());
--   print('OUT: target: ' .. target .. ' tidx: ' .. tidx .. ' cat: ' .. cat .. ' param: ' .. param .. ' unk: ' .. unk);
-- end);

-- table.insert(tout, packets.out.PACKET_NPC_CHOICE, function(id, size, packet)
--   -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L661
--   local target = struct.unpack('L', packet, 0x04 + 1);
--   local idx = struct.unpack('H', packet, 0x08 + 1);
--   local unk = struct.unpack('H', packet, 0x0A + 1);
--   local tidx = struct.unpack('H', packet, 0x0C + 1);
--   local auto = struct.unpack('B', packet, 0x0E + 1); -- 0E   1 if the response packet is automatically generated, 0 if it was selected by you
--   local unk2 = struct.unpack('B', packet, 0x0F + 1);
--   local zone = struct.unpack('H', packet, 0x10 + 1);
--   local menuid = struct.unpack('H', packet, 0x12 + 1);
--   print(packet:hex());
--   print('OUT`: target: ' .. target .. ' idx: ' .. idx .. ' unk: ' .. unk .. ' tidx: ' .. tidx .. ' auto: ' .. auto .. ' unk2: ' .. unk2 .. ' zone: ' .. zone .. ' menuid: ' .. menuid);
-- end);

return {
  inc = function(self, id, size, packet)
    -- if (id == 0x28) then
    --   print('IN: ' .. string.tohex(tostring(packet)));
    --   local actor = struct.unpack('I', packet, 6);
    --   local category = ashita.bits.unpack_be(packet, 82, 4);
    --   local param = ashita.bits.unpack_be(packet, 86, 16);
    --   local effect = ashita.bits.unpack_be(packet, 213, 17);
    --   local msg = ashita.bits.unpack_be(packet, 230, 10);
    --   local target = ashita.bits.unpack_be(packet, 150, 32);
    --   print ("Actor:".. actor.." category:"..category.." param:"..param.." effect:"..effect.." msg:"..msg.. " target:"..target)
    -- end
    if (tinc[id] ~= nil) then
      tinc[id](id, size, packet);
    end
  end,

  out = function(self, id, size, packet)
    -- if (id ~= 0x15) then
    --   print('OUT: ' .. packet:hex());
    -- end
    if (tout[id] ~= nil) then
      tout[id](id, size, packet);
    end
  end
};
