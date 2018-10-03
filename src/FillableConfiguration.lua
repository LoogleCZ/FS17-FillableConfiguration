--
-- Script for controling fertilizer ammount
--
-- Author: Martin Fabík (https://www.fb.com/LoogleCZ)
-- GitHub repository: https://github.com/LoogleCZ/FS17-FillableConfiguration
--
-- Free for non-comerecial usage!
--
-- version ID   - 1.0.1
-- version date - 2018-10-03 15:10:00
--
-- used namespace: LFO
--
-- This is development version! DO not use it on release!
--

-- register new configuration type
if not ConfigurationUtil.configurations.fillConf then
	ConfigurationUtil.registerConfigurationType("fillConf", g_i18n:getText("l10n_fillableConfiguration"), nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION);
end;

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
	
	
	-- load data from fillable
	local key, fillConfId = Vehicle.getXMLConfigurationKey(self.xmlFile, self.configurations["fillConf"], "vehicle.fillConfConfigurations.fillConfConfiguration", "vehicle", "fillConf");
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
    end;
    if key ~= nil and hasXMLProperty(self.xmlFile, key..".fillUnits.fillUnit(0)") then
        unitsBase = key..".fillUnits.fillUnit";
    end;
    local i=0;
    while true do
        local keyUnits = string.format(unitsBase .. "(%d)", i);
        if not hasXMLProperty(self.xmlFile, keyUnits) then
            break;
        end
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
    self.attacherPipeAnimation = Vehicle.getConfigurationValue(self.xmlFile, key, ".attacherPipe", "#animationName", getXMLString, nil, fallbackConfigKey, fallbackOldKey);

	self.allowFillFromAir = Vehicle.getConfigurationValue(self.xmlFile, key, ".allowFillFromAir", "#value", getXMLBool, true, fallbackConfigKey, fallbackOldKey);
	
    local unloadTriggerNode = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".unloadTrigger", "#index", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    if unloadTriggerNode ~= nil then
        self.unloadTrigger = FillTrigger:new();
        self.unloadTrigger:load(unloadTriggerNode, nil, self);
    end;
    self.unloadTriggerFillUnitIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".unloadTrigger", "#fillUnitIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
	
	if self.isClient then
        local fillPlanesRotDeg = Vehicle.getConfigurationValue(self.xmlFile, key, ".fillPlanes", "#rotationDegrees", getXMLBool, false, fallbackConfigKey, fallbackOldKey);
        local i = 0;
		local planesBase = fallbackOldKey .. ".fillPlanes.fillPlane";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".fillPlanes.fillPlane(0)") then
			planesBase = fallbackConfigKey..".fillPlanes.fillPlane";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".fillPlanes.fillPlane(0)") then
			planesBase = key..".fillPlanes.fillPlane";
		end;
        while true do
            local planesKey = string.format(planesBase .. "(%d)", i);
            if not hasXMLProperty(self.xmlFile, planesKey) then
                break;
            end
            local fillUnitIndex = getXMLInt(self.xmlFile, planesKey.."#fillUnitIndex");
            if self.fillUnits[fillUnitIndex] == nil then
                print("Warning: fillUnitIndex '"..tostring(fillUnitIndex).."' in fillPlane("..i..") does not point to a valid fillUnit!");
            end
            if self.fillUnits[fillUnitIndex].fillPlanes == nil then
                self.fillUnits[fillUnitIndex].fillPlanes = {};
            end
            local fillPlane = {};
            fillPlane.nodes = {};
            local fillTypeName = getXMLString(self.xmlFile, planesKey.."#fillType")
            local fillType = Utils.getNoNil(FillUtil.fillTypeNameToInt[fillTypeName], FillUtil.FILLTYPE_UNKNOWN);
            if fillType ~= nil then
                local nodeI = 0;
                while true do
                    local nodeKey = planesKey..string.format(".node(%d)", nodeI);
                    if not hasXMLProperty(self.xmlFile, nodeKey) then
                        break;
                    end
                    local node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, nodeKey.."#index"));
                    if node ~= nil then
                        local defaultX, defaultY, defaultZ = getTranslation(node);
                        local defaultRX, defaultRY, defaultRZ = getRotation(node);
                        local animCurve = AnimCurve:new(linearInterpolatorTransRotScale);
                        local keyI = 0;
                        while true do
                            local animKey = nodeKey..string.format(".key(%d)", keyI);
                            local keyTime = getXMLFloat(self.xmlFile, animKey.."#time");
                            local x,y,z = Utils.getVectorFromString(getXMLString(self.xmlFile, animKey.."#translation"));
                            if y == nil then
                                y = getXMLFloat(self.xmlFile, animKey.."#y");
                            end
                            local rx,ry,rz = Utils.getVectorFromString(getXMLString(self.xmlFile, animKey.."#rotation"));
                            local sx,sy,sz = Utils.getVectorFromString(getXMLString(self.xmlFile, animKey.."#scale"));
                            if keyTime == nil then
                                break;
                            end
                            local x = Utils.getNoNil(x, defaultX);
                            local y = Utils.getNoNil(y, defaultY);
                            local z = Utils.getNoNil(z, defaultZ);
                            if fillPlanesRotDeg then
                                rx = Utils.getNoNilRad(rx, defaultRX);
                                ry = Utils.getNoNilRad(ry, defaultRY);
                                rz = Utils.getNoNilRad(rz, defaultRZ);
                            else
                                rx = Utils.getNoNil(rx, defaultRX);
                                ry = Utils.getNoNil(ry, defaultRY);
                                rz = Utils.getNoNil(rz, defaultRZ);
                            end
                            local sx = Utils.getNoNil(sx, 1);
                            local sy = Utils.getNoNil(sy, 1);
                            local sz = Utils.getNoNil(sz, 1);
                            animCurve:addKeyframe({x=x, y=y, z=z, rx=rx, ry=ry, rz=rz, sx=sx, sy=sy, sz=sz, time = keyTime});
                            keyI = keyI +1;
                        end;
                        if keyI == 0 then
                            local minY, maxY = Utils.getVectorFromString(getXMLString(self.xmlFile, nodeKey.."#minMaxY"));
                            local minY = Utils.getNoNil(minY, defaultY);
                            local maxY = Utils.getNoNil(maxY, defaultY);
                            animCurve:addKeyframe({x=defaultX, y=minY, z=defaultZ, rx=defaultRX, ry=defaultRY, rz=defaultRZ, sx=1, sy=1, sz=1, time = 0});
                            animCurve:addKeyframe({x=defaultX, y=maxY, z=defaultZ, rx=defaultRX, ry=defaultRY, rz=defaultRZ, sx=1, sy=1, sz=1, time = 1});
                        end;
                        local alwaysVisible = Utils.getNoNil(getXMLBool(self.xmlFile, nodeKey.."#alwaysVisible"), false);
                        setVisibility(node, alwaysVisible);
                        table.insert(fillPlane.nodes, {node=node, animCurve = animCurve, alwaysVisible=alwaysVisible});
                    end;
                    nodeI = nodeI +1;
                end;
                if table.getn(fillPlane.nodes) > 0 then
                    if self.fillUnits[fillUnitIndex].defaultFillPlane == nil then
                        self.fillUnits[fillUnitIndex].defaultFillPlane = fillPlane;
                    end;
                    self.fillUnits[fillUnitIndex].fillPlanes[fillType] = fillPlane;
                end;
            end;
            i = i +1;
        end;
		local planesBase = fallbackOldKey .. ".measurementNodes.measurementNode";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".measurementNodes.measurementNode(0)") then
			planesBase = fallbackConfigKey..".measurementNodes.measurementNode";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".measurementNodes.measurementNode(0)") then
			planesBase = key..".measurementNodes.measurementNode";
		end;
		self.measurementNodes = {};
        local i=0;
        while true do
            local keyMeasurements = string.format(planesBase .. "(%d)", i);
            if not hasXMLProperty(self.xmlFile, keyMeasurements) then
                break;
            end;
            local node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, keyMeasurements .. "#index"));
            local fillUnitIndex = getXMLInt(self.xmlFile, keyMeasurements.."#fillUnitIndex");
            if self.fillUnits[fillUnitIndex] == nil then
                print("Warning: fillUnitIndex '"..tostring(fillUnitIndex).."' in measurementNode("..i..") does not point to a valid fillUnit!");
                break;
            end;
            if self.fillUnits[fillUnitIndex].measurementNodes == nil then
                self.fillUnits[fillUnitIndex].measurementNodes = {};
            end;
            table.insert(self.fillUnits[fillUnitIndex].measurementNodes, node);
            i=i+1;
        end;
        self.measurementTime = 0;
    end;

	self:setFillLevel(0, FillUtil.FILLTYPE_UNKNOWN);
    self.fillableDirtyFlag = self:getNextDirtyFlag();
    self.lastFillLevelChangeTime = 0;
	
	-- load data from FillVolume
	
	self.alsoUseFillVolumeLoadInfoForDischarge = Vehicle.getConfigurationValue(self.xmlFile, key, ".alsoUseFillVolumeLoadInfoForDischarge", "", getXMLBool, false, fallbackConfigKey, fallbackOldKey);
	
	if self.isClient then
        self.fillVolumes = {};
        self.fillVolumeDeformers = {};
        local i = 0;
		local fillVolumesBase = fallbackOldKey .. ".fillVolumes.volumes.volume";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".fillVolumes.volumes.volume(0)") then
			fillVolumesBase = fallbackConfigKey..".fillVolumes.volumes.volume";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".fillVolumes.volumes.volume(0)") then
			fillVolumesBase = key..".fillVolumes.volumes.volume";
		end;
        while true do
            local FVkey = string.format(fillVolumesBase .. "(%d)", i);
            if not hasXMLProperty(self.xmlFile, FVkey) then
                break;
            end
			
			local fillVolume = {};
			
            fillVolume.baseNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, FVkey.."#index"));
            fillVolume.allSidePlanes = Utils.getNoNil(getXMLBool(self.xmlFile, FVkey.."#allSidePlanes"), true);
			
			local defaultFillType = getXMLString(self.xmlFile, FVkey.."#defaultFillType");
            if defaultFillType ~= nil then
                local fillType = FillUtil.fillTypeNameToInt[defaultFillType];
                if fillType ~= nil then
                    fillVolume.defaultFillType = fillType;
                else
                    print("Warning: Invalid defaultFillType '"..tostring(defaultFillType).."' in '"..self.configFileName.."'");
                end;
            end;

			fillVolume.maxDelta = Utils.getNoNil(getXMLFloat(self.xmlFile, FVkey.."#maxDelta"), 1.0);
            fillVolume.maxSurfaceAngle = math.rad( Utils.getNoNil(getXMLFloat(self.xmlFile, FVkey.."#maxAllowedHeapAngle"), 35) );
			
            local maxPhysicalSurfaceAngle = math.rad(35);
            fillVolume.maxSubDivEdgeLength = Utils.getNoNil(getXMLFloat(self.xmlFile, FVkey.."#maxSubDivEdgeLength"), 0.9);
			
			local fillUnitIndex = Utils.getNoNil(getXMLInt(self.xmlFile, FVkey.."#fillUnitIndex"), i+1);
            if self.fillUnits == nil or self.fillUnits[fillUnitIndex] == nil then
                print("Warning: '"..self.configFileName.. "' could not determine capacity for fillVolume!");
            end
            local capacity = self.fillUnits[fillUnitIndex].capacity;
			
            fillVolume.volume = createFillPlaneShape(fillVolume.baseNode, "fillPlane", capacity, fillVolume.maxDelta, fillVolume.maxSurfaceAngle, maxPhysicalSurfaceAngle, fillVolume.maxSubDivEdgeLength, fillVolume.allSidePlanes);
            setVisibility(fillVolume.volume, false);
			
            fillVolume.deformers = {};
			if fillVolume.volume ~= nil then
                local j = 0;
                while true do
                    local node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, FVkey..".deformNode("..j..")#index"));
                    if node == nil then
                        break;
                    end
                    local initPos = { localToLocal(node, fillVolume.baseNode, 0,0,0) };
                    local polyline = findPolyline(fillVolume.volume, initPos[1],initPos[3]);
                    self.fillVolumeDeformers[node] = {node=node, initPos=initPos, posX=initPos[1], posZ=initPos[3], polyline=polyline, volume=fillVolume.volume, baseNode=fillVolume.baseNode};
                    j = j + 1;
                end;
            end;
			
			fillVolume.scrollSpeedDischarge = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, FVkey.."#scrollSpeedDischarge"), "0 0 0")) };
            fillVolume.scrollSpeedLoad = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, FVkey.."#scrollSpeedLoad"), "0 0 0")) };
            for i=1,3 do
                fillVolume.scrollSpeedDischarge[i] = fillVolume.scrollSpeedDischarge[i] / 1000;
                fillVolume.scrollSpeedLoad[i] = fillVolume.scrollSpeedLoad[i] / 1000;
            end
            fillVolume.uvPosition = {0, 0, 0};
            if fillVolume.volume ~= nil and fillVolume.volume ~= 0 then
                link(fillVolume.baseNode, fillVolume.volume);
                table.insert(self.fillVolumes, fillVolume);
            end
            i = i + 1;
		end;
		
		local fillHeightsBase = fallbackOldKey .. ".fillVolumes.heights.height";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".fillVolumes.heights.height(0)") then
			fillHeightsBase = fallbackConfigKey..".fillVolumes.heights.height";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".fillVolumes.heights.height(0)") then
			fillHeightsBase = key..".fillVolumes.heights.height";
		end;
		self.fillVolumeHeights = {};
        self.fillVolumeHeightRefNodeToFillVolumeHeight = {};
        local i=0;
        while true do
            local FHkey = string.format(fillHeightsBase .. "(%d)", i);
            if not hasXMLProperty(self.xmlFile, FHkey) then
                break;
            end
            local volumeHeight = {};
            volumeHeight.fillVolumeIndex = getXMLInt(self.xmlFile, FHkey.."#fillVolumeIndex");
            volumeHeight.volumeHeightIsDirty = false;
            volumeHeight.refNodes = {};
            local j=0;
            while true do
                local refNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, string.format("%s.refNode(%d)#index", FHkey, j)));
                if refNode == nil then
                    break;
                end
                table.insert(volumeHeight.refNodes, {refNode=refNode});
                self.fillVolumeHeightRefNodeToFillVolumeHeight[refNode] = volumeHeight;
                j=j+1;
            end
            volumeHeight.nodes = {};
            local j=0;
            while true do
                local node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, string.format("%s.node(%d)#index", FHkey, j)));
                if node == nil then
                    break;
                end
                if node ~= nil then
                    local baseScale = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, string.format("%s.node(%d)#baseScale", FHkey, j)), "1 1 1")) };
                    local scaleAxis = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, string.format("%s.node(%d)#scaleAxis", FHkey, j)), "0 0 0")) };
                    local scaleMax = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, string.format("%s.node(%d)#scaleMax", FHkey, j)), "0 0 0")) };
                    local basePosition = { getTranslation(node) };
                    local transAxis = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, string.format("%s.node(%d)#transAxis", FHkey, j)), "0 0 0")) };
                    local transMax = { Utils.getVectorFromString(Utils.getNoNil(getXMLString(self.xmlFile, string.format("%s.node(%d)#transMax", FHkey, j)), "0 0 0")) };
                    local orientateToWorldY = Utils.getNoNil(getXMLBool(self.xmlFile, string.format("%s.node(%d)#orientateToWorldY", FHkey, j)), false);
                    table.insert(volumeHeight.nodes, {node=node, baseScale=baseScale, scaleAxis=scaleAxis, scaleMax=scaleMax, basePosition=basePosition, transAxis=transAxis, transMax=transMax, orientateToWorldY=orientateToWorldY});
                end
                j=j+1;
            end
            table.insert(self.fillVolumeHeights, volumeHeight);
            i=i+1;
        end;
		
		self.fillVolumeLoadInfos = {};
        self.fillVolumeLoadInfos.name = "loadInfo";
        self.fillVolumeUnloadInfos = {};
        self.fillVolumeUnloadInfos.name = "unloadInfo";
        self.fillVolumeDischargeInfos = {};
        self.fillVolumeDischargeInfos.name = "dischargeInfo";
        for _,tbl in pairs( {self.fillVolumeLoadInfos, self.fillVolumeUnloadInfos, self.fillVolumeDischargeInfos} ) do
            local i=0;
			local xmlBase = fallbackOldKey .. ".fillVolumes."..tbl.name.."s."..tbl.name;
			if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".fillVolumes."..tbl.name.."s."..tbl.name .. "(0)") then
				xmlBase = fallbackConfigKey .. ".fillVolumes."..tbl.name.."s."..tbl.name;
			end;
			if key ~= nil and hasXMLProperty(self.xmlFile, key .. ".fillVolumes."..tbl.name.."s."..tbl.name .. "(0)") then
				xmlBase = key .. ".fillVolumes."..tbl.name.."s."..tbl.name;
			end;
            while true do
                if not hasXMLProperty(self.xmlFile, string.format(xmlBase .. "(%d)", i)) then
                    break;
                end
                local entry = {};
                entry.fillVolumeIndex = Utils.getNoNil(getXMLInt(self.xmlFile, string.format(xmlBase .. "(%d)#fillVolumeIndex", 1)), 1);
                entry.nodes = {};
                local j=0;
                while true do
                    local xmlNewKey = string.format(xmlBase .. "(%d).node(%d)", i, j);
                    if not hasXMLProperty(self.xmlFile, xmlNewKey) then
                        break;
                    end
                    local nodeEntry = {};
                    nodeEntry.node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, xmlNewKey .. "#index"));
                    nodeEntry.width = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlNewKey .. "#width"), 1.0);
                    nodeEntry.length = Utils.getNoNil(getXMLFloat(self.xmlFile, xmlNewKey .. "#length"), 1.0);
                    nodeEntry.fillVolumeHeightIndex = getXMLInt(self.xmlFile, xmlNewKey .. "#fillVolumeHeightIndex");
                    nodeEntry.priority = Utils.getNoNil(getXMLInt(self.xmlFile, xmlNewKey .. "#priority"), 1);
                    nodeEntry.minHeight = getXMLFloat(self.xmlFile, xmlNewKey .. "#minHeight");
                    nodeEntry.maxHeight = getXMLFloat(self.xmlFile, xmlNewKey .. "#maxHeight");
                    nodeEntry.minFillLevelPercentage = getXMLFloat(self.xmlFile, xmlNewKey .. "#minFillLevelPercentage");
                    nodeEntry.maxFillLevelPercentage = getXMLFloat(self.xmlFile, xmlNewKey .. "#maxFillLevelPercentage");
                    nodeEntry.heightForTranslation = getXMLFloat(self.xmlFile, xmlNewKey .. "#heightForTranslation");
                    nodeEntry.translationStart = Utils.getVectorNFromString(getXMLString(self.xmlFile, xmlNewKey .. "#translationStart"), 3);
                    nodeEntry.translationEnd = Utils.getVectorNFromString(getXMLString(self.xmlFile, xmlNewKey .. "#translationEnd"), 3);
                    nodeEntry.translationAlpha = 0;
                    table.insert(entry.nodes, nodeEntry);
                    j=j+1;
                end
                table.sort(entry.nodes, function(a, b) return a.priority > b.priority end);
                table.insert(tbl, entry);
                i=i+1;
            end;
        end;
	end;
	
	self.fillVolumeDirtyFlag = self:getNextDirtyFlag();
	
	-- load data from trailer
	
	self.tipAnimations = {};
	local animationsBase = fallbackOldKey .. ".tipAnimations.tipAnimation";
	if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".tipAnimations.tipAnimation(0)") then
		animationsBase = fallbackConfigKey..".tipAnimations.tipAnimation";
	end;
	if key ~= nil and hasXMLProperty(self.xmlFile, key..".tipAnimations.tipAnimation(0)") then
		animationsBase = key..".tipAnimations.tipAnimation";
	end;
    local i = 0;
    while true do
        local animKey = string.format(animationsBase .. "(%d)", i);
        if not hasXMLProperty(self.xmlFile, animKey) then
            break;
        end
		
        local tipAnimation = {};
        tipAnimation.name = getXMLString(self.xmlFile, animKey.."#name");
        if tipAnimation.name ~= nil then
            local i18n = g_i18n;
            if self.customEnvironment ~= nil then
                i18n = _G[self.customEnvironment].g_i18n;
            end
            tipAnimation.name = i18n:getText(tipAnimation.name);
        else
            tipAnimation.name = i + 1;
        end
        tipAnimation.dischargeEndTime = getXMLFloat(self.xmlFile, animKey.."#dischargeEndTime");
        if tipAnimation.dischargeEndTime ~= nil then
            tipAnimation.dischargeEndTime = tipAnimation.dischargeEndTime * 1000;
        end;
        tipAnimation.dischargeStartTime = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#dischargeStartTime"), 0)*1000;
        local animationName = getXMLString(self.xmlFile, animKey.."#animationName");
        tipAnimation.animationOpenSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#openSpeedScale"), 1);
        tipAnimation.animationCloseSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#closeSpeedScale"), -1);
        tipAnimation.unloadingSpeedScale = getXMLFloat(self.xmlFile, animKey.."#speedScale");
        if tipAnimation.unloadingSpeedScale == nil then
            tipAnimation.unloadingSpeedScale = tipAnimation.animationOpenSpeedScale;
        end;
        if animationName ~= nil then
            if self.playAnimation ~= nil and self.getAnimationDuration ~= nil then
                tipAnimation.animationName = animationName;
                tipAnimation.animationDuration = self:getAnimationDuration(animationName);
            else
                print("Error: tip animation "..i.." has animation name, but misses specialization AnimatedVehicle in "..self.configFileName);
            end;
        else
            local animationRootNode = Utils.indexToObject(self.components, getXMLString(self.xmlFile, animKey.."#rootNode"));
            if animationRootNode ~= nil then
                local animationCharSet = getAnimCharacterSet(animationRootNode);
                if animationCharSet ~= nil then
                    local clip = getAnimClipIndex(animationCharSet, getXMLString(self.xmlFile, animKey.."#clip"));
                    assignAnimTrackClip(animationCharSet, 0, clip);
                    setAnimTrackLoopState(animationCharSet, 0, false);
                    tipAnimation.animationCharSet = animationCharSet;
                    tipAnimation.animationDuration = getAnimClipDuration(animationCharSet, clip);
                end
            end
        end
        if tipAnimation.dischargeEndTime == nil and tipAnimation.animationDuration ~= nil then
            tipAnimation.dischargeEndTime = tipAnimation.animationDuration*2.0;
        end
        if tipAnimation.dischargeEndTime ~= nil then
            if self.isClient then
                tipAnimation.emitterShape = Utils.indexToObject(self.components, getXMLString(self.xmlFile, animKey..".emitterShape#node"));
                tipAnimation.emitCountScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey..".emitterShape#emitCountScale"), 1);
                tipAnimation.isAdditionalEffect = Utils.getNoNil(getXMLBool(self.xmlFile, animKey..".emitterShape#isAdditionalEffect"), false);
                tipAnimation.particleType = getXMLString(self.xmlFile, animKey..".emitterShape#particleType")
                tipAnimation.tipEffect = EffectManager:loadEffect(self.xmlFile, animKey..".tipEffect", self.components, self);
            end
            tipAnimation.doorAnimationName = getXMLString(self.xmlFile, animKey.."#doorAnimationName");
            tipAnimation.doorAnimationSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#doorAnimationSpeedScale"), 1.0);
            tipAnimation.doorAnimationOpenSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#doorAnimationOpenSpeedScale"), 1);
            tipAnimation.doorAnimationCloseSpeedScale = Utils.getNoNil(getXMLFloat(self.xmlFile, animKey.."#doorAnimationCloseSpeedScale"), -1);
            tipAnimation.fillVolumeUnloadInfoIndex = getXMLInt(self.xmlFile, animKey..".fillVolume.unloadInfo#index");
            tipAnimation.fillVolumeDischargeInfoIndex = getXMLInt(self.xmlFile, animKey..".fillVolume.dischargeInfo#index");
            tipAnimation.fillVolumeHeightIndex = getXMLInt(self.xmlFile, animKey..".fillVolume.height#index");
            table.insert(self.tipAnimations, tipAnimation);
        else
            print("Error: invalid tip animation "..i.." in "..self.configFileName);
        end
        i = i + 1;
    end
    if self.isClient then
        self.referenceParticleSystems = {};
        for _, tipAnimation in pairs(self.tipAnimations) do
            local fillUnitIndex = 1
            if tipAnimation.fillVolumeHeightIndex ~= nil then
                local volumeId = self.fillVolumeHeights[tipAnimation.fillVolumeHeightIndex].fillVolumeIndex;
                fillUnitIndex = self.fillVolumes[volumeId].fillUnitIndex;
            end
            if self.fillUnits[fillUnitIndex] ~= nil then
                for fillType, _ in pairs(self:getUnitFillTypes(fillUnitIndex)) do
                    if self.referenceParticleSystems[fillType] == nil then
                        local particleSystem = MaterialUtil.getParticleSystem(fillType, Utils.getNoNil(tipAnimation.particleType, "unloading"))
                        if particleSystem ~= nil then
                            local psClone = clone( particleSystem.shape, true, false, true );
                            local currentPS = {};
                            ParticleUtil.loadParticleSystemFromNode(psClone, currentPS, false, true, particleSystem.forceFullLifespan);
                            self.referenceParticleSystems[fillType] = currentPS;
                        end
                    end
                end
            end
        end
    end
    self.tipState = Trailer.TIPSTATE_CLOSED;
    self.fillLevelToTippedFillLevel = 1;
    self.tipReferencePoints = {};
    local i = 0;
	local animationsBase = fallbackOldKey .. ".tipReferencePoints.tipReferencePoint";
	if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".tipReferencePoints.tipReferencePoint(0)") then
		animationsBase = fallbackConfigKey..".tipReferencePoints.tipReferencePoint";
	end;
	if key ~= nil and hasXMLProperty(self.xmlFile, key..".tipReferencePoints.tipReferencePoint(0)") then
		animationsBase = key..".tipReferencePoints.tipReferencePoint";
	end;
    while true do
        local referenceKey = string.format(animationsBase .. "(%d)", i);
        if not hasXMLProperty(self.xmlFile, referenceKey) then
            break;
        end
        local node = Utils.indexToObject(self.components, getXMLString(self.xmlFile, referenceKey.."#index"));
        if node ~= nil then
            local width = Utils.getNoNil(getXMLFloat(self.xmlFile, referenceKey.."#width"), 0);
            local maxZOffset = Utils.getNoNil(getXMLFloat(self.xmlFile, referenceKey.."#maxZOffset"), 2);
            table.insert(self.tipReferencePoints, {node=node, width=width, zOffset=0, maxZOffset=maxZOffset});
        end
        i = i + 1;
    end
    if self.tipReferencePoints ~= nil then
        self.numTipReferencePoints = table.getn(self.tipReferencePoints);
    else
        self.numTipReferencePoints = 0;
    end
    self.preferedTipReferencePointIndex = 1
    
    if self.isClient then
		local animationsBase = fallbackOldKey .. ".tipRotationNodes.tipRotationNode";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".tipRotationNodes.tipRotationNode(0)") then
			animationsBase = fallbackConfigKey..".tipRotationNodes.tipRotationNode";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".tipRotationNodes.tipRotationNode(0)") then
			animationsBase = key..".tipRotationNodes.tipRotationNode";
		end;
        self.tipRotationNodes = Utils.loadRotationNodes(self.xmlFile, {}, animationsBase, "trailer", self.components);
		
		local animationsBase = fallbackOldKey .. ".tipScrollerNodes.tipScrollerNode";
		if key ~= nil and hasXMLProperty(self.xmlFile, fallbackConfigKey..".tipScrollerNodes.tipScrollerNode(0)") then
			animationsBase = fallbackConfigKey..".tipScrollerNodes.tipScrollerNode";
		end;
		if key ~= nil and hasXMLProperty(self.xmlFile, key..".tipScrollerNodes.tipScrollerNode(0)") then
			animationsBase = key..".tipScrollerNodes.tipScrollerNode";
		end;
        self.tipScrollers = Utils.loadScrollers(self.components, self.xmlFile, animationsBase, {}, false);
    end
    local start = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".groundDropArea", "#startIndex", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    local width = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".groundDropArea", "#widthIndex", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    local height = Utils.indexToObject(self.components, Vehicle.getConfigurationValue(self.xmlFile, key, ".groundDropArea", "#heightIndex", getXMLString, nil, fallbackConfigKey, fallbackOldKey));
    if start ~= nil and width ~= nil and height ~= nil then
        local area = {};
        area.start = start;
        area.width = width;
        area.height = height;
        self.groundDropArea = area;
    end
    self.remainingFillDelta = 0;
    self.isSelectable = true;
    self.couldNotDropTimer = 0;
    self.couldNotDropTimerThreshold = 1000;
    self.allowTipDischarge = Vehicle.getConfigurationValue(self.xmlFile, key, ".allowTipDischarge", "#value", getXMLBool, true, fallbackConfigKey, fallbackOldKey);
    self.trailer = {};
    self.trailer.fillUnitIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".trailer", "#fillUnitIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
    self.trailer.unloadInfoIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".trailer", "#unloadInfoIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
    self.trailer.loadInfoIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".trailer", "#loadInfoIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
    self.trailer.dischargeInfoIndex = Vehicle.getConfigurationValue(self.xmlFile, key, ".trailer", "#dischargeInfoIndex", getXMLInt, 1, fallbackConfigKey, fallbackOldKey);
    self.trailer.stopTipToGroundIfEmpty = Vehicle.getConfigurationValue(self.xmlFile, key, ".trailer", "#stopTipToGroundIfEmpty", getXMLBool, false, fallbackConfigKey, fallbackOldKey);
    if savegame ~= nil then
        self.preferedTipReferencePointIndex = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key .. "#preferedTipReferencePointIndex"), self.preferedTipReferencePointIndex);
    end
	
	-- end of loading
	
	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.fillConfConfigurations.fillConfConfiguration", self.configurations["fillConf"], self.components, self);
end;

function FillableConfiguration:postLoad(savegame)
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
