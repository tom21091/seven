local config = require('config');
local packets = require('packets');
local pgen = require('pgen');

local queue = {};

local actions = {
  busy = false,

  talkNpc = function(self, tid, tidx)
    -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L349
    local pid = packets.out.PACKET_NPC_INTERACTION;
    local packet = pgen:new(pid)
      :push('L', tid)
      :push('H', tidx)
      :push('H', 0):push('H', 0):push('H', 0)
      :push('f', 0):push('f', 0):push('f', 0)
      :get_packet();
    AddOutgoingPacket(pid, packet);
  end,

  InteractNpc = function(self, tid, tidx)
    local actions = self;
    -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L349
    return actions:new():next(function()
      local pid = packets.out.PACKET_NPC_INTERACTION;
      local packet = pgen:new(pid)
        :push('L', tid)
        :push('H', tidx)
        :push('H', 0):push('H', 0):push('H', 0)
        :push('f', 0):push('f', 0):push('f', 0)
        :get_packet();
      AddOutgoingPacket(pid, packet);
      return 'packet_in';
    end)
    :next(function(self, stalled, id, size, packet)
      if (stalled == true) then -- npcs get contention when talked to repeatedly (even by other players)
        if (self.__count ~= nil and self.__count >= 3) then -- bail
          print('I give up');
          return;
        end
        print('trying again');
        actions:talkNpc(tid, tidx);
        self.stalled = false; -- try again
        self.count = 0; -- backdown
        self.__count = (self.__count or 0) + 1;
        print(self.__count);
        return false;
      elseif (id == packets.inc.PACKET_NPC_INTERACTION) then
        return; -- no packet to unpack below;
      elseif (id ~= packets.inc.PACKET_NPC_INTERACTION_2) then
        return false;
      end
      -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L1880
      self._npcid   = struct.unpack('L', packet, 0x04 + 1);
      self._zone    = struct.unpack('H', packet, 0x2A + 1);
      self._menuid  = struct.unpack('H', packet, 0x2C + 1);
    end)
  end,

  new = function(self)
    -- This is an action
    return {
      count = 0, -- how many ticks have gone since progress
      waiting = nil, -- 'packet' or nil
      parts = {}, -- queue of functions to run

      -- monad to help with building
      next = function(self, fn)
        -- to wait for a packet, call this with a function that returns 'packet'
        -- the next fn you queue will be passed all incoming packets for you to filter.
        -- return false if the packet you get does not match what you need.
        table.insert(self.parts, fn);
        return self;
      end
    };

  end,

  queue = function(self, action)
    action.next = nil;
    table.insert(queue, action);
  end,

  tick = function(self)
    local len = #queue;
    if (len == 0) then return end

    local action = queue[1];
    local parts = action.parts;
    if (#parts == 0) then
      table.remove(queue, 1);
      self:tick();
    elseif (action.count >= 5 and action.stalled ~= true) then
      action.stalled = true;
      parts[1](action, true); -- action will be killed next tick
    elseif (action.stalled == true) then
      print('Action stalled, removed.');
      AshitaCore:GetChatManager():QueueCommand('/l2 Action stalled, removed.', -1);
      table.remove(queue, 1);
      self:tick();
    elseif (action.waiting == 'wait') then
      action.wait = (action.wait or 0) - 0.5;
      --print('waiting 1 tick, ' .. action.wait);
      if (action.wait <= 0) then
        action.waiting = nil;
      end
    elseif (action.waiting == nil) then
      action.waiting, action.wait = table.remove(parts, 1)(action, false);
      action.count = 0;
      action.stalled = false;
    else
      action.count = action.count + 1;
    end
  end,

  packet = function(self, isIn, id, size, packet)
    local len = #queue;
    if (len == 0) then return end

    local action = queue[1];
    local parts = action.parts;

    if (#parts == 0) then
      table.remove(queue, 1);
      self:packet(id, size, packet);
    elseif (isIn == true and action.waiting == 'packet_in') then
      local result = parts[1](action, false, id, size, packet);
      if (result ~= false) then
        action.waiting, action.wait = result;
        table.remove(parts, 1);
        action.count = 0;
        action.stalled = false;
      end
    elseif (isIn == false and action.waiting == 'packet_out') then
      local result = parts[1](action, false, id, size, packet);
      if (result ~= false) then
        action.waiting, action.wait = result;
        table.remove(parts, 1);
        action.count = 0;
        action.stalled = false;

        if (result == true) then
          action.waiting = nil;
          return true; -- this function wants to replace the packet.
        end
      end
    end
  end,

  signet = function(self, tid, tidx)
    local actions = self;
    actions:queue(
      actions:InteractNpc(tid, tidx)
      :next(function(self) return 'wait', 2; end) -- wait 2 seconds
      :next(function(self, stalled) -- kill the text menu from the book
        self.esc = true;
        AshitaCore:GetChatManager():QueueCommand('/sendkey escape down', -1);
        return 'packet_out'; -- wait to cap the packet
      end)
      :next(function(self, stalled, id, size, packet)
        if (self.esc == true) then
          self.esc = false;
          AshitaCore:GetChatManager():QueueCommand('/sendkey escape up',   -1);
        end

        if (stalled == true) then return end
        if (id ~= packets.out.PACKET_NPC_CHOICE) then return false end

        -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L661
        local packet = pgen:new(id)
          :push('L', self._npcid) -- npcid
          :push('H', 1) -- signet is slot 1
          :push('H', 0x00)  -- unkown   (with repeat?)
          :push('H', tidx)
          :push('B', 0x00) -- auto
          :push('B', 0x00) -- unkown-2
          :push('H', self._zone)
          :push('H', self._menuid)
          :get_packet();
        AddOutgoingPacket(id, packet);
        return true; -- replace the outgoing packet
      end)
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/l2 done.', 1);
      end)
    );
  end,

  warp_scroll = function(self, tid, tidx)
    local actions = self;
    actions:queue(
      actions:InteractNpc(tid, tidx)
      :next(function(self) return 'wait', 2; end) -- wait 2 seconds
      :next(function(self, stalled) -- kill the text menu from the book
        self.esc = true;
        AshitaCore:GetChatManager():QueueCommand('/sendkey escape down', -1);
        return 'packet_out'; -- wait to cap the packet
      end)
      :next(function(self, stalled, id, size, packet)
        if (self.esc == true) then
          self.esc = false;
          AshitaCore:GetChatManager():QueueCommand('/sendkey escape up',   -1);
        end

        if (stalled == true) then return end
        if (id ~= packets.out.PACKET_NPC_CHOICE) then return false end

        -- https://github.com/Windower/Lua/blob/422880f0e353a82bb9a11328dc4202ed76cd948a/addons/libs/packets/fields.lua#L661
        local packet = pgen:new(id)
          :push('L', self._npcid) -- npcid
          :push('H', 32929) -- warp scroll
          :push('H', 0x00)  -- unkown   (with repeat?)
          :push('H', tidx)
          :push('B', 0x00) -- auto
          :push('B', 0x00) -- unkown-2
          :push('H', self._zone)
          :push('H', self._menuid)
          :get_packet();
        AddOutgoingPacket(id, packet);
        return true; -- replace the outgoing packet
      end)
      :next(function(self)
        AshitaCore:GetChatManager():QueueCommand('/l2 done.', 1);
      end)
    );
  end,

  corn = function(self, tid, tidx)
    local actions = self;
    local Inventory = AshitaCore:GetDataManager():GetInventory();
    local idx = nil;
    for i = 0, Inventory:GetContainerMax(0) - 1 do
      local item_t = Inventory:GetItem(0, i);
      if (item_t and item_t.Id == 629 and item_t.Count >= 3) then
        idx = i;
        break;
      end
    end

    if (idx == nil) then
      AshitaCore:GetChatManager():QueueCommand('/l2 LADIES AND GENTLEMEN! NO MORE CORN!', 1);
      return;
    end
    self:queue(self:new():next(function()
      local pid = packets.out.PACKET_TRADE_MENU_ITEM;
      local packet = pgen:new(pid)
        :push('L', tid)
        :push('L', 3) -- slot 0 (or gil)
        :push('L', 0):push('L', 0):push('L', 0):push('L', 0)
        :push('L', 0):push('L', 0):push('L', 0):push('L', 0)
        :push('L', 0) -- unk1
        :push('B', idx) -- slot 0 (or gil)
        :push('B', 0):push('B', 0):push('B', 0):push('B', 0)
        :push('B', 0):push('B', 0):push('B', 0):push('B', 0)
        :push('B', 0)
        :push('H', tidx)
        :push('B', 1)
        :push('B', 0)
        :push('B', 0)
        :push('B', 0)
        :get_packet();

      AddOutgoingPacket(pid, packet);
      return 'packet_in';
    end)
    :next(function(self, stalled, id, size, packet)
      if (stalled or id ~= 0x1E) then
        if (self.__count ~= nil and self.__count >= 15) then -- bail
          print('I give up');
          return;
        end

        local me = self;
        if (not(me.keydown)) then
          me.keydown = true;
          AshitaCore:GetChatManager():QueueCommand('/sendkey return down', -1);
          ashita.timer.once(1, function()
            AshitaCore:GetChatManager():QueueCommand('/sendkey return up', -1);
            ashita.timer.once(1, function()
              me.keydown = false;
            end);
          end);
        end

        self.stalled = false; -- try again
        self.count = 0; -- backdown
        self.__count = (self.__count or 0) + 1;
        return false;
      else
        ashita.timer.once(1, function()
          actions:corn(tid, tidx);
        end);
      end
    end));
  end,

  leader = function(self, leader)
    config:get().leader = leader;
    print(config:get().leader);
    config:save();
  end,
  
  tank = function(self, tank)
    config:get().tank = tank;
    print(config:get().tank);
    config:save();
  end,

  pause = function(stop)
    local cnf = config.get();
    if (cnf==nil)then print('CNF nil'); return end
    if(stop==true)then--Stopping
      if (cnf['stay'] == nil) then
        cnf['stay'] = true;
        AshitaCore:GetChatManager():QueueCommand("/sendkey numpad7 down", -1);
      elseif (cnf['stay'] == true) then
        cnf['stay'] = nil;
        AshitaCore:GetChatManager():QueueCommand("/sendkey numpad7 up", -1);
      end
    else--Back to following
      if(cnf['follow']==true)then
        AshitaCore:GetChatManager():QueueCommand("/follow ".. cnf.leader, -1);
      end
    end
  end
};

return actions;
