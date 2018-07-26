SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auditing; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auditing;


--
-- Name: SCHEMA auditing; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA auditing IS 'Out-of-table audit/history logging tables and trigger functions';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: audit_table(regclass); Type: FUNCTION; Schema: auditing; Owner: -
--

CREATE FUNCTION auditing.audit_table(target_table regclass) RETURNS void
    LANGUAGE sql
    AS $_$
  SELECT auditing.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$_$;


--
-- Name: FUNCTION audit_table(target_table regclass); Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON FUNCTION auditing.audit_table(target_table regclass) IS '
  Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
';


--
-- Name: audit_table(regclass, boolean, boolean); Type: FUNCTION; Schema: auditing; Owner: -
--

CREATE FUNCTION auditing.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean) RETURNS void
    LANGUAGE sql
    AS $_$
  SELECT auditing.audit_table($1, $2, $3, ARRAY[]::text[]);
$_$;


--
-- Name: audit_table(regclass, boolean, boolean, text[]); Type: FUNCTION; Schema: auditing; Owner: -
--

CREATE FUNCTION auditing.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
    stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
    _q_txt text;
    _pk_column_name text;
    _pk_column_snip text;
    _ignored_cols_snip text = '';
  BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || quote_ident(target_table::TEXT);
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || quote_ident(target_table::TEXT);

    IF audit_rows THEN
      _pk_column_name = auditing.get_primary_key_column(target_table::TEXT);

      IF _pk_column_name IS NOT NULL THEN
        _pk_column_snip = ', ' || quote_literal(_pk_column_name);
      ELSE
        _pk_column_snip = ', NULL';
      END IF;

      IF array_length(ignored_cols,1) > 0 THEN
        _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
      END IF;
      _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
          quote_ident(target_table::TEXT) ||
          ' FOR EACH ROW EXECUTE PROCEDURE auditing.if_modified_func(' ||
          quote_literal(audit_query_text) || _pk_column_snip || _ignored_cols_snip || ');';
      RAISE NOTICE '%',_q_txt;
      EXECUTE _q_txt;
      stm_targets = 'TRUNCATE';
    ELSE
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
        target_table ||
        ' FOR EACH STATEMENT EXECUTE PROCEDURE auditing.if_modified_func('||
        quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%',_q_txt;
    EXECUTE _q_txt;

  END;
$$;


--
-- Name: FUNCTION audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]); Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON FUNCTION auditing.audit_table(target_table regclass, audit_rows boolean, audit_query_text boolean, ignored_cols text[]) IS '
  Add auditing support to a table.

  Arguments:
      target_table:   Table name, schema qualified if not on search_path
      audit_rows:     Record each row change, or only audit at a statement level
      audit_query_text: Record the text of the client query that triggered the audit event?
      ignored_cols:   Columns to exclude from update diffs, ignore updates that change only ignored cols.
';


--
-- Name: get_primary_key_column(text); Type: FUNCTION; Schema: auditing; Owner: -
--

CREATE FUNCTION auditing.get_primary_key_column(target_table text) RETURNS text
    LANGUAGE plpgsql
    AS $$
  DECLARE
    _pk_query_text text;
    _pk_column_name text;
  BEGIN
    _pk_query_text =  'SELECT a.attname ' ||
                      'FROM   pg_index i ' ||
                      'JOIN   pg_attribute a ON a.attrelid = i.indrelid ' ||
                      '                    AND a.attnum = ANY(i.indkey) ' ||
                      'WHERE  i.indrelid = ' || quote_literal(target_table::TEXT) || '::regclass ' ||
                      'AND    i.indisprimary ' ||
                      'AND format_type(a.atttypid, a.atttypmod) = ' || quote_literal('bigint'::TEXT) ||
                      'LIMIT 1';

    EXECUTE _pk_query_text INTO _pk_column_name;
    raise notice 'Value %', _pk_column_name;
    return _pk_column_name;
  END;
$$;


