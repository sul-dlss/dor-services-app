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
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: background_job_result_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.background_job_result_status AS ENUM (
    'pending',
    'processing',
    'complete'
);


--
-- Name: repository_object_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.repository_object_type AS ENUM (
    'dro',
    'admin_policy',
    'collection'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Name: release_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.release_tags (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    who character varying NOT NULL,
    what character varying NOT NULL,
    released_to character varying NOT NULL,
    release boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: release_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.release_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: release_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.release_tags_id_seq OWNED BY public.release_tags.id;


--
-- Name: repository_object_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_object_versions (
    id bigint NOT NULL,
    repository_object_id bigint NOT NULL,
    version integer NOT NULL,
    version_description character varying NOT NULL,
    cocina_version character varying,
    content_type character varying,
    label character varying,
    access jsonb,
    administrative jsonb,
    description jsonb,
    identification jsonb,
    structural jsonb,
    geographic jsonb,
    closed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    lock integer
);


--
-- Name: repository_object_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_object_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_object_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_object_versions_id_seq OWNED BY public.repository_object_versions.id;


--
-- Name: repository_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.repository_objects (
    id bigint NOT NULL,
    object_type public.repository_object_type NOT NULL,
    external_identifier character varying NOT NULL,
    source_id character varying,
    lock integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    head_version_id bigint,
    last_closed_version_id bigint,
    opened_version_id bigint
);


--
-- Name: repository_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.repository_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: repository_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.repository_objects_id_seq OWNED BY public.repository_objects.id;


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
-- Name: user_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_versions (
    id bigint NOT NULL,
    version integer NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    repository_object_version_id bigint NOT NULL,
    state character varying DEFAULT 'available'::character varying NOT NULL
);


--
-- Name: user_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_versions_id_seq OWNED BY public.user_versions.id;


--
-- Name: administrative_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags ALTER COLUMN id SET DEFAULT nextval('public.administrative_tags_id_seq'::regclass);


--
-- Name: background_job_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.background_job_results ALTER COLUMN id SET DEFAULT nextval('public.background_job_results_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: orcid_works id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcid_works ALTER COLUMN id SET DEFAULT nextval('public.orcid_works_id_seq'::regclass);


--
-- Name: release_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.release_tags ALTER COLUMN id SET DEFAULT nextval('public.release_tags_id_seq'::regclass);


--
-- Name: repository_object_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_object_versions ALTER COLUMN id SET DEFAULT nextval('public.repository_object_versions_id_seq'::regclass);


--
-- Name: repository_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_objects ALTER COLUMN id SET DEFAULT nextval('public.repository_objects_id_seq'::regclass);


--
-- Name: tag_labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_labels ALTER COLUMN id SET DEFAULT nextval('public.tag_labels_id_seq'::regclass);


--
-- Name: user_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_versions ALTER COLUMN id SET DEFAULT nextval('public.user_versions_id_seq'::regclass);


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
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: orcid_works orcid_works_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.orcid_works
    ADD CONSTRAINT orcid_works_pkey PRIMARY KEY (id);


--
-- Name: release_tags release_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.release_tags
    ADD CONSTRAINT release_tags_pkey PRIMARY KEY (id);


--
-- Name: repository_object_versions repository_object_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_object_versions
    ADD CONSTRAINT repository_object_versions_pkey PRIMARY KEY (id);


--
-- Name: repository_objects repository_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_objects
    ADD CONSTRAINT repository_objects_pkey PRIMARY KEY (id);


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
-- Name: user_versions user_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_versions
    ADD CONSTRAINT user_versions_pkey PRIMARY KEY (id);


--
-- Name: idx_on_repository_object_id_version_fbf04ede4e; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_repository_object_id_version_fbf04ede4e ON public.repository_object_versions USING btree (repository_object_id, version);


--
-- Name: idx_on_structural_hasMemberOrders_0_members_c0444cb569; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "idx_on_structural_hasMemberOrders_0_members_c0444cb569" ON public.repository_object_versions USING gin ((((structural #> '{hasMemberOrders,0}'::text[]) -> 'members'::text)));


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
-- Name: index_orcid_works_on_orcidid_and_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_orcid_works_on_orcidid_and_druid ON public.orcid_works USING btree (orcidid, druid);


--
-- Name: index_release_tags_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_tags_on_druid ON public.release_tags USING btree (druid);


--
-- Name: index_repository_object_versions_on_repository_object_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_object_versions_on_repository_object_id ON public.repository_object_versions USING btree (repository_object_id);


--
-- Name: index_repository_object_versions_on_structural_isMemberOf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_repository_object_versions_on_structural_isMemberOf" ON public.repository_object_versions USING gin (((structural -> 'isMemberOf'::text)));


--
-- Name: index_repository_objects_on_external_identifier; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repository_objects_on_external_identifier ON public.repository_objects USING btree (external_identifier);


--
-- Name: index_repository_objects_on_head_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_objects_on_head_version_id ON public.repository_objects USING btree (head_version_id);


--
-- Name: index_repository_objects_on_last_closed_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_objects_on_last_closed_version_id ON public.repository_objects USING btree (last_closed_version_id);


--
-- Name: index_repository_objects_on_object_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_objects_on_object_type ON public.repository_objects USING btree (object_type);


--
-- Name: index_repository_objects_on_opened_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_repository_objects_on_opened_version_id ON public.repository_objects USING btree (opened_version_id);


--
-- Name: index_repository_objects_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_repository_objects_on_source_id ON public.repository_objects USING btree (source_id);


--
-- Name: index_tag_labels_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_labels_on_tag ON public.tag_labels USING btree (tag);


--
-- Name: index_user_versions_on_repository_object_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_versions_on_repository_object_version_id ON public.user_versions USING btree (repository_object_version_id);


--
-- Name: index_user_versions_on_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_versions_on_version ON public.user_versions USING btree (version);


--
-- Name: repository_objects fk_rails_1dc8d215fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_objects
    ADD CONSTRAINT fk_rails_1dc8d215fb FOREIGN KEY (last_closed_version_id) REFERENCES public.repository_object_versions(id);


--
-- Name: repository_objects fk_rails_3c4ec20ee5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_objects
    ADD CONSTRAINT fk_rails_3c4ec20ee5 FOREIGN KEY (opened_version_id) REFERENCES public.repository_object_versions(id);


--
-- Name: user_versions fk_rails_5e794ed7b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_versions
    ADD CONSTRAINT fk_rails_5e794ed7b9 FOREIGN KEY (repository_object_version_id) REFERENCES public.repository_object_versions(id);


--
-- Name: repository_object_versions fk_rails_702591eb00; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_object_versions
    ADD CONSTRAINT fk_rails_702591eb00 FOREIGN KEY (repository_object_id) REFERENCES public.repository_objects(id);


--
-- Name: administrative_tags fk_rails_98c2c99c80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags
    ADD CONSTRAINT fk_rails_98c2c99c80 FOREIGN KEY (tag_label_id) REFERENCES public.tag_labels(id);


--
-- Name: repository_objects fk_rails_aee9cbf562; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.repository_objects
    ADD CONSTRAINT fk_rails_aee9cbf562 FOREIGN KEY (head_version_id) REFERENCES public.repository_object_versions(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20240807210223'),
('20240531122304'),
('20240522142556'),
('20240430144139'),
('20240429201956'),
('20240408230311'),
('20240408184127'),
('20240402155058'),
('20240328144814'),
('20240328142859'),
('20240328142339'),
('20240328141842'),
('20240322161526'),
('20240320203110'),
('20240108161425'),
('20240104210953'),
('20230716202954'),
('20220509120943'),
('20220422143440'),
('20220329134023'),
('20220311015318'),
('20220307201420'),
('20220307201030'),
('20220203155057'),
('20220131194912'),
('20220131194359'),
('20220131194025'),
('20200521153735'),
('20200507224637'),
('20200507202950'),
('20200507202909'),
('20200226171829'),
('20191209192646'),
('20191015193638'),
('20190917215521');

