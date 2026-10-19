-- MSSQL schema and sample data for Export Wizard
-- Run this script in your test database. Adjust types and names as needed.

IF OBJECT_ID('dbo.record_specialties') IS NOT NULL DROP TABLE dbo.record_specialties;
IF OBJECT_ID('dbo.specialties') IS NOT NULL DROP TABLE dbo.specialties;
IF OBJECT_ID('dbo.records') IS NOT NULL DROP TABLE dbo.records;
IF OBJECT_ID('dbo.zip_codes') IS NOT NULL DROP TABLE dbo.zip_codes;
IF OBJECT_ID('dbo.export_jobs') IS NOT NULL DROP TABLE dbo.export_jobs;

CREATE TABLE specialties (
  id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(200) NOT NULL
);

CREATE TABLE records (
  id INT IDENTITY(1,1) PRIMARY KEY,
  name NVARCHAR(200) NOT NULL,
  city NVARCHAR(100),
  state NVARCHAR(50),
  zip NVARCHAR(20),
  contact_method NVARCHAR(20),
  created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE record_specialties (
  record_id INT NOT NULL FOREIGN KEY REFERENCES records(id),
  specialty_id INT NOT NULL FOREIGN KEY REFERENCES specialties(id)
);

CREATE TABLE zip_codes (
  zip NVARCHAR(20) PRIMARY KEY,
  lat FLOAT,
  lon FLOAT
);

CREATE TABLE export_jobs (
  id INT IDENTITY(1,1) PRIMARY KEY,
  job_id NVARCHAR(100) UNIQUE,
  status NVARCHAR(50),
  filters_json NVARCHAR(MAX),
  message NVARCHAR(1000),
  download_path NVARCHAR(4000),
  created_at DATETIME,
  completed_at DATETIME
);

-- seed specialties
INSERT INTO specialties (name) VALUES ('Cardiology'),('Radiology'),('Pediatrics'),('Oncology');

-- seed zip_codes (a few example zips with approximate lat/lon)
INSERT INTO zip_codes (zip, lat, lon) VALUES
('02115', 42.3415, -71.0912),
('02116', 42.3498, -71.0713),
('10001', 40.7506, -73.9972),
('94105', 37.7898, -122.3942);

-- seed records
INSERT INTO records (name, city, state, zip, contact_method) VALUES
('Alpha Clinic','Boston','MA','02115','EMAIL'),
('Beta Health','Boston','MA','02116','FAX'),
('Gamma Center','New York','NY','10001','EMAIL'),
('Delta Medical','San Francisco','CA','94105','EMAIL');

-- map specialties
INSERT INTO record_specialties (record_id, specialty_id) VALUES
(1,1),(1,2),(2,2),(3,3),(4,4);
