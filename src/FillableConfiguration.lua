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

-- register new configuration type
ConfigurationUtil.registerConfigurationType("fillConf", "Fillable configuration", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);

FillableConfiguration = {};

function FillableConfiguration.prerequisitesPresent(specializations)
	if not SpecializationUtil.hasSpecialization(Fillable, specializations) then
		print("Warning: Specialization FillableConfiguration needs the specialization Fillable");
		return false;
	end;
	return true;
end;


function FillableConfiguration:preLoad(savegame)
end;

function FillableConfiguration:load(savegame)
	-- replace all data loaded by Fillable in this load. Update, Draw, etc...
	-- will be left on fillable
	
	print("Configurations");
	DebugUtil.printTableRecursively(self.configurations, "-", 0 ,4);
	
	local key, fillConfId = Vehicle.getXMLConfigurationKey(self.xmlFile, self.configurations["fillConf"], "vehicle.fillConfConfigurations.fillConfConfiguration", "vehicle", "fillConf");
	print(tostring(key));
    local fallbackConfigKey = "vehicle.fillConfConfigurations.fillConfConfiguration(0)";
    local fallbackOldKey = "vehicle";

	self.supportsFillTriggers = Vehicle.getConfigurationValue(self.xmlFile, key, ".supportsFillTriggers", "#value", getXMLBool, self.supportsFillTriggers, fallbackConfigKey, fallbackOldKey);

	if self.supportsFillTriggers then
        self.setIsFilling = Fillable.setIsFilling;
        self.addFillTrigger = Fillable.addFillTrigger;
        self.removeFillTrigger = Fillable.removeFillTrigger;
        self.fillLitersPerSecond = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillLitersPerSecond", "", getXMLFloat, 500, fallbackConfigKey, fallbackOldKey);
        local unitFillTime = Vehicle.getConfigurationValue(self.xmlFile, key, ".unitFillTime", "", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey);
        if unitFillTime ~= nil then
            self.unitFillTime = unitFillTime * 1000;
        end
        self.currentFillTime = 0;
        self.fillTriggers = {};
        self.fillActivatable = FillActivatable:new(self);
        self.isFilling = false;
    end;
	
	self.fillTypeChangeThreshold = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillTypeChangeThreshold", "", getXMLFloat, 0.05, fallbackConfigKey, fallbackOldKey);
	
	self.fillUnits = {};
	local unitsBase = fallbackOldKey .. ".fillUnits.fillUnit";
	if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".fillUnits.fillUnit(0)") then
        unitsBase = fallbackConfigKey..".fillUnits.fillUnit";
    end
    if key ~= nil and hasXMLProperty(self.xmlFile, key..".fillUnits.fillUnit(0)") then
        unitsBase = key..".fillUnits.fillUnit";
    end
    local i=0;
    while true do
        local keyUnits = string.format(unitsBase .. "(%d)", i);
        if not hasXMLProperty(self.xmlFile, keyUnits) then
            break;
        end
		print(tostring(keyUnits));
        local entry = {};
        entry.fillUnitIndex = i+1;
        entry.fillVolumeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, keyUnits .. "#fillVolumeIndex"), entry.fillUnitIndex);
        entry.currentFillType = FillUtil.FILLTYPE_UNKNOWN;
        entry.lastValidFillType = FillUtil.FILLTYPE_UNKNOWN;
        entry.fillLevel = 0;
        if self.isServer then
            entry.sentFillType = entry.currentFillType;
            entry.sentFillLevel = entry.fillLevel;
        end
        entry.capacity = getXMLFloat(self.xmlFile, keyUnits .. "#capacity");
        entry.unit = getXMLString(self.xmlFile, keyUnits .. "#unit");
        entry.showOnHud = Utils.getNoNil(getXMLBool(self.xmlFile, keyUnits .. "#showOnHud"), true);
        entry.fillTypes = {};
        local fillTypes = {};
        local fillTypeCategories = getXMLString(self.xmlFile, keyUnits .. "#fillTypeCategories");
        local fillTypeNames = getXMLString(self.xmlFile, keyUnits .. "#fillTypes");
        if fillTypeCategories ~= nil and fillTypeNames == nil then
            fillTypes = FillUtil.getFillTypeByCategoryName(fillTypeCategories, "Warning: '"..self.configFileName.. "' has invalid fillTypeCategory '%s'.")
        elseif fillTypeCategories == nil and fillTypeNames ~= nil then
            fillTypes = FillUtil.getFillTypesByNames(fillTypeNames, "Warning: '"..self.configFileName.. "' has invalid fillType '%s'.")
        else
            print("Warning: '"..self.configFileName.. "' a fillUnit entry needs either the 'fillTypeCategories' or 'fillTypes' attribute.")
        end
        if fillTypes ~= nil then
            for _,fillType in pairs(fillTypes) do
                entry.fillTypes[fillType] = true;
            end
        end
        entry.lastFillLevel = 0;
        entry.fillLevelHud = VehicleHudUtils.loadHud(self, self.xmlFile, "fillLevel", nil, i);
        table.insert(self.fillUnits, entry);
        i=i+1;
    end;
	-- we don't have fallback, because modders should use new config style

	self.fillRootNode = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".fillRootNode", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    if self.fillRootNode == nil then
        self.fillRootNode = self.components[1].node;
    end;
	
	self.fillMassNode = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".fillMassNode", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    local updateFillLevelMass = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillMassNode", "#updateFillLevelMass", getXMLBool, true, fallbackConfigKey, fallbackOldKey);
    if self.fillMassNode == nil and updateFillLevelMass then
        self.fillMassNode = self.components[1].node;
    end;
	
	self.exactFillRootNode = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".exactFillRootNode", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    if self.exactFillRootNode == nil then
        self.exactFillRootNode = self.fillRootNode;
    end;
	
	self.fillAutoAimTarget = {};
    self.fillAutoAimTarget.node = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    if self.fillAutoAimTarget.node == nil then
        self.fillAutoAimTarget.node = self.exactFillRootNode;
    end
    self.fillAutoAimTarget.baseTrans = {getTranslation(self.fillAutoAimTarget.node)};
    self.fillAutoAimTarget.startZ = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#startZ", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey);
    self.fillAutoAimTarget.endZ = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#endZ", getXMLFloat, nil, fallbackConfigKey, fallbackOldKey);
    self.fillAutoAimTarget.fillUnitIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#fillUnitIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
    self.fillAutoAimTarget.startPercentage = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#startPercentage", getXMLFloat, 25, fallbackConfigKey, fallbackOldKey)/100;
    self.fillAutoAimTarget.invert = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillAutoAimTargetNode", "#invert", getXMLBool, false, fallbackConfigKey, fallbackOldKey);
    if self.fillAutoAimTarget.startZ ~= nil and self.fillAutoAimTarget.endZ ~= nil then
        local startZ = self.fillAutoAimTarget.startZ;
        if self.fillAutoAimTarget.invert then
            startZ = self.fillAutoAimTarget.endZ;
        end;
        setTranslation(self.fillAutoAimTarget.node, self.fillAutoAimTarget.baseTrans[1], self.fillAutoAimTarget.baseTrans[2], startZ);
    end;
	
	self.attacherPipeRef = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".attacherPipe", "#refIndex", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
	
	self.attacherPipe = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".attacherPipe", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    self.attacherPipeAnimation = getXMLString(self.xmlFile, "vehicle.attacherPipe#animationName");
    self.attacherPipeAnimation = Vehicle.getConfigurationValue(self.xmlFile, key, ".attacherPipe", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey);
	
	print("load done");
	
	-- end of loading
end;

function FillableConfiguration:postLoad(savegame)
	print("postload");
	DebugUtil.printTableRecursively(self.fillUnits, "-", 0, 4);
	-- need to be loaded here because in time when Fillable is loaded there is no fillunit
	if savegame ~= nil and not savegame.resetVehicles and self.synchronizeFillLevels then
        if hasXMLProperty(savegame.xmlFile, savegame.key.."#fillLevels") and hasXMLProperty(savegame.xmlFile, savegame.key.."#fillTypes") then
            local fillLevels = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(savegame.xmlFile, savegame.key.."#fillLevels"), "")) };
            local fillTypes = Utils.splitString(" ", Utils.getNoNil(getXMLString(savegame.xmlFile, savegame.key.."#fillTypes"), ""));
            for i,fillType in pairs(fillTypes) do
                if fillLevels[i] ~= nil then
                    local fillTypeInt = FillUtil.fillTypeNameToInt[fillType];
                    self:setUnitFillLevel(i, fillLevels[i], fillTypeInt, false);
                end;
            end;
        end;
    end;
	print(tostring(self:getFillLevel()));
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
