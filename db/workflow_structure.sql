SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: version_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.version_contexts (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    "values" jsonb DEFAULT '{}'::jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: version_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.version_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: version_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.version_contexts_id_seq OWNED BY public.version_contexts.id;


--
-- Name: workflow_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workflow_steps (
    id integer NOT NULL,
    druid character varying NOT NULL,
    workflow character varying NOT NULL,
    process character varying NOT NULL,
    status character varying,
    error_msg text,
    error_txt bytea,
    attempts integer DEFAULT 0 NOT NULL,
    lifecycle character varying,
    elapsed numeric(9,3),
    version integer,
    note text,
    lane_id character varying DEFAULT 'default'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    active_version boolean DEFAULT false,
    completed_at timestamp without time zone
);


--
-- Name: workflow_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.workflow_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workflow_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.workflow_steps_id_seq OWNED BY public.workflow_steps.id;


--
-- Name: version_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_contexts ALTER COLUMN id SET DEFAULT nextval('public.version_contexts_id_seq'::regclass);


--
-- Name: workflow_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_steps ALTER COLUMN id SET DEFAULT nextval('public.workflow_steps_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: version_contexts version_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.version_contexts
    ADD CONSTRAINT version_contexts_pkey PRIMARY KEY (id);


--
-- Name: workflow_steps workflow_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workflow_steps
    ADD CONSTRAINT workflow_steps_pkey PRIMARY KEY (id);


--
-- Name: active_version_step_name_workflow2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX active_version_step_name_workflow2_idx ON public.workflow_steps USING btree (active_version, status, workflow, process);


--
-- Name: index_version_contexts_on_druid_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_version_contexts_on_druid_and_version ON public.version_contexts USING btree (druid, version);


--
-- Name: index_workflow_steps_on_active_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_steps_on_active_version ON public.workflow_steps USING btree (active_version);


--
-- Name: index_workflow_steps_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_steps_on_druid ON public.workflow_steps USING btree (druid);


--
-- Name: index_workflow_steps_on_druid_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_workflow_steps_on_druid_and_version ON public.workflow_steps USING btree (druid, version);


--
-- Name: step_name_with_druid_workflow2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX step_name_with_druid_workflow2_idx ON public.workflow_steps USING btree (status, workflow, process, druid);


--
-- Name: step_name_workflow2_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX step_name_workflow2_idx ON public.workflow_steps USING btree (status, workflow, process);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240402194159'),
('20200811212454'),
('20191114185747'),
('20191113200233'),
('20190517154458'),
('20190320163535'),
('20190319184514'),
('20190319162734'),
('20190211160654'),
('20190125161810'),
('20190110221945'),
('20190110213421'),
('20190110154157'),
('20151112054510');

