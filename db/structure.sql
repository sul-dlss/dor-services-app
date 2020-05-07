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
-- Name: tag_labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tag_labels ALTER COLUMN id SET DEFAULT nextval('public.tag_labels_id_seq'::regclass);


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
-- Name: index_administrative_tags_on_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrative_tags_on_druid ON public.administrative_tags USING btree (druid);


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
('20200507224637');


