<!-- preview.cfm
  Accepts POST JSON filters and returns specialties counts & sample rows.
  ColdFusion (CF2021) + MSSQL - adjust datasource name MyMSSQLDSN as needed.
-->
<cfsetting enablecfoutputonly="yes">
<cfscript>
  // Read JSON body
  var req = GetHttpRequestData();
  var raw = req.content;
  if (len(trim(raw)) eq 0) raw = '{}';
  var filters = deserializeJSON(raw);

  // Helper builds literal clauses with embedded cfqueryparam tags
  function buildWhere(filters){
    var clauses = [];
    // contact methods
    if (structKeyExists(filters, 'contactMethods') && arrayLen(filters.contactMethods)){
      var lst = [];
      for (m in filters.contactMethods){
        arrayAppend(lst, "<cfqueryparam value='" & m & "' cfsqltype='cf_sql_varchar'>");
      }
      arrayAppend(clauses, "r.contact_method IN (" & arrayToList(lst, ',') & ")");
    }
    // zip list (if precomputed and provided)
    if (structKeyExists(filters, 'zipList') && arrayLen(filters.zipList)){
      var zips = [];
      for (z in filters.zipList){
        arrayAppend(zips, "<cfqueryparam value='" & z & "' cfsqltype='cf_sql_varchar'>");
      }
      arrayAppend(clauses, "r.zip IN (" & arrayToList(zips, ',') & ")");
    }
    return clauses;
  }

  var whereClauses = buildWhere(filters);
  var whereSql = '';
  if (arrayLen(whereClauses)){
    whereSql = ' WHERE ' & arrayToList(whereClauses, ' AND ');
  }
</cfscript>

<!-- Specialty counts -->
<cfquery name="qSpecialtyCounts" datasource="MyMSSQLDSN">
  SELECT s.name AS specialty, COUNT(DISTINCT r.id) AS cnt
  FROM records r
  JOIN record_specialties rs ON rs.record_id = r.id
  JOIN specialties s ON s.id = rs.specialty_id
  #whereSql#
  GROUP BY s.name
  ORDER BY cnt DESC
</cfquery>

<!-- Sample rows -->
<cfquery name="qSample" datasource="MyMSSQLDSN">
  SELECT TOP 10 r.id, r.name, r.city, r.state, s.name AS specialty
  FROM records r
  JOIN record_specialties rs ON rs.record_id = r.id
  JOIN specialties s ON s.id = rs.specialty_id
  #whereSql#
  ORDER BY r.id
</cfquery>

<cfoutput>
#serializeJSON({
  specialties: (qSpecialtyCounts.recordCount ? arrayMap(qSpecialtyCounts, function(row){ return { specialty: row.specialty, count: row.cnt } }) : []),
  sampleRows: (qSample.recordCount ? arrayMap(qSample, function(row){ return { id: row.id, name: row.name, city: row.city, state: row.state, specialty: row.specialty } }) : [])
})#
</cfoutput>
