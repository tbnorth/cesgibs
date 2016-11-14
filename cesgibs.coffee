
## time of last imagery change - track to limit request rate
last_date_change_time = Date.now()
## date when imagery last changed
last_date = null

map_time = ->
    ## build an imagery provider for a particular day

    time = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)
    time = "#{time.year}-#{('0'+time.month)[-2..]}-#{('0'+time.day)[-2..]}"

    prov = new Cesium.WebMapTileServiceImageryProvider
        url: "//map1.vis.earthdata.nasa.gov/wmts-geo/wmts.cgi?TIME=#{time}",
        layer: "MODIS_Terra_CorrectedReflectance_TrueColor",
        style: "",
        format: "image/jpeg",
        tileMatrixSetID: "EPSG4326_250m",
        maximumLevel: 8,
        tileWidth: 256,
        tileHeight: 256,
        tilingScheme: gibs.GeographicTilingScheme()

    prov._date_loader = map_time

    return prov

cesgibs_init = ->

    last_date = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)

    ## add a base layer icon
    arr = viewer.baseLayerPicker.viewModel.imageryProviderViewModels
    arr.push new Cesium.ProviderViewModel
        name: 'MODIS imagery'
        tooltip: "Daily MODIS images"
        iconUrl: "http://cesiumjs.org/releases/1.26/Build/Cesium/Widgets/Images/ImageryProviders/mapboxSatellite.png"
        creationFunction: map_time

    viewer.clock.onTick.addEventListener ->
        ## see if it's a different day, and check for daily layers

        # see if 1 second has elapsed since last image change
        now = Date.now()
        if now - last_date_change_time < 1000
            return
        last_date_change_time = now

        now = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)
        day_change = (
            now.day != last_date.day or
            now.month != last_date.month or
            now.year != last_date.year
        )
        if day_change
            last_date = now

            layers = viewer.scene.imageryLayers
            console.log layers
            for n in [0..layers.length]
                layer = layers.get(n)
                if layer and layer.imageryProvider._date_loader
                    layers.remove layer
                    layers.addImageryProvider layer.imageryProvider._date_loader()
                    break

