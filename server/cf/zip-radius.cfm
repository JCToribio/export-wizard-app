<!-- zip-radius.cfm
  Given a center zip and radiusMiles, returns an array of zip strings within the radius.
  This example assumes a zip_codes table with columns: zip (varchar), lat (float), lon (float).
  For performance prefer precomputed nearby zips table in production.
-->
<cfsetting enablecfoutputonly="yes">
<cfscript>
  var req = GetHttpRequestData();
  var raw = req.content;
  if (len(trim(raw)) eq 0) raw = '{}';
  var body = deserializeJSON(raw);
  var centerZip = body.zip;
  var radius = body.radiusMiles ?: 25;

  if (!len(trim(centerZip))){ writeOutput(serializeJSON({ zipList: [] })); abort; }

  // get center lat/lon
  var qCenter = queryExecute("SELECT TOP 1 lat, lon FROM zip_codes WHERE zip = ?", [ {value:centerZip,cfsqltype:'cf_sql_varchar'} ], {datasource:'MyMSSQLDSN'});
  if (qCenter.recordCount eq 0){ writeOutput(serializeJSON({ zipList: [] })); abort; }
  var lat0 = qCenter.lat[1]; var lon0 = qCenter.lon[1];

  // bounding box to limit
  var milesPerDegreeLat = 69; // approx
  var deltaLat = radius / milesPerDegreeLat;
  var deltaLon = radius / ( abs(cos( lat0 * 3.14159265/180 )) * milesPerDegreeLat );
  var minLat = lat0 - deltaLat; var maxLat = lat0 + deltaLat;
  var minLon = lon0 - deltaLon; var maxLon = lon0 + deltaLon;

  var qZips = queryExecute("SELECT zip, lat, lon FROM zip_codes WHERE lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?", [ {value:minLat,cfsqltype:'cf_sql_float'},{value:maxLat,cfsqltype:'cf_sql_float'},{value:minLon,cfsqltype:'cf_sql_float'},{value:maxLon,cfsqltype:'cf_sql_float'} ], {datasource:'MyMSSQLDSN'});

  var zipList = [];
  for (var i=1; i LTE qZips.recordCount; i++){
    // Haversine distance
    var lat1 = lat0 * 3.14159265/180; var lon1 = lon0 * 3.14159265/180;
    var lat2 = qZips.lat[i] * 3.14159265/180; var lon2 = qZips.lon[i] * 3.14159265/180;
    var dlat = lat2 - lat1; var dlon = lon2 - lon1;
    var a = sin(dlat/2)^2 + cos(lat1) * cos(lat2) * (sin(dlon/2)^2);
    var c = 2 * atan2( sqrt(a), sqrt(1-a) );
    var earthRadiusMiles = 3959;
    var dist = earthRadiusMiles * c;
    if (dist <= radius){ arrayAppend(zipList, qZips.zip[i]); }
  }

  writeOutput( serializeJSON({ zipList: zipList }) );
</cfscript>
