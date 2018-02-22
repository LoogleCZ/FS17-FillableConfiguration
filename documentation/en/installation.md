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

For proper work of this specialization you will need to have one l10n text. Text is called `l10n_fillableConfiguration` and it is the text for display in shop with configuration. Here is example:

```xml
<modDesc descVersion="37">
	<!-- rest of your modDesc here -->
	<l10n>
		<text name="l10n_fillableConfiguration">
			<en>Fillable configuration</en>
			<de>Fillable configuration</de>
			<cz>Nastavení nástavby</cz>
		</text>
	</l10n>
</modDesc>
```

## Step 5

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

Here is brief example of usage of this script:

```xml
<vehicle type="yourVehicleType">
	<!-- rest of vehicle's settings here -->

	<!-- here you can see that you don't have to use configuration option for all available tags if config is same in all cases... -->
	<tipReferencePoints>
		<tipReferencePoint index="0>9|0" width="2"/>
		<tipReferencePoint index="0>9|1" width="6"/>
		<tipReferencePoint index="0>9|2" width="1"/>
	</tipReferencePoints>
	<fillConfConfigurations>
		<fillConfConfiguration name="$l10n_bez_nastavby" price="0">
			<!-- here we're changing trailer's capacity.. -->
			<fillUnits>
				<fillUnit unit="$l10n_unit_literShort" fillTypeCategories="bulk" capacity="21000"/>
			</fillUnits>
			<!-- and we're using object change nodes... -->
			<objectChange node="0>0|0|0|0|3" visibilityActive="false" />
			<objectChange node="0>0|0|0|0|4|0" visibilityActive="false" />
			<objectChange node="0>0|0|0|0|9" visibilityActive="false" />
			<objectChange node="0>0|0|0|0|4|7" visibilityActive="false" />
		</fillConfConfiguration>
		<fillConfConfiguration name="$l10n_nastavba_stredni" price="2500" icon="$dataS2/menu/hud/configurations/config_edition.png">
			<!-- We have three capacity setting with different pricing -->
			<fillUnits>
				<fillUnit unit="$l10n_unit_literShort" fillTypeCategories="bulk" capacity="25000"/>
			</fillUnits>
			<objectChange node="0>0|0|0|0|3" visibilityActive="false" />
			<objectChange node="0>0|0|0|0|4|0" visibilityActive="false" />
			<objectChange node="0>0|0|0|0|9" visibilityActive="true" />
			<objectChange node="0>0|0|0|0|4|7" visibilityActive="true" />
		</fillConfConfiguration>
		<fillConfConfiguration name="$l10n_nastavba_velka" price="5000" icon="$dataS2/menu/hud/configurations/config_edition.png">
			<fillUnits>
				<fillUnit unit="$l10n_unit_literShort" fillTypeCategories="bulk" capacity="28000"/>
			</fillUnits>
			<objectChange node="0>0|0|0|0|3" visibilityActive="true" />
			<objectChange node="0>0|0|0|0|4|0" visibilityActive="true" />
			<objectChange node="0>0|0|0|0|9" visibilityActive="true" />
			<objectChange node="0>0|0|0|0|4|7" visibilityActive="true" />
		</fillConfConfiguration>
	</fillConfConfigurations>
</vehicle>
```