--
-- Name: FUNCTION get_primary_key_column(target_table text); Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON FUNCTION auditing.get_primary_key_column(target_table text) IS '
  Get primary key column name if single PK and type bigint.

  Arguments:
      target_table:   Table name, schema qualified if not on search_path
';


--
-- Name: if_modified_func(); Type: FUNCTION; Schema: auditing; Owner: -
--

CREATE FUNCTION auditing.if_modified_func() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO pg_catalog, public
    AS $_$
  DECLARE
    audit_row auditing.logged_actions;
    include_values boolean;
    log_diffs boolean;
    h_old hstore;
    h_new hstore;
    user_row record;
    excluded_cols text[] = ARRAY[]::text[];
    pk_val_query text;
  BEGIN
    IF TG_WHEN <> 'AFTER' THEN
      RAISE EXCEPTION 'auditing.if_modified_func() may only run as an AFTER trigger';
    END IF;

    audit_row = ROW(
      nextval('auditing.logged_actions_event_id_seq'), -- event_id
      TG_TABLE_SCHEMA::text,                        -- schema_name
      TG_TABLE_NAME::text,                          -- table_name
      TG_RELID,                                     -- relation OID for much quicker searches
      session_user::text,                           -- session_user_name
      NULL, NULL, NULL,                             -- app_user_id, app_user_type, app_ip_address
      current_timestamp,                            -- action_tstamp_tx
      statement_timestamp(),                        -- action_tstamp_stm
      clock_timestamp(),                            -- action_tstamp_clk
      txid_current(),                               -- transaction ID
      current_setting('application_name'),          -- client application
      inet_client_addr(),                           -- client_addr
      inet_client_port(),                           -- client_port
      current_query(),                              -- top-level query or queries (if multistatement) from client
      substring(TG_OP,1,1),                         -- action
      NULL, NULL, NULL,                             -- row_id, row_data, changed_fields
      'f'                                           -- statement_only
    );

    IF NOT TG_ARGV[0]::boolean IS DISTINCT FROM 'f'::boolean THEN
      audit_row.client_query = NULL;
    END IF;

    IF ((TG_ARGV[1] IS NOT NULL) AND (TG_LEVEL = 'ROW')) THEN
      pk_val_query = 'SELECT $1.' || quote_ident(TG_ARGV[1]::text);

      IF (TG_OP IS DISTINCT FROM 'DELETE') THEN
        EXECUTE pk_val_query INTO audit_row.row_id USING NEW;
      END IF;

      IF audit_row.row_id IS NULL THEN
        EXECUTE pk_val_query INTO audit_row.row_id USING OLD;
      END IF;
    END IF;

    IF TG_ARGV[2] IS NOT NULL THEN
      excluded_cols = TG_ARGV[2]::text[];
    END IF;



    IF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
      audit_row.row_data = hstore(OLD.*) - excluded_cols;
      audit_row.changed_fields =  (hstore(NEW.*) - audit_row.row_data) - excluded_cols;
      IF audit_row.changed_fields = hstore('') THEN
        -- All changed fields are ignored. Skip this update.
        RETURN NULL;
      END IF;
    ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
      audit_row.row_data = hstore(OLD.*) - excluded_cols;
    ELSIF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
      audit_row.row_data = hstore(NEW.*) - excluded_cols;
    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
      audit_row.statement_only = 't';
    ELSE
      RAISE EXCEPTION '[auditing.if_modified_func] - Trigger func added as trigger for unhandled case: %, %',TG_OP, TG_LEVEL;
      RETURN NULL;
    END IF;

    -- inject app_user data into audit
    BEGIN
      PERFORM
      n.nspname, c.relname
      FROM
      pg_catalog.pg_class c
      LEFT JOIN
      pg_catalog.pg_namespace n
      ON n.oid = c.relnamespace
      WHERE
      n.nspname like 'pg_temp_%'
      AND
      c.relname = '_app_user';

      IF FOUND THEN
      FOR user_row IN SELECT * FROM _app_user LIMIT 1 LOOP
        audit_row.app_user_id = user_row.user_id;
        audit_row.app_user_type = user_row.user_type;
        audit_row.app_ip_address = user_row.ip_address;
      END LOOP;
      END IF;
    END;
    -- end app_user data

    INSERT INTO auditing.logged_actions VALUES (audit_row.*);
    RETURN NULL;
  END;
