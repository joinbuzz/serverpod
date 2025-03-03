--
-- Class AuthKey as table serverpod_auth_key
--

CREATE TABLE serverpod_auth_key (
  "id" serial,
  "userId" integer NOT NULL,
  "hash" text NOT NULL,
  "scopeNames" json NOT NULL,
  "method" text NOT NULL
);

ALTER TABLE ONLY serverpod_auth_key
  ADD CONSTRAINT serverpod_auth_key_pkey PRIMARY KEY (id);

CREATE INDEX serverpod_auth_key_userId_idx ON serverpod_auth_key USING btree ("userId");


--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--

CREATE TABLE serverpod_cloud_storage (
  "id" serial,
  "storageId" text NOT NULL,
  "path" text NOT NULL,
  "addedTime" timestamp without time zone NOT NULL,
  "expiration" timestamp without time zone,
  "byteData" bytea NOT NULL,
  "verified" boolean NOT NULL
);

ALTER TABLE ONLY serverpod_cloud_storage
  ADD CONSTRAINT serverpod_cloud_storage_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX serverpod_cloud_storage_path_idx ON serverpod_cloud_storage USING btree ("storageId", "path");
CREATE INDEX serverpod_cloud_storage_expiration ON serverpod_cloud_storage USING btree ("expiration");


--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--

CREATE TABLE serverpod_cloud_storage_direct_upload (
  "id" serial,
  "storageId" text NOT NULL,
  "path" text NOT NULL,
  "expiration" timestamp without time zone NOT NULL,
  "authKey" text NOT NULL
);

ALTER TABLE ONLY serverpod_cloud_storage_direct_upload
  ADD CONSTRAINT serverpod_cloud_storage_direct_upload_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX serverpod_cloud_storage_direct_upload_storage_path ON serverpod_cloud_storage_direct_upload USING btree ("storageId", "path");


--
-- Class FutureCallEntry as table serverpod_future_call
--

CREATE TABLE serverpod_future_call (
  "id" serial,
  "name" text NOT NULL,
  "time" timestamp without time zone NOT NULL,
  "serializedObject" text,
  "serverId" integer NOT NULL
);

ALTER TABLE ONLY serverpod_future_call
  ADD CONSTRAINT serverpod_future_call_pkey PRIMARY KEY (id);

CREATE INDEX serverpod_future_call_time_idx ON serverpod_future_call USING btree ("time");
CREATE INDEX serverpod_future_call_serverId_idx ON serverpod_future_call USING btree ("serverId");


--
-- Class LogEntry as table serverpod_log
--

CREATE TABLE serverpod_log (
  "id" serial,
  "sessionLogId" integer NOT NULL,
  "reference" text,
  "serverId" integer NOT NULL,
  "time" timestamp without time zone NOT NULL,
  "logLevel" integer NOT NULL,
  "message" text NOT NULL,
  "error" text,
  "stackTrace" text
);

ALTER TABLE ONLY serverpod_log
  ADD CONSTRAINT serverpod_log_pkey PRIMARY KEY (id);

CREATE INDEX serverpod_log_sessionLogId_idx ON serverpod_log USING btree ("sessionLogId");


--
-- Class MethodInfo as table serverpod_method
--

CREATE TABLE serverpod_method (
  "id" serial,
  "endpoint" text NOT NULL,
  "method" text NOT NULL
);

ALTER TABLE ONLY serverpod_method
  ADD CONSTRAINT serverpod_method_pkey PRIMARY KEY (id);

CREATE UNIQUE INDEX serverpod_method_endpoint_method_idx ON serverpod_method USING btree ("endpoint", "method");


--
-- Class QueryLogEntry as table serverpod_query_log
--

CREATE TABLE serverpod_query_log (
  "id" serial,
  "serverId" integer NOT NULL,
  "sessionLogId" integer NOT NULL,
  "query" text NOT NULL,
  "duration" double precision NOT NULL,
  "numRows" integer,
  "error" text,
  "stackTrace" text
);

ALTER TABLE ONLY serverpod_query_log
  ADD CONSTRAINT serverpod_query_log_pkey PRIMARY KEY (id);

CREATE INDEX serverpod_query_log_sessionLogId_idx ON serverpod_query_log USING btree ("sessionLogId");


--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--

CREATE TABLE serverpod_readwrite_test (
  "id" serial,
  "number" integer NOT NULL
);

ALTER TABLE ONLY serverpod_readwrite_test
  ADD CONSTRAINT serverpod_readwrite_test_pkey PRIMARY KEY (id);


--
-- Class RuntimeSettings as table serverpod_runtime_settings
--

CREATE TABLE serverpod_runtime_settings (
  "id" serial,
  "logSettings" json NOT NULL,
  "logSettingsOverrides" json NOT NULL,
  "logServiceCalls" boolean NOT NULL,
  "logMalformedCalls" boolean NOT NULL
);

ALTER TABLE ONLY serverpod_runtime_settings
  ADD CONSTRAINT serverpod_runtime_settings_pkey PRIMARY KEY (id);


--
-- Class SessionLogEntry as table serverpod_session_log
--

CREATE TABLE serverpod_session_log (
  "id" serial,
  "serverId" integer NOT NULL,
  "time" timestamp without time zone NOT NULL,
  "module" text,
  "endpoint" text,
  "method" text,
  "duration" double precision,
  "numQueries" integer,
  "slow" boolean,
  "error" text,
  "stackTrace" text,
  "authenticatedUserId" integer
);

ALTER TABLE ONLY serverpod_session_log
  ADD CONSTRAINT serverpod_session_log_pkey PRIMARY KEY (id);


