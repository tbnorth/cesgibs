# CesGibs

CesGibs encapsulates the addition of time varying baselayers (daily
satellite imagery from MODIS etc.) to Cesium.

`CesGibs` is [Cesium](https://cesiumjs.org/) plus
[GIBS](https://wiki.earthdata.nasa.gov/display/GIBS/), NASA's 
Global Imagery Browse Services, although CesGibs may end up managing
more than GIBS sources.

To use CesGibs, include two scripts in the HEAD of your page:
```{html}
<html>
<head>
...
<script src="gibs.js"></script>
<script src="cesgibs/cesgibs.js"></script>
</head>
```

`gibs.js` isn't part of CesGibs, you can
[get it from NASA](https://earthdata.nasa.gov/labs/gibs/lib/gibs/gibs.js).
`cesgibs.js` is [part of this repository](./cesgibs.js).

Then, after you've constructed the Cesium viewer in your code, initialize
CesGibs:
```{javascript}
cesgibs = new CesGibs.CesGibs(viewer);
```

If you want a control panel to alter Contrast / Gamma etc. in the baselayer imagery,
include an element like this in your HTML:
```{html}
<div id="toolbar2" class="cesgibs_imgadj"></div>
```
And after you create `cesgibs` call `cesgibs.imgadj("toolbar2");`.
If you don't want CesGibs to do any styling on the control panel, leave out the
`class="cesgibs_imgadj"` part.

CesGibs is written in [CoffeeScript](http://coffeescript.org/) with the javascript
version included in this repository.

