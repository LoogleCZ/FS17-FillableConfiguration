--
-- Script for controling fertilizer ammount
--
-- Author: Martin Fabík (https://www.fb.com/LoogleCZ)
-- GitHub repository: https://github.com/LoogleCZ/FS17-FillableConfiguration
--
-- Free for non-comerecial usage!
--
-- version ID   - 1.0.0
-- version date - 2018-02-11 21:06:00
--
-- used namespace: LFO
--
-- This is development version! DO not use it on release!
--

FillableConfiguration = {};

function FillableConfiguration.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization FillableConfiguration needs the specialization Fillable");
		return false;
	end;
	return true;
end;

function FillableConfiguration.loadConfPre(...)
	print("Configuration preload");
	print(tostring(self));
	if arg ~= nil and type(arg) == "table" then
		for k,v in pairs(arg) do
			print(k .. "=>" .. v);
		end;
	end;
	print("Configuration preload end;");
end;

function FillableConfiguration.loadConfPost(...)
	print("Configuration postload");
	print(tostring(self));
	if arg ~= nil and type(arg) == "table" then
		for k,v in pairs(arg) do
			print(k .. "=>" .. v);
		end;
	end;
	print("Configuration postload end;");
end;

function FillableConfiguration.loadConfSingleItem(...)
	print("Configuration item load");
	print(tostring(self));
	if arg ~= nil and type(arg) == "table" then
		for k,v in pairs(arg) do
			print(k .. "=>" .. v);
		end;
	end;
	print("Configuration item load end;");
end;

ConfigurationUtil.registerConfigurationType("fillConf", "Fillable configuration", FillableConfiguration.loadConfPre, FillableConfiguration.loadConfSingleItem, FillableConfiguration.loadConfPost, ConfigurationUtil.SELECTOR_MULTIOPTION);

function FillableConfiguration:preLoad(savegame)
end;

function FillableConfiguration:load(savegame)
	self.LFO = {};
	
	--
	--	for saving using self.configurations["fillConf"]
	-- and 
	--	self.boughtConfigurations["fillConf"]
	--
	
	DebugUtil.printTableRecursively(ConfigurationUtil, "", 0, 4 );
	
	-- end of loading
end;

function FillableConfiguration:postLoad(savegame)
end;

function FillableConfiguration:getSaveAttributesAndNodes(nodeIdent)
end;

function FillableConfiguration:delete() end;

function FillableConfiguration:update(dt)
end;

function FillableConfiguration:updateTick(dt)
end;

function FillableConfiguration:readStream(streamId, connection) end;
function FillableConfiguration:writeStream(streamId, connection) end;
function FillableConfiguration:mouseEvent(posX, posY, isDown, isUp, button) end;
function FillableConfiguration:keyEvent(unicode, sym, modifier, isDown) end;

function FillableConfiguration:draw()
end;
