// Generated by CoffeeScript 1.6.3
var cesgibs_init, last_date, last_date_change_time, map_time, resolutions;

last_date_change_time = Date.now();

last_date = null;

resolutions = {
  "250m": {
    tileMatrixSetID: "EPSG4326_250m",
    maximumLevel: 8
  },
  "500m": {
    tileMatrixSetID: "EPSG4326_500m",
    maximumLevel: 7
  },
  "1km": {
    tileMatrixSetID: "EPSG4326_1km",
    maximumLevel: 6
  },
  "2km": {
    tileMatrixSetID: "EPSG4326_2km",
    maximumLevel: 5
  }
};

map_time = function(meta) {
  var func;
  console.log("Building", meta.layer_name);
  func = function() {
    var cull, culls, layer, layers, n, prov, time, _i, _j, _len, _ref;
    time = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime);
    time = "" + time.year + "-" + ('0' + time.month).slice(-2) + "-" + ('0' + time.day).slice(-2);
    layers = viewer.scene.imageryLayers;
    culls = [];
    for (n = _i = 0, _ref = layers.length; 0 <= _ref ? _i <= _ref : _i >= _ref; n = 0 <= _ref ? ++_i : --_i) {
      layer = layers.get(n);
      if (layer && layer.imageryProvider && layer.imageryProvider._date_loader) {
        culls.push(layer);
      }
    }
    for (_j = 0, _len = culls.length; _j < _len; _j++) {
      cull = culls[_j];
      layers.remove(cull);
    }
    prov = new Cesium.WebMapTileServiceImageryProvider({
      url: "//map1.vis.earthdata.nasa.gov/wmts-geo/wmts.cgi?TIME=" + time,
      layer: meta.layer_name,
      style: "",
      format: meta.format,
      tileMatrixSetID: resolutions[meta.res].tileMatrixSetID,
      maximumLevel: resolutions[meta.res].maximumLevel,
      tileWidth: 256,
      tileHeight: 256,
      tilingScheme: gibs.GeographicTilingScheme()
    });
    prov._date_loader = func;
    viewer._cesgibs_active = true;
    return prov;
  };
  return func;
};

cesgibs_init = function() {
  var arr, gibs_layers, layer, _i, _len;
  gibs_layers = [
    {
      name: 'Terra imagery',
      tooltip: "Daily MODIS Terra images",
      meta: {
        layer_name: "MODIS_Terra_CorrectedReflectance_TrueColor",
        res: '250m',
        format: "image/jpeg"
      }
    }, {
      name: 'Aqua imagery',
      tooltip: "Daily MODIS Aqua images",
      meta: {
        layer_name: "MODIS_Aqua_CorrectedReflectance_TrueColor",
        res: '250m',
        format: "image/jpeg"
      }
    }, {
      name: 'Sea Surface Temp MUR',
      tooltip: "GHRSST_L4_MUR_Sea_Surface_Temperature",
      meta: {
        layer_name: "GHRSST_L4_MUR_Sea_Surface_Temperature",
        res: '1km',
        format: "image/png"
      }
    }, {
      name: 'Sea Surface Temp G1SST',
      tooltip: "GHRSST_L4_G1SST_Sea_Surface_Temperature",
      meta: {
        layer_name: "GHRSST_L4_G1SST_Sea_Surface_Temperature",
        res: '1km',
        format: "image/png"
      }
    }, {
      name: 'Terra chl',
      tooltip: "MODIS Terra Chlorophyll",
      meta: {
        layer_name: "MODIS_Terra_Chlorophyll_A",
        res: '1km',
        format: "image/png"
      }
    }, {
      name: 'Aqua chl',
      tooltip: "MODIS Aqua Chlorophyll",
      meta: {
        layer_name: "MODIS_Aqua_Chlorophyll_A",
        res: '1km',
        format: "image/png"
      }
    }
  ];
  last_date = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime);
  arr = viewer.baseLayerPicker.viewModel.imageryProviderViewModels;
  for (_i = 0, _len = gibs_layers.length; _i < _len; _i++) {
    layer = gibs_layers[_i];
    console.log(layer);
    console.log('YY', layer.layer_name);
    arr.push(new Cesium.ProviderViewModel({
      name: layer.name,
      tooltip: layer.tooltip,
      iconUrl: "http://cesiumjs.org/releases/1.26/Build/Cesium/Widgets/Images/ImageryProviders/mapboxSatellite.png",
      creationFunction: map_time(layer.meta)
    }));
    console.log('XX', layer.layer_name);
  }
  return viewer.clock.onTick.addEventListener(function() {
    var base_layer_seen, day_change, layers, n, new_layer, now, our_layer, _j, _k, _ref, _ref1, _results;
    if (!viewer._cesgibs_active) {
      return;
    }
    now = Date.now();
    if (now - last_date_change_time < 1000) {
      return;
    }
    last_date_change_time = now;
    layers = viewer.scene.imageryLayers;
    base_layer_seen = false;
    our_layer = null;
    for (n = _j = 0, _ref = layers.length; 0 <= _ref ? _j <= _ref : _j >= _ref; n = 0 <= _ref ? ++_j : --_j) {
      layer = layers.get(n);
      if (!layer) {
        continue;
      }
      if (layer._isBaseLayer && !layer.imageryProvider._date_loader) {
        base_layer_seen = true;
      }
      if (layer.imageryProvider._date_loader) {
        our_layer = layer;
      }
    }
    if (base_layer_seen && our_layer) {
      viewer.scene.imageryLayers.remove(our_layer);
      viewer._cesgibs_active = false;
      return;
    }
    now = Cesium.JulianDate.toGregorianDate(viewer.clock.currentTime);
    day_change = now.day !== last_date.day || now.month !== last_date.month || now.year !== last_date.year;
    if (day_change) {
      last_date = now;
      _results = [];
      for (n = _k = 0, _ref1 = layers.length; 0 <= _ref1 ? _k <= _ref1 : _k >= _ref1; n = 0 <= _ref1 ? ++_k : --_k) {
        layer = layers.get(n);
        if (layer && layer.imageryProvider._date_loader) {
          layers.remove(layer);
          new_layer = new Cesium.ImageryLayer(layer.imageryProvider._date_loader());
          layers.add(new_layer);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  });
};
