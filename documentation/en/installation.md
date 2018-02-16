# Instalation of specialization into vehicle

This tutorial will explain, how to use FillableConfiguration specialization.

## Step 1

Place `FillableConfiguration.lua` from `release` somewhere in you mod's directory. Idealy in folder named `scripts` etc...

## Step 2

Register specialization in `modDesc.xml`.

You will need to tell game that this script is part of your mod. Here is an example:

```xml
<modDesc descVersion="37">
	<!-- rest of your modDesc here -->
	<specializations>
		<!-- rest of the specializations -->
		<specialization name="FillableConfiguration" className="FillableConfiguration" filename="__path_to_script__/FillableConfiguration.lua"/>
	</specializations>
</modDesc>
```

## Step 3

Now you need to add FillableConfiguration specialization into your vehicle type. This is done also in `modDesc.xml` in `<vehicleTypes>` section. Here is an example:

```xml
<modDesc descVersion="37">
	<!-- rest of your modDesc here -->
	<vehicleTypes>
		<!-- maybe other vehicleTypes -->
		<type name="yourVehicleType" className="Vehicle" filename="$dataS/scripts/vehicles/Vehicle.lua">
			<!-- rest of vehicle specializations here -->
			<specialization name="FillableConfiguration"/>
		</type>
	</vehicleTypes>
</modDesc>
```

By now you have done minimal modDesc instalation. Now you have to go into vehicle's xml file and set some configuraions

## Step 4

In vehicle's xml file you can configure this tags (almost all form Fillable, FillVolume and Trailer):

* `supportsFillTriggers`
* `fillLitersPerSecond`
* `unitFillTime`
* `fillTypeChangeThreshold`
* `fillUnits`
* `fillRootNode`
* `fillMassNode`
* `exactFillRootNode`
* `fillAutoAimTargetNode`
* `attacherPipe`
* `allowFillFromAir`
* `unloadTrigger`
* `fillPlanes`
* `measurementNodes`

* `alsoUseFillVolumeLoadInfoForDischarge`
* `fillVolumes`

* `tipAnimations`
* `tipReferencePoints`
* `tipRotationNodes`
* `tipScrollerNodes`
* `groundDropArea`
* `allowTipDischarge`
* `trailer`

This specialization also allows you to use `objectChange` tags in configuration.
