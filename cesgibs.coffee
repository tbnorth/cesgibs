
## time of last imagery change - track to limit request rate
last_date_change_time = Date.now()
## date when imagery last changed
last_date = null

map_time = (layer) -> 

    console.log "Building", layer
    
    func = ->
        ## build function that returns an imagery provider for a particular day
    
        time = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)
        time = "#{time.year}-#{('0'+time.month)[-2..]}-#{('0'+time.day)[-2..]}"
    
        prov = new Cesium.WebMapTileServiceImageryProvider
            url: "//map1.vis.earthdata.nasa.gov/wmts-geo/wmts.cgi?TIME=#{time}",
            layer: layer,
            style: "",
            format: "image/jpeg",
            tileMatrixSetID: "EPSG4326_250m",
            maximumLevel: 8,
            tileWidth: 256,
            tileHeight: 256,
            tilingScheme: gibs.GeographicTilingScheme()
    
        prov._date_loader = func
    
        viewer._cesgibs_active = true
    
        return prov
        
    return func

cesgibs_init = ->

    gibs_layers = [
        name: 'Terra imagery',
        tooltip: "Daily MODIS Terra images"
        layer_name: "MODIS_Terra_CorrectedReflectance_TrueColor"
    ]

    last_date = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime)

    ## add a base layer icon
    arr = viewer.baseLayerPicker.viewModel.imageryProviderViewModels
    for layer in gibs_layers
        console.log layer
        console.log 'YY', layer.layer_name
        arr.push new Cesium.ProviderViewModel
            name: layer.name
            tooltip: layer.tooltip
            iconUrl: "http://cesiumjs.org/releases/1.26/Build/Cesium/Widgets/Images/ImageryProviders/mapboxSatellite.png"
            creationFunction: map_time layer.layer_name
        console.log 'XX', layer.layer_name

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

