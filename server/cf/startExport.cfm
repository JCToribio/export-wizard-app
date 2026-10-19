<!-- startExport.cfm
   Starts export. If small (<=1000 rows) returns sync download URL, otherwise creates an export_jobs row and starts CFTHREAD to write CSV.
-->
<cfsetting enablecfoutputonly="yes">
<cfscript>
  var req = GetHttpRequestData();
  var raw = req.content;
  if (len(trim(raw)) eq 0) raw = '{}';
  var body = deserializeJSON(raw);
  var filters = structKeyExists(body,'filters') ? body.filters : {};
  var selectedIds = structKeyExists(body,'selectedRecordIds') ? body.selectedRecordIds : [];

  // Helper to compute a COUNT for these filters
  function countMatching(filters, selectedIds){
    if (arrayLen(selectedIds)){
      // count provided IDs
      var idList = [];
      for (id in selectedIds){ arrayAppend(idList, "<cfqueryparam value='" & id & "' cfsqltype='cf_sql_integer'>") }
      var idSql = " WHERE r.id IN (" & arrayToList(idList, ',') & ")";
      var q = queryExecute("SELECT COUNT(1) AS cnt FROM records r " & idSql, {}, {datasource:'MyMSSQLDSN'});
      return q.cnt[1];
    }
    // Otherwise count by filters (simple version: reuse preview count approach)
    var clauses = [];
    if (structKeyExists(filters, 'contactMethods') && arrayLen(filters.contactMethods)){
      var lst = [];
      for (m in filters.contactMethods){ arrayAppend(lst, "<cfqueryparam value='" & m & "' cfsqltype='cf_sql_varchar'>") }
      arrayAppend(clauses, "r.contact_method IN (" & arrayToList(lst, ',') & ")")
    }
    var whereSql = '';
    if (arrayLen(clauses)) whereSql = ' WHERE ' & arrayToList(clauses, ' AND ');
    var q = queryExecute("SELECT COUNT(DISTINCT r.id) AS cnt FROM records r JOIN record_specialties rs ON rs.record_id = r.id JOIN specialties s ON s.id = rs.specialty_id " & whereSql, {}, {datasource:'MyMSSQLDSN'});
    return q.cnt[1];
  }

  var total = countMatching(filters, selectedIds);
  var threshold = 1000; // rows <= threshold are streamed sync
  if (total <= threshold){
    // generate CSV synchronously and return URL
    var timestamp = dateFormat(now(),'yyyy-mm-dd') & '_' & TimeFormat(now(),'HHmmss');
    var fileName = 'export_' & timestamp & '.csv';
    var filePath = expandPath('./exports/') & fileName;

    // Ensure exports folder exists
    directoryExists( expandPath('./exports/') ) or directoryCreate( expandPath('./exports/') );

    // fetch rows (simple version: if selectedIds provided use them else get first N)
    if (arrayLen(selectedIds)){
      var idList = [];
      for (id in selectedIds){ arrayAppend(idList, "<cfqueryparam value='" & id & "' cfsqltype='cf_sql_integer'>") }
      var qRows = queryExecute("SELECT r.id, r.name, r.city, r.state FROM records r WHERE r.id IN (" & arrayToList(idList, ',') & ") ORDER BY r.id", {}, {datasource:'MyMSSQLDSN'});
    } else {
      var qRows = queryExecute("SELECT TOP " & total & " r.id, r.name, r.city, r.state FROM records r ORDER BY r.id", {}, {datasource:'MyMSSQLDSN'});
    }

    // write CSV
    fileWrite(filePath, '"id","name","city","state"' & chr(13) & chr(10) );
    for (var i=1; i LTE qRows.recordCount; i++){
      fileAppend(filePath, '"' & qRows.id[i] & '","' & replace(qRows.name[i], '"', '""', 'all') & '","' & qRows.city[i] & '","' & qRows.state[i] & '"' & chr(13) & chr(10));
    }

    writeOutput( serializeJSON({ mode: 'sync', fileDownloadUrl: '/export-wizard/server/cf/exports/' & fileName }) );
    abort;
  }

  // Otherwise create async job
  var jobId = createUUID();
  var filtersJson = serializeJSON(filters);
  queryExecute("INSERT INTO export_jobs (job_id, status, filters_json, created_at) VALUES (?,?,?,GETDATE())", [ {value:jobId,cfsqltype:'cf_sql_varchar'}, {value:'queued',cfsqltype:'cf_sql_varchar'}, {value:filtersJson,cfsqltype:'cf_sql_clob'} ], {datasource:'MyMSSQLDSN'});

  // start CFTHREAD to write CSV asynchronously
  cfthread name="export_#jobId#" action="run" runat="now">
    <cftry>
      <cfscript>
        var fileName = 'export_' & jobId & '.csv';
        var filePath = expandPath('./exports/') & fileName;
        directoryExists( expandPath('./exports/') ) or directoryCreate( expandPath('./exports/') );

        // Simple: export all matching rows (improve by chunking for huge sets)
        var qRows = queryExecute("SELECT r.id, r.name, r.city, r.state FROM records r ORDER BY r.id", {}, {datasource:'MyMSSQLDSN'});
        fileWrite(filePath, '"id","name","city","state"' & chr(13) & chr(10) );
        for (var i=1; i LTE qRows.recordCount; i++){
          fileAppend(filePath, '"' & qRows.id[i] & '","' & replace(qRows.name[i], '"', '""', 'all') & '","' & qRows.city[i] & '","' & qRows.state[i] & '"' & chr(13) & chr(10));
        }
        queryExecute("UPDATE export_jobs SET status='done', download_path=? , completed_at=GETDATE() WHERE job_id=?", [ {value:filePath,cfsqltype:'cf_sql_varchar'}, {value:jobId,cfsqltype:'cf_sql_varchar'} ], {datasource:'MyMSSQLDSN'});
      </cfscript>
      <cfcatch>
        <cfquery datasource="MyMSSQLDSN">
          UPDATE export_jobs SET status='failed', message=<cfqueryparam value="#cfcatch.message#" cfsqltype="cf_sql_varchar"> WHERE job_id = <cfqueryparam value="#jobId#" cfsqltype="cf_sql_varchar">
        </cfquery>
      </cfcatch>
    </cftry>
  </cfthread>

  writeOutput( serializeJSON({ mode: 'async', jobId: jobId }) );
</cfscript>