$_$;


--
-- Name: FUNCTION if_modified_func(); Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON FUNCTION auditing.if_modified_func() IS '
  Track changes to a table at the statement and/or row level.

  Optional parameters to trigger in CREATE TRIGGER call:

  param 0: boolean, whether to log the query text. Default ''t''.

  param 1: text, primary_key_column of audited table if bigint.

  param 2: text[], columns to ignore in updates. Default [].

       Updates to ignored cols are omitted from changed_fields.

       Updates with only ignored cols changed are not inserted
       into the audit log.

       Almost all the processing work is still done for updates
       that ignored. If you need to save the load, you need to use
       WHEN clause on the trigger instead.

       No warning or error is issued if ignored_cols contains columns
       that do not exist in the target table. This lets you specify
       a standard set of ignored columns.

  There is no parameter to disable logging of values. Add this trigger as
  a ''FOR EACH STATEMENT'' rather than ''FOR EACH ROW'' trigger if you do not
  want to log row values.

  Note that the user name logged is the login role for the session. The audit trigger
  cannot obtain the active role because it is reset by the SECURITY DEFINER invocation
  of the audit trigger its self.
';


--
-- Name: hash_password(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.hash_password(password text) RETURNS text
    LANGUAGE plpgsql
    AS $$
      BEGIN
        password = crypt(password, gen_salt('bf', 8));

        RETURN password;
      END;
      $$;


--
-- Name: temp_table_exists(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.temp_table_exists(character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
        BEGIN
          /* check the table exist in database and is visible*/
          PERFORM n.nspname, c.relname
          FROM pg_catalog.pg_class c
          LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname LIKE 'pg_temp_%' AND pg_catalog.pg_table_is_visible(c.oid)
          AND relname = $1;

          IF FOUND THEN
            RETURN TRUE;
          ELSE
            RETURN FALSE;
          END IF;

        END;
      $_$;


--
-- Name: valid_email_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valid_email_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.email = validate_email(NEW.email);

        RETURN NEW;
      END;
      $$;


--
-- Name: validate_email(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_email(email text) RETURNS text
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF email IS NOT NULL THEN
          IF email !~* '\A[^@\s\;]+@[^@\s\;]+\.[^@\s\;]+\Z' THEN
            RAISE EXCEPTION 'Invalid E-mail format %', email
                USING HINT = 'Please check your E-mail format.';
          END IF ;
          email = lower(email);
        END IF ;

        RETURN email;
      END;
      $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logged_actions; Type: TABLE; Schema: auditing; Owner: -
--

CREATE TABLE auditing.logged_actions (
    event_id bigint NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    relid oid NOT NULL,
    session_user_name text,
    app_user_id integer,
    app_user_type text,
    app_ip_address inet,
    action_tstamp_tx timestamp with time zone NOT NULL,
    action_tstamp_stm timestamp with time zone NOT NULL,
    action_tstamp_clk timestamp with time zone NOT NULL,
    transaction_id bigint,
    application_name text,
    client_addr inet,
    client_port integer,
    client_query text,
    action text NOT NULL,
    row_id bigint,
    row_data public.hstore,
    changed_fields public.hstore,
    statement_only boolean NOT NULL,
    CONSTRAINT logged_actions_action_check CHECK ((action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text])))
);


--
-- Name: TABLE logged_actions; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON TABLE auditing.logged_actions IS 'History of auditable actions on audited tables, from auditing.if_modified_func()';


--
-- Name: COLUMN logged_actions.event_id; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.event_id IS 'Unique identifier for each auditable event';


--
-- Name: COLUMN logged_actions.schema_name; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.schema_name IS 'Database schema audited table for this event is in';


--
-- Name: COLUMN logged_actions.table_name; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';


--
-- Name: COLUMN logged_actions.relid; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';


--
-- Name: COLUMN logged_actions.session_user_name; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.app_user_id; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.app_user_id IS 'Application-provided polymorphic user id';


--
-- Name: COLUMN logged_actions.app_user_type; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.app_user_type IS 'Application-provided polymorphic user type';


--
-- Name: COLUMN logged_actions.app_ip_address; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.app_ip_address IS 'Application-provided ip address of user whose statement caused the audited event';


--
-- Name: COLUMN logged_actions.action_tstamp_tx; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_stm; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';


--
-- Name: COLUMN logged_actions.action_tstamp_clk; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';


--
-- Name: COLUMN logged_actions.transaction_id; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';


--
-- Name: COLUMN logged_actions.application_name; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';


--
-- Name: COLUMN logged_actions.client_addr; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';


--
-- Name: COLUMN logged_actions.client_port; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';


--
-- Name: COLUMN logged_actions.client_query; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';


--
-- Name: COLUMN logged_actions.action; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';


--
-- Name: COLUMN logged_actions.row_id; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.row_id IS 'Record primary_key. Null for statement-level trigger. Prefers NEW.id if exists';


--
-- Name: COLUMN logged_actions.row_data; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';


--
-- Name: COLUMN logged_actions.changed_fields; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';


--
-- Name: COLUMN logged_actions.statement_only; Type: COMMENT; Schema: auditing; Owner: -
--

COMMENT ON COLUMN auditing.logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE; Schema: auditing; Owner: -
--

CREATE SEQUENCE auditing.logged_actions_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logged_actions_event_id_seq; Type: SEQUENCE OWNED BY; Schema: auditing; Owner: -
--

ALTER SEQUENCE auditing.logged_actions_event_id_seq OWNED BY auditing.logged_actions.event_id;


--
-- Name: table_sizes; Type: TABLE; Schema: auditing; Owner: -
--

CREATE TABLE auditing.table_sizes (
    oid bigint NOT NULL,
    schema character varying,
    name character varying,
    apx_row_count double precision,
    total_bytes bigint,
    idx_bytes bigint,
    toast_bytes bigint,
    tbl_bytes bigint,
    total text,
    idx text,
    toast text,
    tbl text
);


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
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: logged_actions event_id; Type: DEFAULT; Schema: auditing; Owner: -
--

ALTER TABLE ONLY auditing.logged_actions ALTER COLUMN event_id SET DEFAULT nextval('auditing.logged_actions_event_id_seq'::regclass);


--
-- Name: logged_actions logged_actions_pkey; Type: CONSTRAINT; Schema: auditing; Owner: -
--

ALTER TABLE ONLY auditing.logged_actions
    ADD CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id);


--
-- Name: table_sizes table_sizes_pkey; Type: CONSTRAINT; Schema: auditing; Owner: -
--

ALTER TABLE ONLY auditing.table_sizes
    ADD CONSTRAINT table_sizes_pkey PRIMARY KEY (oid);


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
-- Name: logged_actions_action_idx; Type: INDEX; Schema: auditing; Owner: -
--

CREATE INDEX logged_actions_action_idx ON auditing.logged_actions USING btree (action);


--
-- Name: logged_actions_action_tstamp_tx_stm_idx; Type: INDEX; Schema: auditing; Owner: -
--

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx ON auditing.logged_actions USING btree (action_tstamp_stm);


--
-- Name: logged_actions_relid_idx; Type: INDEX; Schema: auditing; Owner: -
--

CREATE INDEX logged_actions_relid_idx ON auditing.logged_actions USING btree (relid);


--
-- Name: logged_actions_row_id_idx; Type: INDEX; Schema: auditing; Owner: -
--

CREATE INDEX logged_actions_row_id_idx ON auditing.logged_actions USING btree (row_id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20180725160802'),
('20180725201614');


