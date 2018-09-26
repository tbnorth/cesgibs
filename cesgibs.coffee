
class CesGibs
    gibs_layers: [
        name: 'Terra imagery',
        tooltip: "Daily MODIS Terra images"
        meta:
            layer_name: "MODIS_Terra_CorrectedReflectance_TrueColor"
            res: '250m'
            format: "image/jpeg"
      ,
        name: 'Aqua imagery',
        tooltip: "Daily MODIS Aqua images"
        meta:
            layer_name: "MODIS_Aqua_CorrectedReflectance_TrueColor"
            res: '250m'
            format: "image/jpeg"
      ,
        name: 'VIIRS imagery',
        tooltip: "Daily VIIRS images"
        meta:
            layer_name: "VIIRS_SNPP_CorrectedReflectance_TrueColor"
            res: '250m'
            format: "image/jpeg"
      ,
        name: 'Sea Surface Temp MUR',
        tooltip: "GHRSST_L4_MUR_Sea_Surface_Temperature"
        meta:
            layer_name: "GHRSST_L4_MUR_Sea_Surface_Temperature"
            res: '1km'
            format: "image/png"
      ,
        name: 'Sea Surface Temp G1SST',
        tooltip: "GHRSST_L4_G1SST_Sea_Surface_Temperature"
        meta:
            layer_name: "GHRSST_L4_G1SST_Sea_Surface_Temperature"
            res: '1km'
            format: "image/png"
      ,
        name: 'Terra chl',
        tooltip: "MODIS Terra Chlorophyll"
        meta:
            layer_name: "MODIS_Terra_Chlorophyll_A"
            res: '1km'
            format: "image/png"
      ,
        name: 'Aqua chl',
        tooltip: "MODIS Aqua Chlorophyll"
        meta:
            layer_name: "MODIS_Aqua_Chlorophyll_A"
            res: '1km'
            format: "image/png"
    ]

    resolutions:
        "250m":
            tileMatrixSetID: "EPSG4326_250m"
            maximumLevel: 8
        "500m":
            tileMatrixSetID: "EPSG4326_500m"
            maximumLevel: 7
        "1km":
            tileMatrixSetID: "EPSG4326_1km"
            maximumLevel: 6
        "2km":
            tileMatrixSetID: "EPSG4326_2km"
            maximumLevel: 5

    css: """
    <style>
        /* style inserted by cesgibs.js (from cesgibs.coffee) */
        .cesgibs_imgadj {
            background: rgba(90, 90, 90, 0.8);
            padding: 4px;
            border-radius: 4px;
            font-size: 60%;
        }
        .cesgibs_imgadj input {
            vertical-align: middle;
            padding-top: 1px;
            padding-bottom: 1px;
        }
        .cesgibs_imgadj td {
            font-size: 60%;
        }
        .cesgibs_imgadj input[type=range] {
            height: 8;
        }
    </style>
    """

    template: """
    <!-- table inserted by cesgibs.js (from cesgibs.coffee) -->
    <table><tbody><tr><td>Brightness</td>
    <td><input type="range" min="0" max="3" step="0.02" data-bind="value: brightness, valueUpdate: 'input'">
    <input type="text" size="5" data-bind="value: brightness"></td></tr>
    <tr><td>Contrast</td><td>
    <input type="range" min="0" max="3" step="0.02" data-bind="value: contrast, valueUpdate: 'input'">
    <input type="text" size="5" data-bind="value: contrast"></td></tr>
    <tr><td>Hue</td><td>
    <input type="range" min="0" max="3" step="0.02" data-bind="value: hue, valueUpdate: 'input'">
    <input type="text" size="5" data-bind="value: hue"></td></tr>
    <tr><td>Saturation</td><td>
    <input type="range" min="0" max="3" step="0.02" data-bind="value: saturation, valueUpdate: 'input'">
    <input type="text" size="5" data-bind="value: saturation"></td></tr>
    <tr><td>Gamma</td><td>
    <input type="range" min="0" max="3" step="0.02" data-bind="value: gamma, valueUpdate: 'input'">
    <input type="text" size="5" data-bind="value: gamma"></td></tr></tbody></table>
    """

    ## time of last imagery change - track to limit request rate
    last_date_change_time: Date.now()
    ## date when imagery last changed
    last_date: null

    viewer: null

    imgadj: (ele_id) ->

        # from the Cesium Sandcastle demo
        imageryLayers = viewer.imageryLayers

        # The viewModel tracks the state of our mini application.
        @viewModel =
            brightness: 0
            contrast: 0
            hue: 0
            saturation: 0
            gamma: 0

        # Convert the viewModel members into knockout observables.
        Cesium.knockout.track @viewModel

        # Bind the viewModel to the DOM elements of the UI that call for it.
        toolbar = document.getElementById ele_id
        toolbar.innerHTML = @template
        head = (document.getElementsByTagName "HEAD")[0]
        head.insertAdjacentHTML 'beforeEnd', @css
        Cesium.knockout.applyBindings @viewModel, toolbar

        # Make the active imagery layer a subscriber of the viewModel.
        subscribeLayerParameter = (name) =>
            (Cesium.knockout.getObservable @viewModel, name).subscribe(
                (newValue) ->
                    if imageryLayers.length > 0
                        layer = imageryLayers.get 0
                        layer[name] = newValue
            )

        for attr of @viewModel
            subscribeLayerParameter attr

        # Make the viewModel react to base layer changes.
        @updateViewModel = =>
            if imageryLayers.length > 0
                layer = imageryLayers.get 0
                for attr of @viewModel
                    @viewModel[attr] = layer[attr]

        imageryLayers.layerAdded.addEventListener @updateViewModel
        imageryLayers.layerRemoved.addEventListener @updateViewModel
        imageryLayers.layerMoved.addEventListener @updateViewModel
        @updateViewModel()

    map_time: (meta) ->

        func = =>
            ## build function that returns an imagery provider for a particular day

            time = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)
            time = "#{time.year}-#{('0'+time.month)[-2..]}-#{('0'+time.day)[-2..]}"

            # remove any existing gibs layers
            layers = viewer.scene.imageryLayers
            culls = []
            for n in [0..layers.length]
                layer = layers.get(n)
                if layer and layer.imageryProvider and layer.imageryProvider._date_loader
                    culls.push layer
            for cull in culls
                layers.remove cull

            prov = new Cesium.WebMapTileServiceImageryProvider
                url: "https://map1.vis.earthdata.nasa.gov/wmts-geo/wmts.cgi?TIME=#{time}",
                layer: meta.layer_name,
                style: "",
                format: meta.format,
                tileMatrixSetID: @resolutions[meta.res].tileMatrixSetID,
                maximumLevel: @resolutions[meta.res].maximumLevel,
                tileWidth: 256,
                tileHeight: 256,
                tilingScheme: gibs.GeographicTilingScheme()

            prov._date_loader = func

            viewer._cesgibs_active = true

            return prov

        return func

    constructor: (cesium_viewer) ->

        viewer = cesium_viewer
        last_date = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)

        ## add a base layer icon
        arr = viewer.baseLayerPicker.viewModel.imageryProviderViewModels
        for layer in @gibs_layers
            arr.push new Cesium.ProviderViewModel
                name: layer.name
                tooltip: layer.tooltip
                iconUrl: "http://cesiumjs.org/releases/1.29/Build/Cesium/Widgets/Images/ImageryProviders/mapboxSatellite.png"
                creationFunction: @map_time layer.meta
        viewer.clock.onTick.addEventListener ->
            ## see if it's a different day, and check for daily layers

            if not viewer._cesgibs_active
                return

            # see if 1 second has elapsed since last image change
            now = Date.now()
            if now - last_date_change_time < 1000
                return
            last_date_change_time = now

            layers = viewer.scene.imageryLayers

            # when the day changes and we add a new layer, its "baselayerness"
            # is lost, despite attempt below, so switching to a non-gibs
            # baselayer doesn't unload our layer, so search layers for a
            # non-gibs baselayer, and if found, remove ours
            base_layer_seen = false
            our_layer = null
            for n in [0..layers.length]
                layer = layers.get(n)
                if not layer
                    continue
                if layer._isBaseLayer and not layer.imageryProvider._date_loader
                    base_layer_seen = true
                if layer.imageryProvider._date_loader
                    our_layer = layer
            if base_layer_seen and our_layer
                viewer.scene.imageryLayers.remove our_layer
                viewer._cesgibs_active = false
                return

            now = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)
            day_change = (
                now.day != last_date.day or
                now.month != last_date.month or
                now.year != last_date.year
            )
            if day_change
                last_date = now

                for n in [0..layers.length]
                    layer = layers.get(n)
                    if layer and layer.imageryProvider._date_loader
                        layers.remove layer
                        # layers.addImageryProvider layer.imageryProvider._date_loader()
                        new_layer = new Cesium.ImageryLayer layer.imageryProvider._date_loader()
                        layers.add new_layer
                        # this is insufficient / too soon, hence "our_layer" code above
                        # new_layer._isBaseLayer = true
                        break

window.CesGibs = {CesGibs: CesGibs}

