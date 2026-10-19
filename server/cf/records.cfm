<!-- records.cfm
  Returns paginated records according to filters+pagination.
  Expects POST JSON: filters + pagination {page, pageSize}
-->
<cfsetting enablecfoutputonly="yes">
<cfscript>
  var req = GetHttpRequestData();
  var raw = req.content;
  if (len(trim(raw)) eq 0) raw = '{}';
  var body = deserializeJSON(raw);
  var filters = structKeyExists(body,'filters') ? body.filters : body;
  var page = structKeyExists(body,'pagination') ? body.pagination.page : (structKeyExists(body,'page') ? body.page : 1);
  var pageSize = structKeyExists(body,'pagination') ? body.pagination.pageSize : (structKeyExists(body,'pageSize') ? body.pageSize : 25);

  function buildWhere(filters){
    var clauses = [];
    if (structKeyExists(filters, 'contactMethods') && arrayLen(filters.contactMethods)){
      var lst = [];
      for (m in filters.contactMethods){ arrayAppend(lst, "<cfqueryparam value='" & m & "' cfsqltype='cf_sql_varchar'>") }
      arrayAppend(clauses, "r.contact_method IN (" & arrayToList(lst, ',') & ")")
    }
    if (structKeyExists(filters, 'specialties') && arrayLen(filters.specialties)){
      var sp = [];
      for (s in filters.specialties){ arrayAppend(sp, "<cfqueryparam value='" & s & "' cfsqltype='cf_sql_varchar'>") }
      // join will be used; filter through specialty names
      arrayAppend(clauses, "s.name IN (" & arrayToList(sp, ',') & ")")
    }
    if (structKeyExists(filters, 'zipList') && arrayLen(filters.zipList)){
      var zips = [];
      for (z in filters.zipList){ arrayAppend(zips, "<cfqueryparam value='" & z & "' cfsqltype='cf_sql_varchar'>") }
      arrayAppend(clauses, "r.zip IN (" & arrayToList(zips, ',') & ")")
    }
    return clauses;
  }

  var whereClauses = buildWhere(filters);
  var whereSql = '';
  if (arrayLen(whereClauses)) whereSql = ' WHERE ' & arrayToList(whereClauses, ' AND ');
  var offset = (page-1) * pageSize;
</cfscript>

<!-- total count -->
<cfquery name="qCount" datasource="MyMSSQLDSN">
  SELECT COUNT(DISTINCT r.id) AS totalCount
  FROM records r
  JOIN record_specialties rs ON rs.record_id = r.id
  JOIN specialties s ON s.id = rs.specialty_id
  #whereSql#
</cfquery>

<!-- page rows -->
<cfquery name="qPage" datasource="MyMSSQLDSN">
  SELECT r.id, r.name, r.city, r.state, s.name AS specialty
  FROM records r
  JOIN record_specialties rs ON rs.record_id = r.id
  JOIN specialties s ON s.id = rs.specialty_id
  #whereSql#
  GROUP BY r.id, r.name, r.city, r.state, s.name
  ORDER BY r.id
  OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer"> ROWS
  FETCH NEXT <cfqueryparam value="#pageSize#" cfsqltype="cf_sql_integer"> ROWS ONLY
</cfquery>

<cfscript>
  var rows = [];
  for (var i=1; i LTE qPage.recordCount; i++){
    arrayAppend(rows, { id: qPage.id[i], name: qPage.name[i], city: qPage.city[i], state: qPage.state[i], specialty: qPage.specialty[i] });
  }
  writeOutput( serializeJSON( { totalCount: qCount.totalCount, page: page, pageSize: pageSize, records: rows } ) );
</cfscript>
