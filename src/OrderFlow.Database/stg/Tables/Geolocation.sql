CREATE TABLE stg.Geolocation
(
    geolocation_zip_code_prefix nvarchar(max) NULL,
    geolocation_lat nvarchar(max) NULL,
    geolocation_lng nvarchar(max) NULL,
    geolocation_city nvarchar(max) NULL,
    geolocation_state nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_Geolocation_LoadRunId DEFAULT (0)
);