# Export Wizard App

This repository contains a scaffold for an Export Wizard application: React (Vite) frontend and ColdFusion (CF2021) backend sample endpoints targeting MS SQL.

What is included
- client/: Vite + React frontend (Bootstrap) that talks to CF endpoints.
- server/cf/: ColdFusion sample endpoints (preview.cfm, records.cfm, startExport.cfm, zip-radius.cfm).
- server/sql/: MSSQL schema + seed script to create minimal tables for testing.

Quick start (frontend only, demo against your CF server)
1. cd client
2. npm install
3. Edit client/src/api.js to point to your CF server base URL (default: http://localhost:8500)
4. npm run dev

ColdFusion notes
- Copy server/cf/*.cfm into a folder served by your CF2021 instance (for example: C:\inetpub\wwwroot\export-wizard\server\cf\)
- Ensure the MSSQL datasource name in the CF files matches your CF datasource (default used in files: MyMSSQLDSN).
- Run server/sql/create_schema.sql in your MSSQL to create test data.

Files pushed in this commit: initial scaffold
