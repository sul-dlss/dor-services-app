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

--
-- Name: background_job_result_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.background_job_result_status AS ENUM (
    'pending',
    'processing',
    'complete'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_policies (
    id bigint NOT NULL,
    external_identifier character varying NOT NULL,
    cocina_version character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock integer
);


--
-- Name: admin_policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_policies_id_seq OWNED BY public.admin_policies.id;


--
-- Name: administrative_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.administrative_tags (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tag_label_id bigint NOT NULL
);


--
-- Name: administrative_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.administrative_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrative_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.administrative_tags_id_seq OWNED BY public.administrative_tags.id;


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
-- Name: background_job_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.background_job_results (
    id bigint NOT NULL,
    output json DEFAULT '{}'::json,
    status public.background_job_result_status DEFAULT 'pending'::public.background_job_result_status,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: background_job_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.background_job_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: background_job_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.background_job_results_id_seq OWNED BY public.background_job_results.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id bigint NOT NULL,
    external_identifier character varying NOT NULL,
    cocina_version character varying NOT NULL,
    collection_type character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    access jsonb NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb NOT NULL,
    identification jsonb NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock integer
);


--
-- Name: collections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collections_id_seq OWNED BY public.collections.id;


--
-- Name: dros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dros (
    id bigint NOT NULL,
    external_identifier character varying NOT NULL,
    cocina_version character varying NOT NULL,
    content_type character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    access jsonb NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb NOT NULL,
    identification jsonb NOT NULL,
    structural jsonb NOT NULL,
    geographic jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock integer
);


--
-- Name: dros_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dros_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dros_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dros_id_seq OWNED BY public.dros.id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    event_type character varying NOT NULL,
    druid character varying NOT NULL,
    data jsonb,
    created_at timestamp without time zone
);


--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: object_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.object_versions (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    version integer NOT NULL,
    tag character varying NOT NULL,
    description character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: object_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.object_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: object_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.object_versions_id_seq OWNED BY public.object_versions.id;


--
-- Name: orcid_works; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.orcid_works (
    id bigint NOT NULL,
    orcidid character varying NOT NULL,
    put_code character varying NOT NULL,
    druid character varying NOT NULL,
    md5 character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: orcid_works_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.orcid_works_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: orcid_works_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.orcid_works_id_seq OWNED BY public.orcid_works.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tag_labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tag_labels (
    id bigint NOT NULL,
    tag character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tag_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tag_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tag_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tag_labels_id_seq OWNED BY public.tag_labels.id;


--
-- Name: admin_policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_policies ALTER COLUMN id SET DEFAULT nextval('public.admin_policies_id_seq'::regclass);


--
-- Name: administrative_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags ALTER COLUMN id SET DEFAULT nextval('public.administrative_tags_id_seq'::regclass);


--
-- Name: background_job_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.background_job_results ALTER COLUMN id SET DEFAULT nextval('public.background_job_results_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: dros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dros ALTER COLUMN id SET DEFAULT nextval('public.dros_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: object_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.object_versions ALTER COLUMN id SET DEFAULT nextval('public.object_versions_id_seq'::regclass);


--
-- Name: orcid_works id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcid_works ALTER COLUMN id SET DEFAULT nextval('public.orcid_works_id_seq'::regclass);


--
-- Name: tag_labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_labels ALTER COLUMN id SET DEFAULT nextval('public.tag_labels_id_seq'::regclass);


--
-- Name: admin_policies admin_policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_policies
    ADD CONSTRAINT admin_policies_pkey PRIMARY KEY (id);


--
-- Name: administrative_tags administrative_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags
    ADD CONSTRAINT administrative_tags_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: background_job_results background_job_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.background_job_results
    ADD CONSTRAINT background_job_results_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: dros dros_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dros
    ADD CONSTRAINT dros_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: object_versions object_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.object_versions
    ADD CONSTRAINT object_versions_pkey PRIMARY KEY (id);


--
-- Name: orcid_works orcid_works_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcid_works
    ADD CONSTRAINT orcid_works_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tag_labels tag_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_labels
    ADD CONSTRAINT tag_labels_pkey PRIMARY KEY (id);


--
-- Name: collection_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX collection_source_id_idx ON public.collections USING btree (((identification ->> 'sourceId'::text)));


--
-- Name: dro_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dro_source_id_idx ON public.dros USING btree (((identification ->> 'sourceId'::text)));


--
-- Name: index_admin_policies_on_external_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_policies_on_external_identifier ON public.admin_policies USING btree (external_identifier);


--
-- Name: index_administrative_tags_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrative_tags_on_druid ON public.administrative_tags USING btree (druid);


--
-- Name: index_administrative_tags_on_druid_and_tag_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_administrative_tags_on_druid_and_tag_label_id ON public.administrative_tags USING btree (druid, tag_label_id);


--
-- Name: index_administrative_tags_on_tag_label_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrative_tags_on_tag_label_id ON public.administrative_tags USING btree (tag_label_id);


--
-- Name: index_collections_on_external_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_external_identifier ON public.collections USING btree (external_identifier);


--
-- Name: index_dros_on_external_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dros_on_external_identifier ON public.dros USING btree (external_identifier);


--
-- Name: index_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_created_at ON public.events USING btree (created_at);


--
-- Name: index_events_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_druid ON public.events USING btree (druid);


--
-- Name: index_events_on_event_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_events_on_event_type ON public.events USING btree (event_type);


--
-- Name: index_object_versions_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_object_versions_on_druid ON public.object_versions USING btree (druid);


--
-- Name: index_object_versions_on_druid_and_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_object_versions_on_druid_and_version ON public.object_versions USING btree (druid, version);


--
-- Name: index_orcid_works_on_orcidid_and_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orcid_works_on_orcidid_and_druid ON public.orcid_works USING btree (orcidid, druid);


--
-- Name: index_tag_labels_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_labels_on_tag ON public.tag_labels USING btree (tag);


--
-- Name: administrative_tags fk_rails_98c2c99c80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags
    ADD CONSTRAINT fk_rails_98c2c99c80 FOREIGN KEY (tag_label_id) REFERENCES public.tag_labels(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20190917215521'),
('20191015193638'),
('20191209192646'),
('20200226171829'),
('20200507202909'),
('20200507202950'),
('20200507224637'),
('20200521153735'),
('20220131194025'),
('20220131194359'),
('20220131194912'),
('20220203155057'),
('20220307201030'),
('20220307201420'),
('20220311015318'),
('20220329134023'),
('20220422143440'),
('20220509120943'),
('20230716202954');


