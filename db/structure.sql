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


--
-- Name: admin_policies_after_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_policies_after_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO admin_policy_versions(admin_policy_id, druid, label, version, administrative, description, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.label, NEW.version), NULLIF(OLD.version, NEW.version), NUllIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), OLD.created_at, OLD.updated_at);
    RETURN NULL;
END;
$$;


--
-- Name: collections_after_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.collections_after_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO collection_versions(collection_id, druid, content_type, label, version, access, administrative, description, identification, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), OLD.created_at, OLD.updated_at);
    RETURN NULL;
END;
$$;


--
-- Name: dros_after_update_row_tr(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dros_after_update_row_tr() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO dro_versions(dro_id, druid, content_type, label, version, access, administrative, description, identification, structural, geographic, created_at, updated_at) VALUES (OLD.id, OLD.druid, NULLIF(OLD.content_type, NEW.content_type), NULLIF(OLD.label, NEW.label), NULLIF(OLD.version, NEW.version), NULLIF(OLD.access, NEW.access), NULLIF(OLD.administrative, NEW.administrative), NULLIF(OLD.description, NEW.description), NULLIF(OLD.identification, NEW.identification), NULLIF(OLD.structural, NEW.structural), NULLIF(OLD.geographic, NEW.geographic), OLD.created_at, OLD.updated_at);
    RETURN NULL;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_policies (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: admin_policy_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_policy_versions (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    admin_policy_id bigint NOT NULL
);


--
-- Name: admin_policy_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_policy_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_policy_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_policy_versions_id_seq OWNED BY public.admin_policy_versions.id;


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
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: collection_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_versions (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    content_type character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    access jsonb NOT NULL,
    administrative jsonb,
    description jsonb,
    identification jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    collection_id bigint NOT NULL
);


--
-- Name: collection_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.collection_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: collection_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.collection_versions_id_seq OWNED BY public.collection_versions.id;


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    content_type character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    access jsonb NOT NULL,
    administrative jsonb,
    description jsonb,
    identification jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: dro_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dro_versions (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    content_type character varying,
    label character varying,
    version integer,
    access jsonb,
    administrative jsonb,
    description jsonb,
    identification jsonb,
    structural jsonb,
    geographic jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dro_id bigint NOT NULL
);


--
-- Name: dro_versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dro_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dro_versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dro_versions_id_seq OWNED BY public.dro_versions.id;


--
-- Name: dros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dros (
    id bigint NOT NULL,
    druid character varying NOT NULL,
    content_type character varying NOT NULL,
    label character varying NOT NULL,
    version integer NOT NULL,
    access jsonb NOT NULL,
    administrative jsonb NOT NULL,
    description jsonb,
    identification jsonb,
    structural jsonb,
    geographic jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: admin_policy_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_policy_versions ALTER COLUMN id SET DEFAULT nextval('public.admin_policy_versions_id_seq'::regclass);


--
-- Name: administrative_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags ALTER COLUMN id SET DEFAULT nextval('public.administrative_tags_id_seq'::regclass);


--
-- Name: background_job_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.background_job_results ALTER COLUMN id SET DEFAULT nextval('public.background_job_results_id_seq'::regclass);


--
-- Name: collection_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_versions ALTER COLUMN id SET DEFAULT nextval('public.collection_versions_id_seq'::regclass);


--
-- Name: collections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections ALTER COLUMN id SET DEFAULT nextval('public.collections_id_seq'::regclass);


--
-- Name: dro_versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dro_versions ALTER COLUMN id SET DEFAULT nextval('public.dro_versions_id_seq'::regclass);


--
-- Name: dros id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dros ALTER COLUMN id SET DEFAULT nextval('public.dros_id_seq'::regclass);


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


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
-- Name: admin_policy_versions admin_policy_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_policy_versions
    ADD CONSTRAINT admin_policy_versions_pkey PRIMARY KEY (id);


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
-- Name: collection_versions collection_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_versions
    ADD CONSTRAINT collection_versions_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: dro_versions dro_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dro_versions
    ADD CONSTRAINT dro_versions_pkey PRIMARY KEY (id);


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
-- Name: index_admin_policies_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admin_policies_on_druid ON public.admin_policies USING btree (druid);


--
-- Name: index_admin_policy_versions_on_admin_policy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_policy_versions_on_admin_policy_id ON public.admin_policy_versions USING btree (admin_policy_id);


--
-- Name: index_admin_policy_versions_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_policy_versions_on_druid ON public.admin_policy_versions USING btree (druid);


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
-- Name: index_collection_versions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_versions_on_collection_id ON public.collection_versions USING btree (collection_id);


--
-- Name: index_collection_versions_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_versions_on_druid ON public.collection_versions USING btree (druid);


--
-- Name: index_collections_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_druid ON public.collections USING btree (druid);


--
-- Name: index_dro_versions_on_dro_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dro_versions_on_dro_id ON public.dro_versions USING btree (dro_id);


--
-- Name: index_dro_versions_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_dro_versions_on_druid ON public.dro_versions USING btree (druid);


--
-- Name: index_dros_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_dros_on_druid ON public.dros USING btree (druid);


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
-- Name: index_tag_labels_on_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tag_labels_on_tag ON public.tag_labels USING btree (tag);


--
-- Name: admin_policies admin_policies_after_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER admin_policies_after_update_row_tr AFTER UPDATE ON public.admin_policies FOR EACH ROW EXECUTE FUNCTION public.admin_policies_after_update_row_tr();


--
-- Name: collections collections_after_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER collections_after_update_row_tr AFTER UPDATE ON public.collections FOR EACH ROW EXECUTE FUNCTION public.collections_after_update_row_tr();


--
-- Name: dros dros_after_update_row_tr; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER dros_after_update_row_tr AFTER UPDATE ON public.dros FOR EACH ROW EXECUTE FUNCTION public.dros_after_update_row_tr();


--
-- Name: admin_policy_versions fk_rails_20346f2b09; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_policy_versions
    ADD CONSTRAINT fk_rails_20346f2b09 FOREIGN KEY (admin_policy_id) REFERENCES public.admin_policies(id) ON DELETE CASCADE;


--
-- Name: dro_versions fk_rails_73ab876cf7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dro_versions
    ADD CONSTRAINT fk_rails_73ab876cf7 FOREIGN KEY (dro_id) REFERENCES public.dros(id) ON DELETE CASCADE;


--
-- Name: administrative_tags fk_rails_98c2c99c80; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_tags
    ADD CONSTRAINT fk_rails_98c2c99c80 FOREIGN KEY (tag_label_id) REFERENCES public.tag_labels(id);


--
-- Name: collection_versions fk_rails_e110e4f591; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_versions
    ADD CONSTRAINT fk_rails_e110e4f591 FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


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
('20210303185746'),
('20210304182648'),
('20210304182918'),
('20210503035746'),
('20210503182648'),
('20210503182918'),
('20210505113243');


