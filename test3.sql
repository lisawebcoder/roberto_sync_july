--
-- pgsyncQL database dump
--

-- Dumped from database version 15.1
-- Dumped by pg_dump version 15.2

-- Started on 2023-06-08 15:35:34

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
-- TOC entry 5343 (class 1262 OID 16384)
-- Name: cs-database; Type: DATABASE; Schema: -; Owner: author
--

CREATE DATABASE "cs-database" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE "cs-database" OWNER TO pgsync;

\connect -reuse-previous=on "dbname='cs-database'"

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
-- TOC entry 9 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pgsync
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO pgsync;

--
-- TOC entry 5344 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pgsync
--

COMMENT ON SCHEMA public IS '';


--
-- TOC entry 2 (class 3079 OID 16385)
-- Name: dblink; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;


--
-- TOC entry 5346 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION dblink; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION dblink IS 'connect to other pgsyncQL databases from within a database';


--
-- TOC entry 3 (class 3079 OID 16431)
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- TOC entry 5347 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- TOC entry 4 (class 3079 OID 16559)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5348 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- TOC entry 5 (class 3079 OID 17605)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 5
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 1129 (class 1255 OID 17617)
-- Name: add_call_bookings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_call_bookings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	INSERT INTO "BookingCall"("callID", "bookingID", "pendingBooking")
	SELECT
		NEW."callID",
		"bookingID",
		"pending"
	FROM "Booking"
	LEFT JOIN "Customer"
	ON "Booking"."customerID" = "Customer"."customerID"
	LEFT JOIN "Unit"
	ON "Booking"."unitID" = "Unit"."unitID"
	LEFT JOIN "FacilityType"
	ON "Unit"."facilityTypeID" = "FacilityType"."facilityTypeID"
	LEFT JOIN "Facility"
	ON "FacilityType"."facilityID" = "Facility"."facilityID"
	WHERE "phoneNumberActive" IS TRUE
	AND ("Facility"."maskedPhoneNumber" = NEW."maskedPhoneNumber"
	AND "phoneNumber" = NEW."caller"
	OR "Booking"."maskedPhoneNumber" = NEW."maskedPhoneNumber");

	RETURN NEW;
END
$$;


ALTER FUNCTION public.add_call_bookings() OWNER TO pgsync;

--
-- TOC entry 5350 (class 0 OID 0)
-- Dependencies: 1129
-- Name: FUNCTION add_call_bookings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_call_bookings() IS 'Search and add bookingIDs when a new call is created.';


--
-- TOC entry 1130 (class 1255 OID 17618)
-- Name: add_call_facility_id(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_call_facility_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	facilityID UUID;
	initiator VARCHAR;
BEGIN

	SELECT
		"facilityID",
		"callInitiator"
	INTO
		facilityID, 
		initiator 
	FROM 
		(
			WITH bookings AS (
				SELECT
					"bookingID",
					"phoneNumber",
					"maskedPhoneNumber",
					"language"
				FROM "Booking"
				LEFT JOIN "Customer"
				ON "Booking"."customerID" = "Customer"."customerID"
				WHERE ("phoneNumber" = NEW.caller
				OR "maskedPhoneNumber" = NEW."maskedPhoneNumber")
				AND "phoneNumberActive" IS TRUE
			),
			facilities AS (
				SELECT
					"bookingID",
					"Facility"."maskedPhoneNumber" AS "facilityMaskedPhoneNumber",
					(
						SELECT "phoneNumber" FROM bookings
						WHERE bookings."bookingID" = "Booking"."bookingID"
					) AS "customerActualPhoneNumber",
					(
						SELECT "maskedPhoneNumber" FROM bookings
						WHERE bookings."bookingID" = "Booking"."bookingID"
					) AS "customerMaskedPhoneNumber",
					"Facility"."facilityID"
				FROM "Facility"
				LEFT JOIN "FacilityType"
				ON "FacilityType"."facilityID" = "Facility"."facilityID"
				LEFT JOIN "Unit"
				ON "Unit"."facilityTypeID" = "FacilityType"."facilityTypeID"
				LEFT JOIN "Booking"
				ON "Booking"."unitID" = "Unit"."unitID"
				WHERE "phoneNumberActive" IS TRUE
			)
			SELECT
				"facilityID",
				'customer' AS "callInitiator"
			FROM facilities
			WHERE ("customerActualPhoneNumber" = NEW.caller
			AND "customerMaskedPhoneNumber" = NEW."maskedPhoneNumber")
			OR "facilityMaskedPhoneNumber" = NEW."maskedPhoneNumber"
			UNION ALL
			SELECT
				"facilityID",
				'facility' AS "callInitiator"
			FROM facilities
			WHERE "customerMaskedPhoneNumber" = NEW."maskedPhoneNumber"
			AND "customerActualPhoneNumber" <> NEW.caller
			ORDER BY "customerMaskedPhoneNumber"
			LIMIT 1
	  	) t;
	  
	NEW."facilityID" = facilityID;
	NEW."initiator" = initiator;
		
	RETURN NEW;
END 
$$;


ALTER FUNCTION public.add_call_facility_id() OWNER TO pgsync;

--
-- TOC entry 5351 (class 0 OID 0)
-- Dependencies: 1130
-- Name: FUNCTION add_call_facility_id(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_call_facility_id() IS 'Add facilityID when a new call is created.';


--
-- TOC entry 1131 (class 1255 OID 17621)
-- Name: add_customer_to_newsletter(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_customer_to_newsletter() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."newsletter" IS TRUE) THEN
		INSERT INTO "NewsletterMember" ("email", "language")
		VALUES (NEW."email", NEW."language");
	END IF;
	RETURN NEW;
END
$$;


ALTER FUNCTION public.add_customer_to_newsletter() OWNER TO pgsync;

--
-- TOC entry 5352 (class 0 OID 0)
-- Dependencies: 1131
-- Name: FUNCTION add_customer_to_newsletter(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_customer_to_newsletter() IS 'If the customer subscribed to the newsletter, add his email in the list of members.';


--
-- TOC entry 1132 (class 1255 OID 17622)
-- Name: add_facility_image_position(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_facility_image_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    imgCount INTEGER;
    minPos INTEGER;
BEGIN
    SELECT count("imageID")
    INTO imgCount
    FROM "FacilityImage"
    WHERE "FacilityImage"."facilityID" = NEW."facilityID"
    GROUP BY "facilityID";

    WITH arr AS (
        SELECT generate_series as "num" FROM generate_series(1, imgCount+1)
    )
    SELECT "num"
    INTO minPos
    FROM arr
    LEFT JOIN (
        SELECT * FROM "FacilityImage"
        WHERE "FacilityImage"."facilityID" = NEW."facilityID"
        AND "imageID" <> NEW."imageID"
    ) t
    ON arr."num" = "position"
    WHERE "position" IS NULL
    ORDER BY "num"
    LIMIT 1;
	            
    IF (NEW."position" > minPos AND minPos > imgCount)
    OR (NEW."position" IS NULL)
    THEN
    	NEW."position" = minPos;
    END IF;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.add_facility_image_position() OWNER TO pgsync;

--
-- TOC entry 5353 (class 0 OID 0)
-- Dependencies: 1132
-- Name: FUNCTION add_facility_image_position(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_facility_image_position() IS 'Add a position number to the image if it is not defined.
Correct the position number if it is too high.';


--
-- TOC entry 1133 (class 1255 OID 17623)
-- Name: add_facility_last_update_time(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_facility_last_update_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    NEW."lastUpdateTime" = CURRENT_TIMESTAMP;
    RETURN NEW;
END$$;


ALTER FUNCTION public.add_facility_last_update_time() OWNER TO pgsync;

--
-- TOC entry 5354 (class 0 OID 0)
-- Dependencies: 1133
-- Name: FUNCTION add_facility_last_update_time(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_facility_last_update_time() IS 'Update the time of the latest update.';


--
-- TOC entry 1134 (class 1255 OID 17624)
-- Name: add_facility_short_title(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_facility_short_title() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
BEGIN
	IF (NEW."title" IS NOT NULL AND NEW."shortTitle" IS NULL) THEN
		NEW."shortTitle" = (
			WITH input(title) AS (
			  VALUES ("title")
			),
			cleaned_title AS (
			  SELECT regexp_replace(title, '[\u0250-\ue007]', '', 'g') AS title_cleaned
			  FROM input
			),
			split_title AS (
			  SELECT split_part(title_cleaned, '|', 1) AS title_array
			  FROM cleaned_title
			),
			trimmed_title AS (
			  SELECT trim(title_array) AS title_trimmed
			  FROM split_title
			),
			words AS (
			  SELECT 
				word,
				row_number() OVER () AS word_position
			  FROM unnest(string_to_array((SELECT title_trimmed FROM trimmed_title), ' ')) WITH ORDINALITY AS t(word, ord)
			  WHERE length(word) <= 25
			),
			short_title AS (
			  SELECT regexp_replace(string_agg(word, ' '), '[\\s]*[-|](?=[\\s]*$)', '') AS short_title
			  FROM (
				SELECT 
				  word,
				  sum(length(word) + 1) OVER (ORDER BY word_position) - 1 AS running_length
				FROM words
			  ) s
			  WHERE running_length <= 25
			)
			SELECT
				short_title
			FROM short_title
		);
	END IF;
	
	RETURN NEW;
END
$_$;


ALTER FUNCTION public.add_facility_short_title() OWNER TO pgsync;

--
-- TOC entry 5355 (class 0 OID 0)
-- Dependencies: 1134
-- Name: FUNCTION add_facility_short_title(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_facility_short_title() IS 'Add facility short title from title.';


--
-- TOC entry 1135 (class 1255 OID 17625)
-- Name: add_facility_user_locale(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.add_facility_user_locale() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	locale VARCHAR;
	p_locale VARCHAR;
BEGIN
	PERFORM * FROM dblink_connect('dbname=cs-auth
		   port=5432 host=pg-keycloak
		   user=pgsync password=DcsJAdfODPsDNAfSUV');
	
	SELECT language INTO locale
	FROM public."Facility"
	WHERE "facilityID" = NEW."facilityID";
	
	SELECT t.value INTO p_locale
	FROM dblink('dbname=cs-auth
		   port=5432 host=pg-keycloak
		   user=pgsync password=DcsJAdfODPsDNAfSUV',
            concat('SELECT value FROM user_attribute WHERE user_id = ''', NEW."userID", ''' AND name = ''locale'''))
     AS t(value VARCHAR);
	
	-- if there's already a language stored here then here we wont go ahead
	IF ( p_locale IS NULL ) THEN
		PERFORM dblink_exec(concat('
	    	INSERT INTO user_attribute(name, value, user_id, id)
    		VALUES (''locale'', ''', locale, ''', ''', NEW."userID", ''', ''', uuid_generate_v4(), ''')'
		));
    END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.add_facility_user_locale() OWNER TO pgsync;

--
-- TOC entry 5356 (class 0 OID 0)
-- Dependencies: 1135
-- Name: FUNCTION add_facility_user_locale(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.add_facility_user_locale() IS 'When an user is added to FacilityUser, send pg-keycloak''s user_attribute the locale language of the facility.';


--
-- TOC entry 1136 (class 1255 OID 17626)
-- Name: check_booking_is_request(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_booking_is_request() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF ((
		SELECT "partner"
		FROM "Unit"
		LEFT JOIN "FacilityType"
		ON "FacilityType"."facilityTypeID" = "Unit"."facilityTypeID"
		LEFT JOIN "Facility"
		ON "Facility"."facilityID" = "FacilityType"."facilityID"
		WHERE "Unit"."unitID" = NEW."unitID"
	) IS TRUE) THEN
		NEW."isRequest" = FALSE;
	ELSE
		NEW."isRequest" = TRUE;
	END IF;

	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_booking_is_request() OWNER TO pgsync;

--
-- TOC entry 5357 (class 0 OID 0)
-- Dependencies: 1136
-- Name: FUNCTION check_booking_is_request(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_booking_is_request() IS 'Check if it''s a booking booking request or directly a booking.';


--
-- TOC entry 1138 (class 1255 OID 17627)
-- Name: check_booking_move_in_date(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_booking_move_in_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
   currentTz VARCHAR(255) := (
      SELECT "timezone" FROM "Unit"
      LEFT JOIN "FacilityType"
      ON "FacilityType"."facilityTypeID" = "Unit"."facilityTypeID"
      LEFT JOIN "Facility"
      ON "Facility"."facilityID" = "FacilityType"."facilityID"
      LEFT JOIN "Address"
      ON "Address"."addressID" = "Facility"."addressID"
      LEFT JOIN "PostalCode"
      ON "PostalCode"."postalCodeID" = "Address"."postalCodeID"
      LEFT JOIN "City"
      ON "City"."cityID" = "PostalCode"."cityID"
      LEFT JOIN "Country"
      ON "City"."countryID" = "Country"."countryID"
      WHERE "Unit"."unitID" = NEW."unitID"
   );
   tz                TEXT := (SELECT abbrev FROM pg_timezone_names WHERE name = currentTz);
   currentDate       DATE := timezone(tz, CURRENT_TIMESTAMP)::DATE;
   moveInDate        DATE := NEW."moveInDate";
   earlyDate    TIMESTAMP;
   lateDate     TIMESTAMP;
   early          INTEGER;
   late           INTEGER;
BEGIN
    SELECT "earlyBooking", "lateBooking"
    INTO early, late
    FROM "Unit"
    LEFT JOIN "FacilityType"
    ON "FacilityType"."facilityTypeID" = "Unit"."facilityTypeID"
    WHERE "unitID" = NEW."unitID";
    SELECT (currentDate + (early * INTERVAL '1 DAY'))::DATE INTO earlyDate;
    SELECT (currentDate + (late * INTERVAL '1 DAY'))::DATE INTO lateDate;

    IF (moveInDate < currentDate) THEN
        RAISE EXCEPTION 'Date (%) must be in the future', moveInDate;
    ELSIF (early IS NOT NULL AND moveInDate < earlyDate) THEN
        RAISE EXCEPTION 'Date (%) must be after the early booking date : %', moveInDate, earlyDate;
    ELSIF (lateDate IS NOT NULL AND moveInDate > lateDate) THEN
        RAISE EXCEPTION 'Date (%) must be before the late booking date : %', moveInDate, lateDate;
    END IF;
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_booking_move_in_date() OWNER TO pgsync;

--
-- TOC entry 5358 (class 0 OID 0)
-- Dependencies: 1138
-- Name: FUNCTION check_booking_move_in_date(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_booking_move_in_date() IS 'Check if the move-in date is within the range defined by the facility owner.';


--
-- TOC entry 1139 (class 1255 OID 17628)
-- Name: check_discount_activity(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_discount_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    unitDiscounts UUID;
    facilityDiscounts UUID;
BEGIN    
    SELECT "discountID"
    INTO unitDiscounts
    FROM "UnitDiscount"
    WHERE "discountID" = OLD."discountID";
    
    SELECT "discountID"
    INTO facilityDiscounts
    FROM "FacilityDiscount"
    WHERE "discountID" = OLD."discountID";
    
    IF (unitDiscounts IS NULL AND facilityDiscounts IS NULL AND NEW."active" = 't') THEN
        NEW."active" = FALSE;
        RAISE EXCEPTION 'This discount can not be active since nothing is associated with it.';
    END IF;
    
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_discount_activity() OWNER TO pgsync;

--
-- TOC entry 5359 (class 0 OID 0)
-- Dependencies: 1139
-- Name: FUNCTION check_discount_activity(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_discount_activity() IS 'Disable discount if nothing is associated with it.';


--
-- TOC entry 1140 (class 1255 OID 17629)
-- Name: check_discount_expiration_date(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_discount_expiration_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."expirationDate" IS NOT NULL AND NEW."expirationDate" <= (
		SELECT TIMEZONE((
			SELECT abbrev FROM pg_timezone_names WHERE name = (
				SELECT "timezone" FROM "Facility"
				LEFT JOIN "Address"
				ON "Address"."addressID" = "Facility"."addressID"
				LEFT JOIN "PostalCode"
				ON "PostalCode"."postalCodeID" = "Address"."postalCodeID"
				LEFT JOIN "City"
				ON "City"."cityID" = "PostalCode"."cityID"
				LEFT JOIN "Country"
				ON "City"."countryID" = "Country"."countryID"
			  	WHERE "Facility"."facilityID" = NEW."facilityID"
			)
		), CURRENT_TIMESTAMP)::DATE
	)) THEN
		RAISE EXCEPTION 'The expiration date of the discount "%" must be in the future', NEW."title";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_discount_expiration_date() OWNER TO pgsync;

--
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 1140
-- Name: FUNCTION check_discount_expiration_date(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_discount_expiration_date() IS 'Check if the expiration date is not in the past.';


--
-- TOC entry 1141 (class 1255 OID 17630)
-- Name: check_email_is_allowed(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_email_is_allowed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF ((
		SELECT
			(
				CASE
					WHEN "pending" IS TRUE OR "confirmed" IS TRUE
					THEN TRUE
					ELSE FALSE
				END
			)
		FROM "Booking"
		WHERE "Booking"."bookingID" = NEW."bookingID"
	) <> NEW."allowed") THEN
		IF (NEW."allowed" IS TRUE) THEN
			RAISE EXCEPTION 'The email is not allowed to be sent because the booking is no longer active.';
		ELSE
			RAISE EXCEPTION 'The email must be allowed to be sent because the booking is still active.';
		END IF;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_email_is_allowed() OWNER TO pgsync;

--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 1141
-- Name: FUNCTION check_email_is_allowed(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_email_is_allowed() IS 'Check if the email is allowed to be sent.';


--
-- TOC entry 1142 (class 1255 OID 17631)
-- Name: check_facility_discount_activity(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_discount_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    unitDiscounts UUID;
    facilityDiscounts UUID;
    active BOOL;
BEGIN
    SELECT "discountID"
    INTO unitDiscounts
    FROM "UnitDiscount"
    WHERE "discountID" = OLD."discountID";

    SELECT "discountID"
    INTO facilityDiscounts
    FROM "FacilityDiscount"
    WHERE "discountID" = OLD."discountID"
    AND "facilityDiscountID" != OLD."facilityDiscountID";
    
    SELECT "Discount"."active"
    INTO active
    FROM "Discount"
    WHERE "discountID" = OLD."discountID"
    OR "discountID" = NEW."discountID";
    
    IF (unitDiscounts IS NULL AND facilityDiscounts IS NULL AND active = 't') THEN
        UPDATE "Discount"
        SET "active" = FALSE
        WHERE "discountID" = OLD."discountID";
    END IF;
    
    IF (TG_OP = 'INSERT') THEN
        RETURN NEW;
    ELSE
        RETURN OLD;
    END IF;
END$$;


ALTER FUNCTION public.check_facility_discount_activity() OWNER TO pgsync;

--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 1142
-- Name: FUNCTION check_facility_discount_activity(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_discount_activity() IS 'Disable discount if nothing is associated with it.';


--
-- TOC entry 1143 (class 1255 OID 17632)
-- Name: check_facility_discount_apparition(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_discount_apparition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "UnitDiscount"
    WHERE "discountID" = NEW."discountID";
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_discount_apparition() OWNER TO pgsync;

--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 1143
-- Name: FUNCTION check_facility_discount_apparition(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_discount_apparition() IS 'Delete all units discounts if the discount is applied to all units.';


--
-- TOC entry 1144 (class 1255 OID 17633)
-- Name: check_facility_image_position(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_image_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    oldImageID UUID;
BEGIN
    SELECT "imageID"
    INTO oldImageID
    FROM "FacilityImage"
    WHERE "position" = NEW."position"
    AND "facilityID" = NEW."facilityID"
    AND "imageID" != NEW."imageID";
    
    IF (oldImageID IS NOT NULL) THEN
        DELETE FROM "FacilityImage"
        WHERE "imageID" = oldImageID;
        INSERT INTO "FacilityImage" ("imageID", "facilityID", "position")
            VALUES (oldImageID, NEW."facilityID", OLD."position");    
   END IF;

   RETURN NEW;
END$$;


ALTER FUNCTION public.check_facility_image_position() OWNER TO pgsync;

--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 1144
-- Name: FUNCTION check_facility_image_position(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_image_position() IS 'Swap position numbers between two images.';


--
-- TOC entry 1145 (class 1255 OID 17634)
-- Name: check_facility_info_verified_synchronization_config(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_info_verified_synchronization_config() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	syncEnabled BOOL;
BEGIN
	SELECT enabled
	INTO syncEnabled
	FROM "SynchronizationConfig"
	WHERE "synchronizationConfigID" = NEW."synchronizationConfigID";

	IF (NEW."infoVerified" = 'f' AND syncEnabled = 't') THEN
        RAISE EXCEPTION 'A Facility with an enabled SynchronizationConfig cannot lose its badge.';
	END IF;

	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_info_verified_synchronization_config() OWNER TO pgsync;

--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 1145
-- Name: FUNCTION check_facility_info_verified_synchronization_config(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_info_verified_synchronization_config() IS 'Prevents disabling infoVerified from facility if a synchronisation is enabled';


--
-- TOC entry 1146 (class 1255 OID 17635)
-- Name: check_facility_masked_phone_number_and_partner(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_masked_phone_number_and_partner() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."partner" IS TRUE AND NEW."partner" IS FALSE) THEN
		NEW."maskedPhoneNumber" = NULL;
	END IF;
	
	IF (NEW."partner" IS TRUE AND NEW."maskedPhoneNumber" IS NULL) THEN
		NEW."maskedPhoneNumber" = (
			SELECT "maskedPhoneNumber"
			FROM "MaskedPhoneNumber"
			WHERE "available" IS TRUE
			ORDER BY (
				SELECT "date" FROM "MaskedPhoneNumberAvailabilityHistory"
				WHERE "MaskedPhoneNumber"."maskedPhoneNumber" = "MaskedPhoneNumberAvailabilityHistory"."maskedPhoneNumber"
				AND "available" IS TRUE
				ORDER BY "date" DESC
				LIMIT 1
			)
			LIMIT 1
		);
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_masked_phone_number_and_partner() OWNER TO pgsync;

--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 1146
-- Name: FUNCTION check_facility_masked_phone_number_and_partner(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_masked_phone_number_and_partner() IS 'Dissociate the masked phone number of the facility when becoming non-partner and, on the opposite, associate a masked phone number when a facility become a partner.';


--
-- TOC entry 1148 (class 1255 OID 17636)
-- Name: check_facility_status(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."completed" IS FALSE AND NEW."online" IS TRUE AND NEW."partner" IS FALSE) THEN 
        RAISE EXCEPTION 'This ad can not be online since it is not completed yet';
    END IF;
    IF (NEW."completed" IS FALSE AND NEW."partner" IS TRUE) THEN 
        RAISE EXCEPTION 'This ad can not get the waiting status since it is not completed yet';
    END IF;
    IF (NEW."deleted" IS TRUE AND NEW."online" IS TRUE) THEN 
        NEW."online" = 'f';
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_status() OWNER TO pgsync;

--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 1148
-- Name: FUNCTION check_facility_status(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_status() IS 'Prevents facility ad to be online while it is not completed yet.
Prevents facility ad to get the waiting status while this facility is one of our partner.';


--
-- TOC entry 1149 (class 1255 OID 17637)
-- Name: check_facility_synchronisation(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_synchronisation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE "Unit"
	SET "archived" = TRUE
	WHERE "unitID" IN (
		SELECT "Unit"."unitID" FROM "FacilityType"
		LEFT JOIN "Unit"
		ON "Unit"."facilityTypeID" = "FacilityType"."facilityTypeID"
		LEFT JOIN "Booking"
		ON "Booking"."unitID" = "Unit"."unitID"
		WHERE "bookingID" IS NOT NULL
		AND "externalID" IS NULL
		AND "FacilityType"."facilityID" IN (
			SELECT "facilityID" FROM "Facility"
			WHERE "Facility"."synchronizationConfigID" = NEW."synchronizationConfigID"
		)
	);
	
	DELETE FROM "Unit"
	WHERE "unitID" IN (
		SELECT "Unit"."unitID" FROM "FacilityType"
		LEFT JOIN "Unit"
		ON "Unit"."facilityTypeID" = "FacilityType"."facilityTypeID"
		LEFT JOIN "Booking"
		ON "Booking"."unitID" = "Unit"."unitID"
		WHERE "bookingID" IS NULL
		AND "archived" IS FALSE
		AND "externalID" IS NULL
		AND "FacilityType"."facilityID" IN (
			SELECT "facilityID" FROM "Facility"
			WHERE "Facility"."synchronizationConfigID" = NEW."synchronizationConfigID"
		)
	);
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_synchronisation() OWNER TO pgsync;

--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 1149
-- Name: FUNCTION check_facility_synchronisation(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_synchronisation() IS 'Check that all non-integrated units are archived before creating new integrated units.';


--
-- TOC entry 1150 (class 1255 OID 17638)
-- Name: check_facility_title(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_title() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    facilityID UUID;
BEGIN    
    SELECT "facilityID"
    INTO facilityID
    FROM "Facility"
    WHERE "title" = NEW."title"
    AND "facilityID" <> NEW."facilityID";
    
    IF (facilityID IS NOT NULL AND NEW."completed" IS TRUE) THEN
        RAISE EXCEPTION 'This title already exists.';
    END IF;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_title() OWNER TO pgsync;

--
-- TOC entry 5369 (class 0 OID 0)
-- Dependencies: 1150
-- Name: FUNCTION check_facility_title(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_title() IS 'Check if the facility title does not already exist.';


--
-- TOC entry 1151 (class 1255 OID 17639)
-- Name: check_facility_type_alarm(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_type_alarm() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  specs TEXT[] := ARRAY['alarmInSomeUnits', 'alarmInEachUnit'];
  ind INT;
  ind2 INT;
BEGIN
  FOR ind IN SELECT generate_subscripts(specs,1)
  LOOP
    IF (SELECT (hstore(OLD) -> specs[ind])::bool IS FALSE AND (hstore(NEW) -> specs[ind])::bool IS TRUE) THEN
        FOR ind2 IN SELECT generate_subscripts(specs,1)
        LOOP
            IF (ind2 = ind) THEN
                CONTINUE;
            ELSE
                EXECUTE 'UPDATE "FacilityType"
                SET "' || specs[ind2] || '" = $1::bool
                WHERE "' || specs[ind2] || '" = $2::bool
                AND "facilityTypeID" = $3'
                USING 'f', 't', NEW."facilityTypeID";
            END IF;
        END LOOP;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


ALTER FUNCTION public.check_facility_type_alarm() OWNER TO pgsync;

--
-- TOC entry 5370 (class 0 OID 0)
-- Dependencies: 1151
-- Name: FUNCTION check_facility_type_alarm(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_type_alarm() IS 'Check that only one alarm feature is true.';


--
-- TOC entry 1152 (class 1255 OID 17640)
-- Name: check_facility_type_prorata(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_type_prorata() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."billingDate" <> 1 AND NEW."firstMonthProrata" IS TRUE) THEN
        NEW."firstMonthProrata" = 'f';
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_type_prorata() OWNER TO pgsync;

--
-- TOC entry 5371 (class 0 OID 0)
-- Dependencies: 1152
-- Name: FUNCTION check_facility_type_prorata(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_type_prorata() IS 'If the billing date is not the first day of the month, then firstMonthProrata must be false.';


--
-- TOC entry 1153 (class 1255 OID 17641)
-- Name: check_facility_type_some(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_type_some() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  specs TEXT[] := ARRAY[
	  ARRAY['heating', 'someHeating'],
	  ARRAY['airConditioning', 'airConditioning'],
	  ARRAY['heatedFloor', 'someHeatedFloor'],
	  ARRAY['electricity', 'someElectricity']
  ];
  ind INT;
  someSpec UUID;
BEGIN
  FOR ind IN SELECT generate_subscripts(specs,1)
  LOOP
    IF (SELECT (hstore(OLD) -> specs[ind][2])::bool IS FALSE AND (hstore(NEW) -> specs[ind][2])::bool IS TRUE) THEN
    
        SELECT "unitID"
        INTO someSpec
        FROM "FacilityType"
        LEFT JOIN "Unit"
        ON "Unit"."facilityTypeID" = "FacilityType"."facilityTypeID"
        WHERE (hstore("Unit") -> specs[ind][1])::bool IS TRUE
        AND "FacilityType"."facilityTypeID" = NEW."facilityTypeID";
        
        IF (someSpec IS NOT NULL) THEN
            EXECUTE 'UPDATE "Unit"
            SET "' || specs[ind][1] || '" = $1::bool
            WHERE "' || specs[ind][1] || '" = $2::bool
            AND "facilityTypeID" = $3::uuid'
            USING 'f', 't', NEW."facilityTypeID";
        END IF;
        
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


ALTER FUNCTION public.check_facility_type_some() OWNER TO pgsync;

--
-- TOC entry 5372 (class 0 OID 0)
-- Dependencies: 1153
-- Name: FUNCTION check_facility_type_some(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_type_some() IS 'Check if the "some" attribute has not the same value as the other attribute.';


--
-- TOC entry 1154 (class 1255 OID 17642)
-- Name: check_facility_type_terms(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_facility_type_terms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."monthlyBilling" IS TRUE AND OLD."monthlyBilling" IS FALSE) THEN
        NEW."billingFrequency" = NULL;
    END IF;
    IF (NEW."billingFrequency" IS NOT NULL AND OLD."billingFrequency" IS NULL) THEN
        NEW."monthlyBilling" = FALSE;
    END IF;
    IF (NEW."billingOnMoveInDate" IS TRUE AND OLD."billingOnMoveInDate" IS FALSE) THEN
        NEW."billingDate" = NULL;
    END IF;
    IF (NEW."billingDate" IS NOT NULL AND OLD."billingDate" IS NULL) THEN
        NEW."monthlyBilling" = FALSE;
    END IF;
    IF (OLD."minBookingDays" IS NULL AND NEW."minBookingDays" IS NOT NULL) THEN
        NEW."minBookingMonths" = NULL;
    ELSIF (NEW."minBookingMonths" IS NOT NULL) THEN
        NEW."minBookingDays" = NULL;
    END IF;
    IF (NEW."insuranceAvailable" IS NOT TRUE) THEN
        IF ((SELECT count(*) FROM "Insurance" WHERE "facilityTypeID" = NEW."facilityTypeID") > 0) THEN
            NEW."insuranceAvailable" = 't';
        END IF;
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_facility_type_terms() OWNER TO pgsync;

--
-- TOC entry 5373 (class 0 OID 0)
-- Dependencies: 1154
-- Name: FUNCTION check_facility_type_terms(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_facility_type_terms() IS 'Set monthlyBilling to true if the billing frequency is null and vice versa.
Set billingOnMovingDate to true if the billing date is null and vice versa.
Set minBookingDays to null if the minBookingMonths is not null and vice versa.';


--
-- TOC entry 1155 (class 1255 OID 17643)
-- Name: check_focus_session_start_time(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_focus_session_start_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    lastEndTime TIMESTAMP;
BEGIN
    SELECT "endTime"
    INTO lastEndTime
    FROM "FocusSession"
    WHERE "endTime" IS NOT NULL
    ORDER BY "endTime" DESC
    LIMIT 1;
        
    IF (NEW."startTime" < lastEndTime) THEN
        NEW."startTime" = lastEndTime;
    END IF;
    
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_focus_session_start_time() OWNER TO pgsync;

--
-- TOC entry 5374 (class 0 OID 0)
-- Dependencies: 1155
-- Name: FUNCTION check_focus_session_start_time(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_focus_session_start_time() IS 'Check if the new focus session does not overlap another one.';


--
-- TOC entry 1156 (class 1255 OID 17644)
-- Name: check_insurance_monthly_fee(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_insurance_monthly_fee() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    minCoverage NUMERIC;
    maxCoverage NUMERIC;
BEGIN
    SELECT "coverage" FROM "Insurance"
    INTO minCoverage
    WHERE NEW."monthlyFee" >= "Insurance"."monthlyFee"
    AND "facilityTypeID" = NEW."facilityTypeID"
    ORDER BY "monthlyFee" DESC
    LIMIT 1;
    
    SELECT "coverage" FROM "Insurance"
    INTO maxCoverage
    WHERE NEW."monthlyFee" <= "Insurance"."monthlyFee"
    AND "facilityTypeID" = NEW."facilityTypeID"
    ORDER BY "monthlyFee"
    LIMIT 1;  
    
    IF (NEW."coverage" <= minCoverage) OR (NEW."coverage" >= maxCoverage) THEN
        RAISE EXCEPTION 'Coverage is not proportionnal to the monthly fees (min: %, max: %).', minCoverage, maxCoverage;
    END IF;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_insurance_monthly_fee() OWNER TO pgsync;

--
-- TOC entry 5375 (class 0 OID 0)
-- Dependencies: 1156
-- Name: FUNCTION check_insurance_monthly_fee(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_insurance_monthly_fee() IS 'Check if the coverage is proportionnal to monthly fees.';


--
-- TOC entry 1157 (class 1255 OID 17645)
-- Name: check_masked_phone_number_availabiity(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_masked_phone_number_availabiity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF ((SELECT "available" FROM "MaskedPhoneNumber"
	   WHERE "maskedPhoneNumber" = NEW."maskedPhoneNumber") IS FALSE) THEN
	   RAISE EXCEPTION 'The masked phone number % is not available', NEW."maskedPhoneNumber";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_masked_phone_number_availabiity() OWNER TO pgsync;

--
-- TOC entry 5376 (class 0 OID 0)
-- Dependencies: 1157
-- Name: FUNCTION check_masked_phone_number_availabiity(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_masked_phone_number_availabiity() IS 'Check that the masked phone number is available.';


--
-- TOC entry 1159 (class 1255 OID 17646)
-- Name: check_masked_phone_number_availability_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_masked_phone_number_availability_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."available" IS TRUE AND (
		SELECT * FROM (
			SELECT "maskedPhoneNumber" FROM "Booking"
			WHERE "phoneNumberActive" IS TRUE
			UNION ALL
			SELECT "maskedPhoneNumber" FROM "Facility"
		) t WHERE "maskedPhoneNumber" = NEW."maskedPhoneNumber"
	) IS NOT NULL) THEN
		RAISE EXCEPTION 'The masked phone number % is referenced in another table.', NEW."maskedPhoneNumber";
	END IF;
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_masked_phone_number_availability_dependencies() OWNER TO pgsync;

--
-- TOC entry 5377 (class 0 OID 0)
-- Dependencies: 1159
-- Name: FUNCTION check_masked_phone_number_availability_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_masked_phone_number_availability_dependencies() IS 'Check that the masked phone number doesn''t exist in dependencies tables.';


--
-- TOC entry 1160 (class 1255 OID 17647)
-- Name: check_opening_hours_logic(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_opening_hours_logic() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    temprow RECORD;
BEGIN
    FOR temprow IN
        SELECT * FROM "OpeningHours"
        WHERE "facilityID" = NEW."facilityID"
        AND "dayOfWeek" = NEW."dayOfWeek"
		AND "type" = NEW."type"
    LOOP
        IF (temprow."openingTime" < NEW."closingTime" AND temprow."closingTime" > NEW."openingTime") THEN
            RAISE EXCEPTION 'Current interval [%, %] overlap with another interval which is [%, %])', NEW."openingTime", NEW."closingTime", temprow."openingTime", temprow."closingTime";
        ELSIF (temprow."closingTime" = NEW."openingTime" OR temprow."openingTime" = NEW."closingTime") THEN
            IF (temprow."closingTime" = NEW."openingTime") THEN
                NEW."openingTime" = temprow."openingTime";
            ELSIF (temprow."openingTime" = NEW."closingTime") THEN
                NEW."closingTime" = temprow."closingTime";
            END IF;
            DELETE FROM "OpeningHours"
            WHERE "facilityID" = temprow."facilityID"
            AND "dayOfWeek" = temprow."dayOfWeek"
            AND "openingTime" = temprow."openingTime"
            AND "closingTime" = temprow."closingTime"
			AND "type" = NEW."type";
        END IF;
    END LOOP;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_opening_hours_logic() OWNER TO pgsync;

--
-- TOC entry 5378 (class 0 OID 0)
-- Dependencies: 1160
-- Name: FUNCTION check_opening_hours_logic(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_opening_hours_logic() IS 'Check if no existing interval overlap with the new.
Join intervals together when they follow.';


--
-- TOC entry 1161 (class 1255 OID 17648)
-- Name: check_others_for_category_discounts(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_others_for_category_discounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "FacilityDiscount"
    WHERE "discountID" = NEW."discountID"
    AND "sizeCategoryID" IS NULL
    AND "storageTypeID" IS NULL;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_others_for_category_discounts() OWNER TO pgsync;

--
-- TOC entry 5379 (class 0 OID 0)
-- Dependencies: 1161
-- Name: FUNCTION check_others_for_category_discounts(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_others_for_category_discounts() IS 'When a discount is set to a specific unit category of a facility, delete all existing general discounts.';


--
-- TOC entry 1162 (class 1255 OID 17649)
-- Name: check_others_for_global_discounts(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_others_for_global_discounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "FacilityDiscount"
    WHERE "discountID" = NEW."discountID"
    AND NEW."facilityDiscountID" != "facilityDiscountID";
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_others_for_global_discounts() OWNER TO pgsync;

--
-- TOC entry 5380 (class 0 OID 0)
-- Dependencies: 1162
-- Name: FUNCTION check_others_for_global_discounts(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_others_for_global_discounts() IS 'When a discount is set to all units of a facility, delete all existing category discounts.';


--
-- TOC entry 1163 (class 1255 OID 17650)
-- Name: check_primary_booking_customer(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_primary_booking_customer() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."primaryBookingID" IS NOT NULL AND
		(SELECT "customerID" FROM "Booking"
		WHERE "bookingID" = NEW."primaryBookingID"
		LIMIT 1) <> NEW."customerID") THEN
		RAISE EXCEPTION 'The customer must be the same as for the primary booking';
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_primary_booking_customer() OWNER TO pgsync;

--
-- TOC entry 5381 (class 0 OID 0)
-- Dependencies: 1163
-- Name: FUNCTION check_primary_booking_customer(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_primary_booking_customer() IS 'Check if the customer of the primary booking is also the customer of the secondary bookings.';


--
-- TOC entry 1164 (class 1255 OID 17651)
-- Name: check_session_change(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_session_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    lastSessionActive UUID;
    currentDate TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    IF (TG_OP = 'INSERT' OR OLD."latestActivityTime" <> NEW."latestActivityTime") THEN
        SELECT "sessionID"
        INTO lastSessionActive
        FROM "Session"
        WHERE "user" = NEW."user"
        AND "latestActivityTime" IS NOT NULL
        ORDER BY "latestActivityTime" DESC
        LIMIT 1;

        UPDATE "SessionFacility"
        SET "endTime" = NULL,
            "notSaved" = FALSE
        WHERE "notSaved" = TRUE
        AND "sessionID" = lastSessionActive
        AND "endTime" IS NOT NULL;

        UPDATE "SessionFacility"
        SET "endTime" = currentDate,
            "notSaved" = TRUE
        WHERE "sessionFacilityID" IN (
            SELECT "sessionFacilityID" FROM "SessionFacility"
            LEFT JOIN "Session"
            ON "Session"."sessionID" = "SessionFacility"."sessionID"
            WHERE "SessionFacility"."endTime" IS NULL
            AND "user" = NEW."user"
            AND "SessionFacility"."sessionID" <> lastSessionActive
        );

        UPDATE "Session"
        SET "endTime" = currentDate
        WHERE "user" = NEW."user"
        AND "endTime" IS NULL
        AND "sessionID" <> lastSessionActive;

        UPDATE "Session"
        SET "endTime" = NULL
        WHERE "endTime" IS NOT NULL
        AND "sessionID" = lastSessionActive;

        IF (( SELECT "focusSessionID" FROM "FocusSession"
              WHERE "sessionID" = lastSessionActive
              AND "endTime" IS NULL
              LIMIT 1
            ) IS NULL) THEN
            INSERT INTO "FocusSession" ("sessionID", "startTime")
              VALUES (lastSessionActive, currentDate);
        END IF;
    END IF;
    
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_session_change() OWNER TO pgsync;

--
-- TOC entry 5382 (class 0 OID 0)
-- Dependencies: 1164
-- Name: FUNCTION check_session_change(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_session_change() IS 'Set endTime to NULL to the session with the most recent activity and set endTime to the current timestamp for the others.
Set notSaved to TRUE to session facilities active in other sessions and FALSE for the current session.';


--
-- TOC entry 1165 (class 1255 OID 17652)
-- Name: check_session_facility_focus_duration(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_session_facility_focus_duration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    totalDuration NUMERIC;
BEGIN
    SELECT
        CEIL(EXTRACT(epoch FROM NEW."endTime" - NEW."startTime"))
    INTO totalDuration;
    
    IF (totalDuration > NEW."focusDuration") THEN
        NEW."focusDuration" = totalDuration;
    END IF;
    
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_session_facility_focus_duration() OWNER TO pgsync;

--
-- TOC entry 5383 (class 0 OID 0)
-- Dependencies: 1165
-- Name: FUNCTION check_session_facility_focus_duration(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_session_facility_focus_duration() IS 'Check if the focus duration is not longer than the total duration.';


--
-- TOC entry 1166 (class 1255 OID 17653)
-- Name: check_session_lastest_activity_time(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_session_lastest_activity_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."endTime" IS NOT NULL AND NEW."latestActivityTime" > NEW."endTime") THEN
        NEW."endTime" = NEW."latestActivityTime";
    END IF;
 
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_session_lastest_activity_time() OWNER TO pgsync;

--
-- TOC entry 5384 (class 0 OID 0)
-- Dependencies: 1166
-- Name: FUNCTION check_session_lastest_activity_time(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_session_lastest_activity_time() IS 'Update endTime if latestActivityTime is larger.';


--
-- TOC entry 1167 (class 1255 OID 17654)
-- Name: check_timezone(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_timezone() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    abbrevExist INTEGER;
BEGIN
	IF (NEW.timezone IS NOT NULL) THEN
		abbrevExist = (SELECT COUNT(*) FROM (SELECT * FROM pg_timezone_names WHERE name = NEW.timezone) src);
		IF (abbrevExist = 0) THEN
			RAISE 'Timezone does not exist';
		END IF;
	END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_timezone() OWNER TO pgsync;

--
-- TOC entry 5385 (class 0 OID 0)
-- Dependencies: 1167
-- Name: FUNCTION check_timezone(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_timezone() IS 'Check if the timezone exists.';


--
-- TOC entry 1168 (class 1255 OID 17655)
-- Name: check_unit_archived(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_archived() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."archived" IS TRUE) THEN
		NEW."visible" = FALSE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_archived() OWNER TO pgsync;

--
-- TOC entry 5386 (class 0 OID 0)
-- Dependencies: 1168
-- Name: FUNCTION check_unit_archived(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_archived() IS 'Check that visible is false when archived is true.';


--
-- TOC entry 1169 (class 1255 OID 17656)
-- Name: check_unit_discount_activity(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_discount_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    unitDiscounts UUID;
    facilityDiscounts UUID;
    active BOOL;
BEGIN
    SELECT "discountID"
    INTO unitDiscounts
    FROM "UnitDiscount"
    WHERE "discountID" = OLD."discountID"
    AND "unitID" != OLD."unitID";

    SELECT "discountID"
    INTO facilityDiscounts
    FROM "FacilityDiscount"
    WHERE "discountID" = OLD."discountID";
    
    SELECT "Discount"."active"
    INTO active
    FROM "Discount"
    WHERE "discountID" = OLD."discountID"
    OR "discountID" = NEW."discountID";
    
    IF (unitDiscounts IS NULL AND facilityDiscounts IS NULL AND active = 't') THEN
        UPDATE "Discount"
        SET "active" = FALSE
        WHERE "discountID" = OLD."discountID";
    END IF;
    
    IF (TG_OP = 'INSERT') THEN
        RETURN NEW;
    ELSE
        RETURN OLD;
    END IF;
END$$;


ALTER FUNCTION public.check_unit_discount_activity() OWNER TO pgsync;

--
-- TOC entry 5387 (class 0 OID 0)
-- Dependencies: 1169
-- Name: FUNCTION check_unit_discount_activity(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_discount_activity() IS 'Disable discount if nothing is associated with it.';


--
-- TOC entry 1170 (class 1255 OID 17657)
-- Name: check_unit_discount_apparition(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_discount_apparition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "FacilityDiscount"
    WHERE "discountID" = NEW."discountID"
    AND "sizeCategoryID" IS NULL
    AND "storageTypeID" IS NULL;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_discount_apparition() OWNER TO pgsync;

--
-- TOC entry 5388 (class 0 OID 0)
-- Dependencies: 1170
-- Name: FUNCTION check_unit_discount_apparition(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_discount_apparition() IS 'Delete from FacilityDiscount when the discount is applied to all units.';


--
-- TOC entry 1171 (class 1255 OID 17658)
-- Name: check_unit_discount_facility_id(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_discount_facility_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    unitFacilityID UUID;
    discountFacilityID UUID;
BEGIN
    SELECT "facilityID"
    INTO unitFacilityID
    FROM "Unit"
    LEFT JOIN "FacilityType"
    ON "FacilityType"."facilityTypeID" = "Unit"."facilityTypeID"
    WHERE "unitID" = NEW."unitID"
	AND "archived" IS FALSE;
    
    SELECT "facilityID"
    INTO discountFacilityID
    FROM "Discount"
    WHERE "discountID" = NEW."discountID";
    
    IF (unitFacilityID <> discountFacilityID) THEN
        RAISE EXCEPTION 'The unit associated to this discount do not refer to the same facility of that discount.';
    END IF;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_discount_facility_id() OWNER TO pgsync;

--
-- TOC entry 5389 (class 0 OID 0)
-- Dependencies: 1171
-- Name: FUNCTION check_unit_discount_facility_id(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_discount_facility_id() IS 'Check if the unit associated to the discount refers to the same facility of that discount.';


--
-- TOC entry 1172 (class 1255 OID 17659)
-- Name: check_unit_floor(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_floor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (OLD."floorNb" IS NULL AND NEW."floorNb" IS NOT NULL) THEN
        NEW."noStairs" = FALSE;
    ELSIF (NEW."noStairs" IS TRUE) THEN
        NEW."floorNb" = NULL;
    END IF;
    IF (NEW."noStairs" IS NOT TRUE AND NEW."carAccess" IS TRUE) THEN
        NEW."noStairs" = TRUE;
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_floor() OWNER TO pgsync;

--
-- TOC entry 5390 (class 0 OID 0)
-- Dependencies: 1172
-- Name: FUNCTION check_unit_floor(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_floor() IS 'Set floorNb to null if noStairs is true and vice versa.';


--
-- TOC entry 1173 (class 1255 OID 17660)
-- Name: check_unit_outdoor(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_outdoor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    IF (NEW."outdoor" IS TRUE AND (
          SELECT "storageTypeID" FROM "FacilityType"
          WHERE "facilityTypeID" = NEW."facilityTypeID"
        ) = 2) THEN
        NEW."heating" = 'f';
        NEW."airConditioning" = 'f';
        NEW."heatedFloor" = 'f';
    END IF;
    RETURN NEW;
END$$;


ALTER FUNCTION public.check_unit_outdoor() OWNER TO pgsync;

--
-- TOC entry 5391 (class 0 OID 0)
-- Dependencies: 1173
-- Name: FUNCTION check_unit_outdoor(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_outdoor() IS 'Desactive indoor features if unit is outdoor.';


--
-- TOC entry 1174 (class 1255 OID 17661)
-- Name: check_unit_price(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."regularPrice" IS NULL AND NEW."discountedPrice" IS NOT NULL) THEN
        NEW."regularPrice" = NEW."discountedPrice";
		NEW."discountedPrice" = NULL;
    ELSIF (NEW."regularPrice" IS NOT NULL AND NEW."discountedPrice" >= NEW."regularPrice") THEN
        NEW."discountedPrice" = NULL;
    END IF;
		
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_price() OWNER TO pgsync;

--
-- TOC entry 5392 (class 0 OID 0)
-- Dependencies: 1174
-- Name: FUNCTION check_unit_price(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_price() IS 'Set regular price equal to discounted price if null and vice versa.';


--
-- TOC entry 1175 (class 1255 OID 17662)
-- Name: check_unit_size(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_size() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    prevSizeCategoryID INT;
BEGIN
    IF ((SELECT "storageTypeID" FROM "FacilityType"
         WHERE "facilityTypeID" = NEW."facilityTypeID"
        ) = 2) THEN
        NEW."sizeCategoryID" = NULL;
    ELSE
        SELECT "sizeCategoryID" FROM "Unit"
        INTO prevSizeCategoryID
        WHERE "facilityTypeID" = NEW."facilityTypeID"
        AND ("width"*"length") <= (NEW."width"*NEW."length")
        ORDER BY "width"*"length" DESC
        LIMIT 1;

        IF (prevSizeCategoryID IS NOT NULL AND prevSizeCategoryID > NEW."sizeCategoryID") THEN
            NEW."sizeCategoryID" = prevSizeCategoryID;
        END IF;
    END IF;
    
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_size() OWNER TO pgsync;

--
-- TOC entry 5393 (class 0 OID 0)
-- Dependencies: 1175
-- Name: FUNCTION check_unit_size(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_size() IS 'Check if the unit category is coherent according to its size.';


--
-- TOC entry 1176 (class 1255 OID 17663)
-- Name: check_unit_some(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_some() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
  specs TEXT[] := ARRAY[ARRAY['heating', 'someHeating'],ARRAY['airConditioning', 'airConditioning'], ARRAY['heatedFloor', 'someHeatedFloor']];
  ind INT;
  someSpec UUID;
BEGIN
  FOR ind IN SELECT generate_subscripts(specs,1)
  LOOP
    IF (SELECT (hstore(OLD) -> specs[ind][1])::bool IS FALSE AND (hstore(NEW) -> specs[ind][1])::bool IS TRUE) THEN
        SELECT "facilityTypeID"
        INTO someSpec
        FROM "FacilityType"
        WHERE "facilityTypeID" = NEW."facilityTypeID"
        AND (hstore("FacilityType") -> specs[ind][2])::bool IS TRUE;
        IF (someSpec IS NOT NULL) THEN
            EXECUTE 'UPDATE "FacilityType"
            SET "' || specs[ind][2] || '" = $1::bool
            WHERE "facilityTypeID" = $2'
            USING 'f', NEW."facilityTypeID";
        END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$_$;


ALTER FUNCTION public.check_unit_some() OWNER TO pgsync;

--
-- TOC entry 5394 (class 0 OID 0)
-- Dependencies: 1176
-- Name: FUNCTION check_unit_some(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_some() IS 'Check that if the unit has "airConditioning" or "heating" attributes, then "someAirConditioning" or "someHeated" are false.';


--
-- TOC entry 1177 (class 1255 OID 17664)
-- Name: check_unit_vehicles(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_unit_vehicles() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."possiblyVehicle" IS TRUE
        AND NEW."motorcycle" IS FALSE
        AND NEW."car" IS FALSE
        AND NEW."rv" IS FALSE
        AND NEW."boat" IS FALSE) THEN
        NEW."possiblyVehicle" = 'f';
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.check_unit_vehicles() OWNER TO pgsync;

--
-- TOC entry 5395 (class 0 OID 0)
-- Dependencies: 1177
-- Name: FUNCTION check_unit_vehicles(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_unit_vehicles() IS 'Check that one or more vehicles are selected when the possiblyVehicle attribute is true.';


--
-- TOC entry 1178 (class 1255 OID 17665)
-- Name: check_user_exist(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.check_user_exist() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
    IF NOT EXISTS (SELECT * FROM
    dblink('dbname=cs-auth
           port=5432 host=pg-keycloak
           user=pgsync password=DcsJAdfODPsDNAfSUV',
           concat('SELECT id FROM public."user_entity" WHERE "id" IN (''',NEW."userID",''')')
    ) AS ResponseTable(
        userID uuid
    )) THEN
        RAISE EXCEPTION 'entry does not exist';
    END IF;
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_user_exist() OWNER TO pgsync;

--
-- TOC entry 5396 (class 0 OID 0)
-- Dependencies: 1178
-- Name: FUNCTION check_user_exist(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.check_user_exist() IS 'Checks if the user exists in pg-keycloak''s database, an external database';


--
-- TOC entry 1179 (class 1255 OID 17666)
-- Name: convert_measure(character varying, character varying, numeric); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.convert_measure("fromSystem" character varying DEFAULT 'metric'::character varying, "toSystem" character varying DEFAULT 'imperial'::character varying, measure numeric DEFAULT 0) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
converted NUMERIC;
BEGIN
    SELECT
        CASE
            WHEN "fromSystem" = 'metric' AND "toSystem" = 'imperial'
                THEN ROUND("measure"*3.2808, 1)
			WHEN "fromSystem" = 'imperial' AND "toSystem" = 'metric'
                THEN ROUND("measure"/3.2808, 1)
            ELSE ROUND("measure", 1)
		END
		AS converted
    INTO converted;
    RETURN converted;
END
$$;


ALTER FUNCTION public.convert_measure("fromSystem" character varying, "toSystem" character varying, measure numeric) OWNER TO pgsync;

--
-- TOC entry 1180 (class 1255 OID 17667)
-- Name: copy_price_info(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.copy_price_info() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    regularPrice    NUMERIC;
    discountedPrice NUMERIC;
BEGIN
    SELECT "regularPrice", "discountedPrice"
	INTO regularPrice, discountedPrice
	FROM "Unit"
	WHERE "unitID" = NEW."unitID";
	
    NEW."regularPrice" = regularPrice;
    NEW."discountedPrice" = discountedPrice;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.copy_price_info() OWNER TO pgsync;

--
-- TOC entry 5397 (class 0 OID 0)
-- Dependencies: 1180
-- Name: FUNCTION copy_price_info(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.copy_price_info() IS 'Copy price info from the unit table to the booking table for each new booking.';


--
-- TOC entry 1181 (class 1255 OID 17668)
-- Name: delete_booking_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_booking_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (OLD."endDate" IS NULL) THEN
        RAISE EXCEPTION 'This booking is not ended';
    ELSE
        DELETE FROM "BookingDiscount"
        WHERE "bookingID" = OLD."bookingID";
    END IF;    
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_booking_dependencies() OWNER TO pgsync;

--
-- TOC entry 5398 (class 0 OID 0)
-- Dependencies: 1181
-- Name: FUNCTION delete_booking_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_booking_dependencies() IS 'Delete Booking table dependencies.';


--
-- TOC entry 1182 (class 1255 OID 17669)
-- Name: delete_discount_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_discount_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NOT EXISTS (
        SELECT * FROM "BookingDiscount"
        LEFT JOIN "Booking"
        ON "Booking"."bookingID" = "BookingDiscount"."bookingID"
        WHERE "discountID" = OLD."discountID"
        AND "Booking"."endDate" IS NULL
    )) THEN
    
        DELETE FROM "UnitDiscount"
        WHERE "discountID" = OLD."discountID";

        DELETE FROM "FacilityDiscount"
        WHERE "discountID" = OLD."discountID";
        
    ELSE
        RAISE EXCEPTION 'Some bookings are not ended';
    END IF;
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_discount_dependencies() OWNER TO pgsync;

--
-- TOC entry 5399 (class 0 OID 0)
-- Dependencies: 1182
-- Name: FUNCTION delete_discount_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_discount_dependencies() IS 'Delete Discount table dependencies.';


--
-- TOC entry 1137 (class 1255 OID 17670)
-- Name: delete_epicenter_city_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_epicenter_city_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    temprow RECORD;
BEGIN
    DELETE FROM "SearchedCity"
    WHERE "epicenterCityID" = OLD."epicenterCityID";
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_epicenter_city_dependencies() OWNER TO pgsync;

--
-- TOC entry 5400 (class 0 OID 0)
-- Dependencies: 1137
-- Name: FUNCTION delete_epicenter_city_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_epicenter_city_dependencies() IS 'Delete EpicenterCity table dependencies.';


--
-- TOC entry 1183 (class 1255 OID 17671)
-- Name: delete_facility_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_facility_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    temprow RECORD;
BEGIN
    DELETE FROM "OfficeHours"
    WHERE "facilityID" = OLD."facilityID";
    
    DELETE FROM "AccessHours"
    WHERE "facilityID" = OLD."facilityID";
   
    FOR temprow IN
        DELETE FROM "FacilityImage"
        WHERE "facilityID" = OLD."facilityID"
        RETURNING "imageID"
    LOOP
        DELETE FROM "Image"
        WHERE "imageID" = temprow."imageID";
    END LOOP;
        
    DELETE FROM "Discount"
    WHERE "facilityID" = OLD."facilityID";
    
    DELETE FROM "FacilityType"
    WHERE "facilityID" = OLD."facilityID";
    
    DELETE FROM "Note"
    WHERE "facilityID" = OLD."facilityID";
    
    DELETE FROM "FacilityTag"
    WHERE "facilityID" = OLD."facilityID";
    
    DELETE FROM "SessionFacility"
    WHERE "facilityID" = OLD."facilityID";
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_facility_dependencies() OWNER TO pgsync;

--
-- TOC entry 5401 (class 0 OID 0)
-- Dependencies: 1183
-- Name: FUNCTION delete_facility_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_facility_dependencies() IS 'Delete Facility table dependencies.';


--
-- TOC entry 1184 (class 1255 OID 17672)
-- Name: delete_facility_type_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_facility_type_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    temprow RECORD;
BEGIN
    UPDATE "Unit"
	SET "archived" = TRUE
    WHERE "facilityTypeID" = OLD."facilityTypeID";
    
    DELETE FROM "Insurance"
    WHERE "facilityTypeID" = OLD."facilityTypeID";
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_facility_type_dependencies() OWNER TO pgsync;

--
-- TOC entry 5402 (class 0 OID 0)
-- Dependencies: 1184
-- Name: FUNCTION delete_facility_type_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_facility_type_dependencies() IS 'Delete Facility Type table dependencies.';


--
-- TOC entry 1185 (class 1255 OID 17673)
-- Name: delete_image_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_image_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    DELETE FROM "FacilityImage"
    WHERE "imageID" = OLD."imageID";
    
    DELETE FROM "City"
    WHERE "imageID" = OLD."imageID";
    
    DELETE FROM "Neighborhood"
    WHERE "imageID" = OLD."imageID";
    
    DELETE FROM "SuperArea1"
    WHERE "imageID" = OLD."imageID";
    
    DELETE FROM "SuperArea2"
    WHERE "imageID" = OLD."imageID";
    
    DELETE FROM "Country"
    WHERE "imageID" = OLD."imageID";

    RETURN OLD;
END$$;


ALTER FUNCTION public.delete_image_dependencies() OWNER TO pgsync;

--
-- TOC entry 5403 (class 0 OID 0)
-- Dependencies: 1185
-- Name: FUNCTION delete_image_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_image_dependencies() IS 'Delete Image table dependencies.';


--
-- TOC entry 1186 (class 1255 OID 17674)
-- Name: delete_image_independencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_image_independencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
    DELETE FROM "Image"
    WHERE "imageID" = OLD."imageID";
    
    RETURN OLD;
END$$;


ALTER FUNCTION public.delete_image_independencies() OWNER TO pgsync;

--
-- TOC entry 5404 (class 0 OID 0)
-- Dependencies: 1186
-- Name: FUNCTION delete_image_independencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_image_independencies() IS 'Delete Image table independencies.';


--
-- TOC entry 1187 (class 1255 OID 17675)
-- Name: delete_session_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_session_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "SessionFacility"
    WHERE "sessionID" = OLD."sessionID";
    
    DELETE FROM "FocusSession"
    WHERE "sessionID" = OLD."sessionID";
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_session_dependencies() OWNER TO pgsync;

--
-- TOC entry 5405 (class 0 OID 0)
-- Dependencies: 1187
-- Name: FUNCTION delete_session_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_session_dependencies() IS 'Delete all session dependencies.';


--
-- TOC entry 1188 (class 1255 OID 17676)
-- Name: delete_session_facility_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_session_facility_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "FacilityEvent"
    WHERE "sessionFacilityID" = OLD."sessionFacilityID";
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_session_facility_dependencies() OWNER TO pgsync;

--
-- TOC entry 5406 (class 0 OID 0)
-- Dependencies: 1188
-- Name: FUNCTION delete_session_facility_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_session_facility_dependencies() IS 'Delete SessionFacility table dependencies.';


--
-- TOC entry 1189 (class 1255 OID 17677)
-- Name: delete_session_oldest(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_session_oldest() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "Session"
    WHERE "sessionID" IN (
        SELECT "sessionID" FROM (
            SELECT "sessionID", ROW_NUMBER() OVER() AS "row" FROM (
                SELECT "sessionID" FROM "Session"
                ORDER BY "startTime" DESC
            ) t
        ) p
        WHERE "row" > 10000
    );
    RETURN NEW;
END
$$;


ALTER FUNCTION public.delete_session_oldest() OWNER TO pgsync;

--
-- TOC entry 5407 (class 0 OID 0)
-- Dependencies: 1189
-- Name: FUNCTION delete_session_oldest(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_session_oldest() IS 'Delete oldest sessions.';


--
-- TOC entry 1190 (class 1255 OID 17678)
-- Name: delete_unit_dependencies(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.delete_unit_dependencies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
    	SELECT * FROM "Booking"
    	WHERE "unitID" = OLD."unitID"
    ) OR (OLD."externalID" IS NOT NULL) THEN
		UPDATE "Unit"
		SET "archived" = TRUE
		WHERE "unitID" = OLD."unitID";

		RETURN NULL;
    ELSE
		DELETE FROM "UnitDiscount"
		WHERE "unitID" = OLD."unitID";
		
		DELETE FROM "UnitPriceHistory"
		WHERE "unitID" = OLD."unitID";
		
		DELETE FROM "UnitVisibilityHistory"
		WHERE "unitID" = OLD."unitID";
		
		DELETE FROM "UnitAvailabilityHistory"
		WHERE "unitID" = OLD."unitID";
		
		DELETE FROM "UnitArchivalHistory"
		WHERE "unitID" = OLD."unitID";
    END IF;
    
    RETURN OLD;
END
$$;


ALTER FUNCTION public.delete_unit_dependencies() OWNER TO pgsync;

--
-- TOC entry 5408 (class 0 OID 0)
-- Dependencies: 1190
-- Name: FUNCTION delete_unit_dependencies(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.delete_unit_dependencies() IS 'Delete Unit table dependencies.';


--
-- TOC entry 1191 (class 1255 OID 17679)
-- Name: end_session_active(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.end_session_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    focusSessionStart TIMESTAMP;
BEGIN
    SELECT "startTime"
    INTO focusSessionStart
    FROM "FocusSession"
    WHERE "sessionID" = NEW."sessionID"
    AND "endTime" IS NULL;
    
    IF (NEW."latestActivityTime" IS NOT NULL AND NEW."latestActivityTime" > focusSessionStart) THEN
        UPDATE "FocusSession"
        SET "endTime" = NEW."latestActivityTime"
        WHERE "sessionID" = NEW."sessionID"
        AND "endTime" IS NULL;
    ELSE
        DELETE FROM "FocusSession"
        WHERE "sessionID" = NEW."sessionID"
        AND "endTime" IS NULL;
    END IF;
    
    DELETE FROM "SessionFacility"
    WHERE "notSaved" = FALSE
    AND "sessionID" = NEW."sessionID"
    AND "endTime" IS NULL;
    
    RETURN NEW;
END$$;


ALTER FUNCTION public.end_session_active() OWNER TO pgsync;

--
-- TOC entry 5409 (class 0 OID 0)
-- Dependencies: 1191
-- Name: FUNCTION end_session_active(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.end_session_active() IS 'Delete all active sessions facility and end all focus sessions when a session ends.';


--
-- TOC entry 1192 (class 1255 OID 17680)
-- Name: insert_booking_discounts(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.insert_booking_discounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "BookingDiscount" ("discountID", "bookingID")
    SELECT DISTINCT "discountID", NEW."bookingID" FROM (
        SELECT "Discount"."discountID", "active" FROM "Booking"
        LEFT JOIN "UnitDiscount"
        ON "UnitDiscount"."unitID" = "Booking"."unitID"
        LEFT JOIN "Discount"
        ON "Discount"."discountID" = "UnitDiscount"."discountID"
        WHERE "bookingID" = NEW."bookingID"
        UNION ALL
        SELECT "Discount"."discountID", "active" FROM "Booking"
        LEFT JOIN "Unit"
        ON "Unit"."unitID" = "Booking"."unitID"
        LEFT JOIN "FacilityType"
        ON "FacilityType"."facilityTypeID" = "Unit"."facilityTypeID"
        LEFT JOIN "Discount"
        ON "Discount"."facilityID" = "FacilityType"."facilityID"
        LEFT JOIN "FacilityDiscount" AS fd
        ON fd."discountID" = "Discount"."discountID"
        WHERE "facilityDiscountID" IS NOT NULL
        AND (fd."sizeCategoryID" IS NULL OR fd."sizeCategoryID" = "Unit"."sizeCategoryID")
        AND (fd."storageTypeID" IS NULL OR fd."storageTypeID" = "FacilityType"."storageTypeID")
        AND "bookingID" = NEW."bookingID"
    ) t
    WHERE "active" IS TRUE;
  
  RETURN NEW;
END
$$;


ALTER FUNCTION public.insert_booking_discounts() OWNER TO pgsync;

--
-- TOC entry 5410 (class 0 OID 0)
-- Dependencies: 1192
-- Name: FUNCTION insert_booking_discounts(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.insert_booking_discounts() IS 'Insert booking discounts in the corresponding table for each new booking.';


--
-- TOC entry 1193 (class 1255 OID 17681)
-- Name: loop_unit_prices(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.loop_unit_prices() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  temprow record;
BEGIN
  	FOR temprow IN
	
         (SELECT "placeID", "externalID"
    FROM dblink('dbname=cs-database user=pgsync host=10.0.3.33 password=V3o%jxQB6KIVSn',
      CONCAT('SELECT "placeID", "externalID" FROM "Facility" WHERE "synchronizationConfigID" = ''44b2a01b-242c-4941-9355-d180e9a42172'''))
    AS t("placeID" character varying, "externalID" character varying))
    
	
	LOOP
		UPDATE "Facility"
		SET "synchronizationConfigID" = '44b2a01b-242c-4941-9355-d180e9a42172',
			"externalID" = temprow."externalID"
		WHERE "placeID" = temprow."placeID";
    END LOOP;
END;
$$;


ALTER FUNCTION public.loop_unit_prices() OWNER TO pgsync;

--
-- TOC entry 1194 (class 1255 OID 17682)
-- Name: replace_address_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_address_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."apartmentNumber" = '') THEN
        NEW."apartmentNumber" = NULL;
    END IF;

    IF (NEW."streetNumber" = '') THEN
        NEW."streetNumber" = NULL;
    END IF;

    IF (NEW."streetName" = '') THEN
        NEW."streetName" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_address_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5411 (class 0 OID 0)
-- Dependencies: 1194
-- Name: FUNCTION replace_address_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_address_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1147 (class 1255 OID 17683)
-- Name: replace_booking_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_booking_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."cancelReason" = '') THEN
        NEW."cancelReason" = NULL;
    END IF;

    IF (NEW."review" = '') THEN
        NEW."review" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_booking_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5412 (class 0 OID 0)
-- Dependencies: 1147
-- Name: FUNCTION replace_booking_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_booking_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1158 (class 1255 OID 17684)
-- Name: replace_discount_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_discount_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN  
    IF (NEW."terms" = '') THEN
        NEW."terms" = NULL;
    END IF;
    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_discount_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5413 (class 0 OID 0)
-- Dependencies: 1158
-- Name: FUNCTION replace_discount_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_discount_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1195 (class 1255 OID 17685)
-- Name: replace_epicenter_city_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_epicenter_city_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."token" = '') THEN
        NEW."token" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_epicenter_city_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5414 (class 0 OID 0)
-- Dependencies: 1195
-- Name: FUNCTION replace_epicenter_city_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_epicenter_city_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1196 (class 1255 OID 17686)
-- Name: replace_facility_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_facility_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."title" = '') THEN
        NEW."title" = NULL;
    END IF;
	
	IF (NEW."description" = '') THEN
        NEW."description" = NULL;
    END IF;
	
    IF (NEW."placeID" = '') THEN
        NEW."placeID" = NULL;
    END IF;
	
	IF (NEW."website" = '') THEN
        NEW."website" = NULL;
    END IF;

    IF (NEW."author" = '') THEN
        NEW."author" = NULL;
    END IF;
	
	IF (NEW."welcomeNote" = '') THEN
        NEW."welcomeNote" = NULL;
    END IF;
	
	IF (NEW."externalID" = '') THEN
        NEW."externalID" = NULL;
    END IF;
	
	IF (NEW."language" = '') THEN
        NEW."language" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_facility_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5415 (class 0 OID 0)
-- Dependencies: 1196
-- Name: FUNCTION replace_facility_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_facility_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1197 (class 1255 OID 17687)
-- Name: replace_image_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_image_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."authorName" = '') THEN
        NEW."authorName" = NULL;
    END IF;

    IF (NEW."authorProfile" = '') THEN
        NEW."authorProfile" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_image_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5416 (class 0 OID 0)
-- Dependencies: 1197
-- Name: FUNCTION replace_image_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_image_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1198 (class 1255 OID 17688)
-- Name: replace_insurance_empty_strings(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.replace_insurance_empty_strings() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW."terms" = '') THEN
        NEW."terms" = NULL;
    END IF;

    RETURN NEW;
END
$$;


ALTER FUNCTION public.replace_insurance_empty_strings() OWNER TO pgsync;

--
-- TOC entry 5417 (class 0 OID 0)
-- Dependencies: 1198
-- Name: FUNCTION replace_insurance_empty_strings(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.replace_insurance_empty_strings() IS 'Replace empty string with null value.';


--
-- TOC entry 1199 (class 1255 OID 17689)
-- Name: save_info_verified_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_info_verified_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF (OLD."infoVerified" != NEW."infoVerified") THEN
		INSERT INTO "InfoVerifiedHistory" ("facilityID", "status")
		VALUES (NEW."facilityID", NEW."infoVerified");
	END IF;

	RETURN NEW;

END;
$$;


ALTER FUNCTION public.save_info_verified_history() OWNER TO pgsync;

--
-- TOC entry 5418 (class 0 OID 0)
-- Dependencies: 1199
-- Name: FUNCTION save_info_verified_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_info_verified_history() IS 'Save info verified history.';


--
-- TOC entry 1200 (class 1255 OID 17690)
-- Name: save_masked_phone_number_availability_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_masked_phone_number_availability_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO "MaskedPhoneNumberAvailabilityHistory" ("maskedPhoneNumber", "available")
	VALUES (NEW."maskedPhoneNumber", NEW."available");
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.save_masked_phone_number_availability_history() OWNER TO pgsync;

--
-- TOC entry 5419 (class 0 OID 0)
-- Dependencies: 1200
-- Name: FUNCTION save_masked_phone_number_availability_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_masked_phone_number_availability_history() IS 'Save masked phone number availability history.';


--
-- TOC entry 1201 (class 1255 OID 17691)
-- Name: save_unit_archival_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_unit_archival_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO "UnitArchivalHistory" ("unitID", "archived")
	VALUES (NEW."unitID", NEW."archived");
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.save_unit_archival_history() OWNER TO pgsync;

--
-- TOC entry 5420 (class 0 OID 0)
-- Dependencies: 1201
-- Name: FUNCTION save_unit_archival_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_unit_archival_history() IS 'Save unit archival history.';


--
-- TOC entry 1202 (class 1255 OID 17692)
-- Name: save_unit_availability_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_unit_availability_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO "UnitAvailabilityHistory" ("unitID", "available")
	VALUES (NEW."unitID", NEW."available");
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.save_unit_availability_history() OWNER TO pgsync;

--
-- TOC entry 5421 (class 0 OID 0)
-- Dependencies: 1202
-- Name: FUNCTION save_unit_availability_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_unit_availability_history() IS 'Save unit availability history.';


--
-- TOC entry 1203 (class 1255 OID 17693)
-- Name: save_unit_price_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_unit_price_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (coalesce(OLD."regularPrice", 0) <> coalesce(NEW."regularPrice", 0)) THEN
		INSERT INTO "UnitPriceHistory" ("unitID", "newPrice", "priceType")
    	VALUES (NEW."unitID", NEW."regularPrice", 'regular');
	END IF;
	
	IF (coalesce(OLD."discountedPrice", 0) <> coalesce(NEW."discountedPrice", 0)) THEN
		INSERT INTO "UnitPriceHistory" ("unitID", "newPrice", "priceType")
    	VALUES (NEW."unitID", NEW."discountedPrice", 'discounted');
	END IF;

	RETURN NEW;
END
$$;


ALTER FUNCTION public.save_unit_price_history() OWNER TO pgsync;

--
-- TOC entry 5422 (class 0 OID 0)
-- Dependencies: 1203
-- Name: FUNCTION save_unit_price_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_unit_price_history() IS 'Save regular and discounted prices history.';


--
-- TOC entry 1204 (class 1255 OID 17694)
-- Name: save_unit_visibility_history(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.save_unit_visibility_history() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	INSERT INTO "UnitVisibilityHistory" ("unitID", "visible")
	VALUES (NEW."unitID", NEW."visible");
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.save_unit_visibility_history() OWNER TO pgsync;

--
-- TOC entry 5423 (class 0 OID 0)
-- Dependencies: 1204
-- Name: FUNCTION save_unit_visibility_history(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.save_unit_visibility_history() IS 'Save unit visibility history.';


--
-- TOC entry 1205 (class 1255 OID 17695)
-- Name: update_booking_aborted(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_aborted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."aborted" IS FALSE AND NEW."aborted" IS TRUE) THEN
		IF (NEW."dateAborted" IS NULL) THEN
			NEW."dateAborted" = CURRENT_TIMESTAMP;
		END IF;
		NEW."pending" = FALSE;
		NEW."confirmed" = FALSE;
		NEW."dateConfirmed" = NULL;
		NEW."confirmationSource" = NULL;
		NEW."phoneNumberActive" = FALSE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_aborted() OWNER TO pgsync;

--
-- TOC entry 5424 (class 0 OID 0)
-- Dependencies: 1205
-- Name: FUNCTION update_booking_aborted(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_aborted() IS 'Add to the booking the date at which the booking has been aborted and remove the pending status.';


--
-- TOC entry 1206 (class 1255 OID 17696)
-- Name: update_booking_approved(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_approved() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."approved" IS FALSE AND NEW."approved" IS TRUE) THEN
		IF (NEW."dateApproved" IS NULL) THEN
			NEW."dateApproved" = CURRENT_TIMESTAMP;
		END IF;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_approved() OWNER TO pgsync;

--
-- TOC entry 5425 (class 0 OID 0)
-- Dependencies: 1206
-- Name: FUNCTION update_booking_approved(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_approved() IS 'Add to the booking the date at which the booking has been approved.';


--
-- TOC entry 1207 (class 1255 OID 17697)
-- Name: update_booking_canceled(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_canceled() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."canceled" IS FALSE AND NEW."canceled" IS TRUE) THEN
		IF (NEW."dateCanceled" IS NULL) THEN
			NEW."dateCanceled" = CURRENT_TIMESTAMP;
		END IF;
		NEW."pending" = FALSE;
		NEW."phoneNumberActive" = FALSE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_canceled() OWNER TO pgsync;

--
-- TOC entry 5426 (class 0 OID 0)
-- Dependencies: 1207
-- Name: FUNCTION update_booking_canceled(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_canceled() IS 'Add to the booking the date at which the booking has been canceled and remove the pending status.';


--
-- TOC entry 1208 (class 1255 OID 17698)
-- Name: update_booking_confirmed(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_confirmed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."confirmed" IS FALSE AND NEW."confirmed" IS TRUE) THEN
		IF (NEW."dateConfirmed" IS NULL) THEN
			NEW."dateConfirmed" = CURRENT_TIMESTAMP;
		END IF;
		NEW."pending" = FALSE;
		NEW."expired" = FALSE;
		NEW."dateExpired" = NULL;
		NEW."aborted" = FALSE;
		NEW."dateAborted" = NULL;
		NEW."abortionSource" = NULL;
		NEW."phoneNumberActive" = FALSE;
		NEW."contactInfoShared" = TRUE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_confirmed() OWNER TO pgsync;

--
-- TOC entry 5427 (class 0 OID 0)
-- Dependencies: 1208
-- Name: FUNCTION update_booking_confirmed(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_confirmed() IS 'Add to the booking the date at which the booking has been confirmed and remove the pending status.';


--
-- TOC entry 1209 (class 1255 OID 17699)
-- Name: update_booking_expired(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_expired() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."expired" IS FALSE AND NEW."expired" IS TRUE) THEN
		IF (NEW."dateExpired" IS NULL) THEN
			NEW."dateExpired" = CURRENT_TIMESTAMP;
		END IF;
		NEW."pending" = FALSE;
		NEW."phoneNumberActive" = FALSE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_expired() OWNER TO pgsync;

--
-- TOC entry 5428 (class 0 OID 0)
-- Dependencies: 1209
-- Name: FUNCTION update_booking_expired(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_expired() IS 'Add to the booking the date at which the booking has been expired and remove the pending status.';


--
-- TOC entry 1210 (class 1255 OID 17700)
-- Name: update_booking_masked_phone_number_availability(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_masked_phone_number_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."maskedPhoneNumber" IS NOT NULL AND (OLD."maskedPhoneNumber" <> NEW."maskedPhoneNumber" OR NEW."maskedPhoneNumber" IS NULL OR (OLD."phoneNumberActive" IS TRUE AND NEW."phoneNumberActive" IS FALSE))) THEN
		IF ((
			SELECT * FROM (
				SELECT "maskedPhoneNumber" FROM "Booking"
				WHERE "phoneNumberActive" IS TRUE
				UNION ALL
				SELECT "maskedPhoneNumber" FROM "Facility"
			) t WHERE "maskedPhoneNumber" = OLD."maskedPhoneNumber"
		) IS NULL) THEN
			UPDATE "MaskedPhoneNumber"
			SET "available" = TRUE
			WHERE "maskedPhoneNumber" = OLD."maskedPhoneNumber";
		END IF;
	END IF;
	
	IF (OLD."maskedPhoneNumber" IS NULL AND NEW."maskedPhoneNumber" IS NOT NULL OR OLD."phoneNumberActive" IS FALSE AND NEW."phoneNumberActive" IS TRUE) THEN
		UPDATE "MaskedPhoneNumber"
		SET "available" = FALSE
		WHERE "maskedPhoneNumber" = NEW."maskedPhoneNumber";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_masked_phone_number_availability() OWNER TO pgsync;

--
-- TOC entry 5429 (class 0 OID 0)
-- Dependencies: 1210
-- Name: FUNCTION update_booking_masked_phone_number_availability(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_masked_phone_number_availability() IS 'Set available or unavailable masked phone numbers when needed from the booking table.';


--
-- TOC entry 1211 (class 1255 OID 17701)
-- Name: update_booking_refused(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_booking_refused() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."refused" IS FALSE AND NEW."refused" IS TRUE) THEN
		IF (NEW."dateRefused" IS NULL) THEN
			NEW."dateRefused" = CURRENT_TIMESTAMP;
		END IF;
		NEW."pending" = FALSE;
		NEW."phoneNumberActive" = FALSE;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_booking_refused() OWNER TO pgsync;

--
-- TOC entry 5430 (class 0 OID 0)
-- Dependencies: 1211
-- Name: FUNCTION update_booking_refused(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_booking_refused() IS 'Add to the booking the date at which the booking has been refused and remove the pending status.';


--
-- TOC entry 1212 (class 1255 OID 17702)
-- Name: update_call_booking_status(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_call_booking_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."contactInfoShared" IS TRUE) THEN
		UPDATE "Booking"
		SET "phoneNumberActive" = FALSE
		WHERE "bookingID" IN (
			SELECT "bookingID" FROM "BookingCall"
			WHERE "callID" = NEW."callID"
		);
	END IF;
	
	IF (NEW."bookingConfirmed" IS TRUE) THEN
		UPDATE "Booking"
		SET	"confirmed" = TRUE,
			"confirmationSource" = 'call',
			"phoneNumberActive" = FALSE
		WHERE "bookingID" IN (
			SELECT "bookingID" FROM "BookingCall"
			WHERE "callID" = NEW."callID"
		);
	ELSIF (NEW."bookingAborted" IS TRUE) THEN
		UPDATE "Booking"
		SET	"aborted" = TRUE,
			"abortionSource" = 'call',
			"phoneNumberActive" = FALSE
		WHERE "bookingID" IN (
			SELECT "bookingID" FROM "BookingCall"
			WHERE "callID" = NEW."callID"
		);
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_call_booking_status() OWNER TO pgsync;

--
-- TOC entry 5431 (class 0 OID 0)
-- Dependencies: 1212
-- Name: FUNCTION update_call_booking_status(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_call_booking_status() IS 'Confirm booking in the booking table when a booking confirmation is detected in the call.
Abort booking in the booking table when a booking abortion is detected in the call.';


--
-- TOC entry 1213 (class 1255 OID 17703)
-- Name: update_call_end_time(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_call_end_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."status" = 'unanswered' AND NEW."endTime" IS NULL) THEN
		NEW."endTime" = CURRENT_TIMESTAMP;
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_call_end_time() OWNER TO pgsync;

--
-- TOC entry 5432 (class 0 OID 0)
-- Dependencies: 1213
-- Name: FUNCTION update_call_end_time(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_call_end_time() IS 'Add call end time when a call is unanswered.';


--
-- TOC entry 1214 (class 1255 OID 17704)
-- Name: update_customer_newsletter_email(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_customer_newsletter_email() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."newsletter" IS TRUE) THEN
		UPDATE "NewsletterMember"
		SET "email" = NEW."email"
		WHERE "email" = OLD."email";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_customer_newsletter_email() OWNER TO pgsync;

--
-- TOC entry 5433 (class 0 OID 0)
-- Dependencies: 1214
-- Name: FUNCTION update_customer_newsletter_email(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_customer_newsletter_email() IS 'Update customer email in newsletter members list when updated.';


--
-- TOC entry 1215 (class 1255 OID 17705)
-- Name: update_customer_newsletter_language(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_customer_newsletter_language() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."newsletter" IS TRUE) THEN
		UPDATE "NewsletterMember"
		SET "language" = NEW."language"
		WHERE "email" = NEW."email";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_customer_newsletter_language() OWNER TO pgsync;

--
-- TOC entry 5434 (class 0 OID 0)
-- Dependencies: 1215
-- Name: FUNCTION update_customer_newsletter_language(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_customer_newsletter_language() IS 'Update customer language in newsletter members list when updated.';


--
-- TOC entry 1216 (class 1255 OID 17706)
-- Name: update_email_booking_confirmed(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_email_booking_confirmed() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	IF (OLD."linkClicked" IS FALSE AND NEW."linkClicked" IS TRUE) THEN
		NEW."bookingConfirmed" = TRUE;
	END IF;
	
	RETURN NEW;
END$$;


ALTER FUNCTION public.update_email_booking_confirmed() OWNER TO pgsync;

--
-- TOC entry 5435 (class 0 OID 0)
-- Dependencies: 1216
-- Name: FUNCTION update_email_booking_confirmed(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_email_booking_confirmed() IS 'Set booking confirmed when link is clicked.';


--
-- TOC entry 1217 (class 1255 OID 17707)
-- Name: update_email_booking_status(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_email_booking_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (NEW."contactInfoShared" IS TRUE) THEN
		UPDATE "Booking"
		SET "phoneNumberActive" = FALSE
		WHERE "bookingID" = NEW."bookingID";
	END IF;
	
	IF (NEW."bookingConfirmed" IS TRUE) THEN
		UPDATE "Booking"
		SET "confirmed" = TRUE,
			"confirmationSource" = 'email'
		WHERE "bookingID" = NEW."bookingID";
	ELSIF (NEW."bookingAborted" IS TRUE) THEN
		UPDATE "Booking"
		SET "aborted" = TRUE,
			"abortionSource" = 'email'
		WHERE "bookingID" = NEW."bookingID";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_email_booking_status() OWNER TO pgsync;

--
-- TOC entry 5436 (class 0 OID 0)
-- Dependencies: 1217
-- Name: FUNCTION update_email_booking_status(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_email_booking_status() IS 'Confirm booking in the booking table when a booking confirmation is detected in the email.
Abort booking in the booking table when a booking abortion is detected in the email.';


--
-- TOC entry 1218 (class 1255 OID 17708)
-- Name: update_epicenter_radius(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_epicenter_radius() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    epicenterCityID UUID;
BEGIN
    IF (NEW."epicenterCityID" IS NOT NULL) THEN
        epicenterCityID = NEW."epicenterCityID";
    ELSIF (OLD."epicenterCityID" IS NOT NULL) THEN
        epicenterCityID = OLD."epicenterCityID";
    END IF;
    
    IF (epicenterCityID IS NOT NULL) THEN
      UPDATE "EpicenterCity"
      SET "radius" = coalesce((
          SELECT MAX("distance") FROM (
              WITH epicenterCoords AS (
                  SELECT "coordinates" FROM "EpicenterCity"
                  LEFT JOIN "City"
                  ON "City"."cityID" = "EpicenterCity"."cityID"
                  WHERE "epicenterCityID" = epicenterCityID
              )
              SELECT
                  ROUND(ST_DistanceSphere(
                      "Address"."coordinates",
                      (SELECT "coordinates" FROM epicenterCoords)
                  )/1000) as "distance"
              FROM "Facility"
              LEFT JOIN "Address"
              ON "Address"."addressID" = "Facility"."addressID"
              WHERE "epicenterCityID" = epicenterCityID
          ) t
      ), 0)
      WHERE "epicenterCityID" = epicenterCityID;
   END IF;
   RETURN NEW;
END
$$;


ALTER FUNCTION public.update_epicenter_radius() OWNER TO pgsync;

--
-- TOC entry 5437 (class 0 OID 0)
-- Dependencies: 1218
-- Name: FUNCTION update_epicenter_radius(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_epicenter_radius() IS 'Update epicenter city radius when some faclities are deleted.';


--
-- TOC entry 1219 (class 1255 OID 17709)
-- Name: update_facility_image_position(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_facility_image_position() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
    temprow RECORD;
    existing UUID;
BEGIN
    FOR temprow IN
        SELECT * FROM "FacilityImage"
        WHERE "facilityID" = OLD."facilityID"
        AND "position" > OLD."position"
        ORDER BY "position"
    LOOP
        SELECT "imageID" FROM "FacilityImage" INTO existing
        WHERE "facilityID" = OLD."facilityID"
        AND "position" = temprow."position"-1;
        
        IF existing IS NULL THEN
          DELETE FROM "FacilityImage"
          WHERE "imageID" = temprow."imageID";

          INSERT INTO "FacilityImage" ("imageID", "facilityID", "position")
              VALUES (temprow."imageID", temprow."facilityID", temprow."position"-1);        
        END IF;
        SELECT null INTO existing;
    END LOOP;
    RETURN NEW;
END$$;


ALTER FUNCTION public.update_facility_image_position() OWNER TO pgsync;

--
-- TOC entry 5438 (class 0 OID 0)
-- Dependencies: 1219
-- Name: FUNCTION update_facility_image_position(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_facility_image_position() IS 'Update image position when an image is deleted.';


--
-- TOC entry 1220 (class 1255 OID 17710)
-- Name: update_facility_masked_phone_number_availability(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_facility_masked_phone_number_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF (OLD."maskedPhoneNumber" IS NOT NULL
		AND (OLD."maskedPhoneNumber" <> NEW."maskedPhoneNumber"
		 OR NEW."maskedPhoneNumber" IS NULL)
	   ) THEN
		IF ((
			SELECT "maskedPhoneNumber" FROM "Booking"
			WHERE "phoneNumberActive" IS TRUE
			 AND "maskedPhoneNumber" = OLD."maskedPhoneNumber"
		) IS NULL) THEN
			UPDATE "MaskedPhoneNumber"
			SET "available" = TRUE
			WHERE "maskedPhoneNumber" = OLD."maskedPhoneNumber";
		END IF;
	END IF;
	
	IF (OLD."maskedPhoneNumber" IS NULL AND NEW."maskedPhoneNumber" IS NOT NULL
		OR OLD."maskedPhoneNumber" <> NEW."maskedPhoneNumber"
	   ) THEN
		UPDATE "MaskedPhoneNumber"
		SET "available" = FALSE
		WHERE "maskedPhoneNumber" = NEW."maskedPhoneNumber";
	END IF;
	
	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_facility_masked_phone_number_availability() OWNER TO pgsync;

--
-- TOC entry 5439 (class 0 OID 0)
-- Dependencies: 1220
-- Name: FUNCTION update_facility_masked_phone_number_availability(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_facility_masked_phone_number_availability() IS 'Set available or unavailable masked phone numbers when needed from the facility table.';


--
-- TOC entry 1221 (class 1255 OID 17711)
-- Name: update_reminder_last_update_time(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_reminder_last_update_time() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE "Reminder"
		SET "lastUpdateTime" = NOW()::timestamp
		WHERE NEW."facilityID" = "Reminder"."facilityID"
		AND NEW."status" = true;

	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_reminder_last_update_time() OWNER TO pgsync;

--
-- TOC entry 5440 (class 0 OID 0)
-- Dependencies: 1221
-- Name: FUNCTION update_reminder_last_update_time(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_reminder_last_update_time() IS 'Made to update Reminder''s last update time date on update of another table, giving it the current NOW timestamp value.';


--
-- TOC entry 1222 (class 1255 OID 17712)
-- Name: update_synchronization_config_info_verified(); Type: FUNCTION; Schema: public; Owner: pgsync
--

CREATE FUNCTION public.update_synchronization_config_info_verified() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 	UPDATE "Facility"
	SET "infoVerified"=NEW.enabled
	WHERE "synchronizationConfigID" = NEW."synchronizationConfigID";

	RETURN NEW;
END
$$;


ALTER FUNCTION public.update_synchronization_config_info_verified() OWNER TO pgsync;

--
-- TOC entry 5441 (class 0 OID 0)
-- Dependencies: 1222
-- Name: FUNCTION update_synchronization_config_info_verified(); Type: COMMENT; Schema: public; Owner: pgsync
--

COMMENT ON FUNCTION public.update_synchronization_config_info_verified() IS 'When SynchronizationConfig.enabled is updated to true, we update after the Facility.InfoVerified to true AND if the synchronization is no longer enabled, infoVerified is lost';


SET default_tablespace = '';

--
-- TOC entry 224 (class 1259 OID 17713)
-- Name: OpeningHours; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."OpeningHours" (
    "facilityID" uuid NOT NULL,
    "dayOfWeek" smallint NOT NULL,
    "openingTime" smallint NOT NULL,
    "closingTime" smallint NOT NULL,
    type character varying(255) NOT NULL,
    CONSTRAINT closing_time_inferior_to_24hrs CHECK (("closingTime" < 1440)),
    CONSTRAINT dayofweek_valid CHECK ((("dayOfWeek" >= 1) AND ("dayOfWeek" <= 7))),
    CONSTRAINT opening_time_inferior_to_24hrs CHECK (("openingTime" < 1440)),
    CONSTRAINT openingtime_not_null CHECK (("openingTime" >= 0)),
    CONSTRAINT time_order CHECK (("openingTime" < "closingTime"))
)
PARTITION BY LIST (type);


ALTER TABLE public."OpeningHours" OWNER TO pgsync;

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 17721)
-- Name: AccessHours; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."AccessHours" (
    "facilityID" uuid NOT NULL,
    "dayOfWeek" smallint NOT NULL,
    "openingTime" smallint NOT NULL,
    "closingTime" smallint NOT NULL,
    type character varying(255) NOT NULL,
    CONSTRAINT closing_time_inferior_to_24hrs CHECK (("closingTime" < 1440)),
    CONSTRAINT dayofweek_valid CHECK ((("dayOfWeek" >= 1) AND ("dayOfWeek" <= 7))),
    CONSTRAINT opening_time_inferior_to_24hrs CHECK (("openingTime" < 1440)),
    CONSTRAINT openingtime_not_null CHECK (("openingTime" >= 0)),
    CONSTRAINT time_order CHECK (("openingTime" < "closingTime"))
);


ALTER TABLE public."AccessHours" OWNER TO pgsync;

--
-- TOC entry 226 (class 1259 OID 17729)
-- Name: AdAccessRequest; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."AdAccessRequest" (
    "adAccessRequestID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "placeID" character varying(255) NOT NULL,
    "userID" uuid NOT NULL,
    "phoneNumber" character varying(255) NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."AdAccessRequest" OWNER TO pgsync;

--
-- TOC entry 227 (class 1259 OID 17736)
-- Name: Address; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Address" (
    "addressID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "apartmentNumber" character varying(255),
    "streetName" character varying(255),
    "postalCodeID" uuid NOT NULL,
    coordinates public.geometry NOT NULL,
    "streetNumber" character varying(255)
);


ALTER TABLE public."Address" OWNER TO pgsync;

--
-- TOC entry 228 (class 1259 OID 17742)
-- Name: Booking; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Booking" (
    "bookingID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "moveInDate" date NOT NULL,
    "unitID" uuid NOT NULL,
    "customerID" uuid NOT NULL,
    canceled boolean DEFAULT false NOT NULL,
    "cancelReason" character varying(255),
    notation integer,
    review text,
    "regularPrice" numeric(10,2),
    "discountedPrice" numeric(10,2),
    date timestamp without time zone DEFAULT CURRENT_DATE NOT NULL,
    "endDate" date,
    geoprecision character varying,
    "primaryBookingID" uuid,
    "dateCanceled" timestamp without time zone,
    "dateConfirmed" timestamp without time zone,
    "rentalDuration" smallint,
    "customMessage" text,
    coordinates public.geometry,
    "searchParams" json,
    "maskedPhoneNumber" character varying(255) NOT NULL,
    "phoneNumberActive" boolean DEFAULT true NOT NULL,
    pending boolean DEFAULT true NOT NULL,
    confirmed boolean DEFAULT false NOT NULL,
    expired boolean DEFAULT false NOT NULL,
    "confirmationSource" character varying(255),
    "dateExpired" timestamp without time zone,
    number character varying(7) DEFAULT upper(substr((public.uuid_generate_v4())::text, 30)) NOT NULL,
    "isRequest" boolean DEFAULT false NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    "dateApproved" timestamp without time zone,
    refused boolean DEFAULT false NOT NULL,
    "dateRefused" timestamp without time zone,
    "facilityBookingID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "refusalReason" text,
    aborted boolean DEFAULT false NOT NULL,
    "dateAborted" timestamp without time zone,
    "abortionSource" character varying(255),
    "contactInfoShared" boolean DEFAULT false NOT NULL,
    CONSTRAINT discountedprice_positive CHECK (("discountedPrice" > (0)::numeric)),
    CONSTRAINT notation_valid CHECK (((notation >= 0) AND (notation <= 5))),
    CONSTRAINT price_order CHECK ((("discountedPrice" IS NOT NULL) OR ("discountedPrice" < "regularPrice"))),
    CONSTRAINT regularprice_positive CHECK (("regularPrice" > (0)::numeric))
);


ALTER TABLE public."Booking" OWNER TO pgsync;

--
-- TOC entry 229 (class 1259 OID 17765)
-- Name: BookingCall; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."BookingCall" (
    "bookingID" uuid NOT NULL,
    "callID" uuid NOT NULL,
    "pendingBooking" boolean NOT NULL
);


ALTER TABLE public."BookingCall" OWNER TO pgsync;

--
-- TOC entry 230 (class 1259 OID 17768)
-- Name: BookingDiscount; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."BookingDiscount" (
    "discountID" uuid NOT NULL,
    "bookingID" uuid NOT NULL
);


ALTER TABLE public."BookingDiscount" OWNER TO pgsync;

--
-- TOC entry 231 (class 1259 OID 17771)
-- Name: booking_reason_sequence; Type: SEQUENCE; Schema: public; Owner: pgsync
--

CREATE SEQUENCE public.booking_reason_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.booking_reason_sequence OWNER TO pgsync;

--
-- TOC entry 232 (class 1259 OID 17772)
-- Name: BookingReason; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."BookingReason" (
    "bookingReasonID" integer DEFAULT nextval('public.booking_reason_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT bookingreasonid_positive CHECK (("bookingReasonID" > 0))
);


ALTER TABLE public."BookingReason" OWNER TO pgsync;

--
-- TOC entry 233 (class 1259 OID 17777)
-- Name: Call; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Call" (
    "callID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "facilityID" uuid NOT NULL,
    "startTime" timestamp without time zone,
    "endTime" timestamp without time zone,
    "recordingID" character varying(255),
    status character varying(255) DEFAULT 'ongoing'::character varying NOT NULL,
    "leftMessage" boolean DEFAULT false NOT NULL,
    language character varying(5),
    "customerSentiment" numeric,
    "contactInfoShared" boolean,
    "twilioCallID" character varying(255),
    initiator character varying(255) NOT NULL,
    caller character varying(255) NOT NULL,
    called character varying(255) NOT NULL,
    "twilioParentCallID" character varying(255) NOT NULL,
    "callerPostalCode" character varying(255),
    "callerCity" character varying(255),
    "callerState" character varying(255),
    "callerCountry" character varying(255),
    "calledPostalCode" character varying(255),
    "calledCity" character varying(255),
    "calledState" character varying(255),
    "calledCountry" character varying(255),
    "maskedPhoneNumber" character varying NOT NULL,
    "agentSentiment" numeric,
    "bookingConfirmed" boolean,
    "outputReason" text,
    voicemail boolean DEFAULT false NOT NULL,
    "bookingAborted" boolean,
    "storedItems" character varying(255)[],
    "bookingReasonID" integer,
    CONSTRAINT called_format CHECK (((called)::text ~ '^\+'::text)),
    CONSTRAINT caller_format CHECK (((caller)::text ~ '^\+'::text))
);


ALTER TABLE public."Call" OWNER TO pgsync;

--
-- TOC entry 234 (class 1259 OID 17788)
-- Name: City; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."City" (
    "cityID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255),
    "countryID" uuid NOT NULL,
    "superArea1ID" uuid,
    "superArea2ID" uuid,
    timezone character varying(255) DEFAULT 'America/Toronto'::character varying NOT NULL,
    coordinates public.geometry,
    "imageID" uuid,
    "placeID" character varying(255),
    CONSTRAINT city_not_null CHECK ((((name IS NOT NULL) AND ("placeID" IS NOT NULL)) OR ((name IS NULL) AND ("placeID" IS NULL))))
);


ALTER TABLE public."City" OWNER TO pgsync;

--
-- TOC entry 235 (class 1259 OID 17796)
-- Name: Country; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Country" (
    "countryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "currencyID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255) DEFAULT 1 NOT NULL,
    code character varying(2) DEFAULT 'ca'::character varying NOT NULL,
    "measurementSystem" character varying(255) DEFAULT 'metric'::character varying NOT NULL
);


ALTER TABLE public."Country" OWNER TO pgsync;

--
-- TOC entry 236 (class 1259 OID 17806)
-- Name: Currency; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Currency" (
    "currencyID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    code character varying(255) NOT NULL,
    currency character varying(255) NOT NULL,
    CONSTRAINT code_valid CHECK ((length((code)::text) = 3))
);


ALTER TABLE public."Currency" OWNER TO pgsync;

--
-- TOC entry 237 (class 1259 OID 17813)
-- Name: Customer; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Customer" (
    "customerID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "firstName" character varying(255) NOT NULL,
    "lastName" character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    "phoneNumber" character varying(255) NOT NULL,
    newsletter boolean DEFAULT false NOT NULL,
    language character varying(5) DEFAULT 'en-CA'::character varying NOT NULL,
    "dialCode" smallint NOT NULL,
    "formattedPhoneNumber" character varying(255) NOT NULL,
    "measurementSystem" character varying(255) DEFAULT 'metric'::character varying NOT NULL,
    CONSTRAINT email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."Customer" OWNER TO pgsync;

--
-- TOC entry 238 (class 1259 OID 17823)
-- Name: Discount; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Discount" (
    "discountID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    terms text,
    active boolean DEFAULT false NOT NULL,
    "facilityID" uuid NOT NULL,
    "expirationDate" date,
    language character varying(2) DEFAULT 'en'::character varying NOT NULL
);


ALTER TABLE public."Discount" OWNER TO pgsync;

--
-- TOC entry 239 (class 1259 OID 17831)
-- Name: Email; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Email" (
    "emailID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "bookingID" uuid NOT NULL,
    sender character varying(255) NOT NULL,
    initiator character varying(255) NOT NULL,
    bounced boolean DEFAULT false NOT NULL,
    opened boolean DEFAULT false NOT NULL,
    content text NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    recipients character varying[] NOT NULL,
    "bookingConfirmed" boolean DEFAULT false NOT NULL,
    "outputReason" text,
    "contactInfoShared" boolean DEFAULT false NOT NULL,
    "bookingAborted" boolean DEFAULT false,
    sentiment numeric NOT NULL,
    allowed boolean DEFAULT true NOT NULL,
    "storedItems" character varying(255)[],
    "inSpam" boolean DEFAULT false NOT NULL,
    "bookingReasonID" integer,
    "linkClicked" boolean DEFAULT false NOT NULL,
    CONSTRAINT bounced_and_not_opened CHECK (((bounced IS FALSE) OR (opened IS FALSE))),
    CONSTRAINT initiator_value CHECK ((((initiator)::text = 'customer'::text) OR ((initiator)::text = 'facility'::text))),
    CONSTRAINT sender_format CHECK (((sender)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."Email" OWNER TO pgsync;

--
-- TOC entry 240 (class 1259 OID 17849)
-- Name: EpicenterCity; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."EpicenterCity" (
    "epicenterCityID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "lastCityID" integer,
    radius smallint DEFAULT 0 NOT NULL,
    "cityID" uuid NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    token text,
    CONSTRAINT radius_positive CHECK ((radius >= 0))
);


ALTER TABLE public."EpicenterCity" OWNER TO pgsync;

--
-- TOC entry 241 (class 1259 OID 17858)
-- Name: Facility; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Facility" (
    "facilityID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    "addressID" uuid NOT NULL,
    "placeID" character varying(255),
    partner boolean DEFAULT false NOT NULL,
    online boolean DEFAULT false NOT NULL,
    completed boolean DEFAULT false NOT NULL,
    "creationDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    website character varying(255),
    "lastUpdateTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    author character varying(255),
    "epicenterCityID" uuid,
    timing integer,
    deleted boolean DEFAULT false NOT NULL,
    checked boolean DEFAULT true NOT NULL,
    "welcomeNote" text,
    language character varying(5) DEFAULT 'en-CA'::character varying NOT NULL,
    "descriptionLanguage" character varying(2) DEFAULT 'en-CA'::character varying,
    "latestSynchronization" timestamp without time zone,
    "externalID" character varying(255),
    "synchronizationConfigID" uuid,
    "maskedPhoneNumber" character varying,
    "shortTitle" character varying(25) NOT NULL,
    "infoVerified" boolean DEFAULT false NOT NULL,
    CONSTRAINT description_language CHECK ((((description IS NULL) AND ("descriptionLanguage" IS NULL)) OR ((description IS NOT NULL) AND ("descriptionLanguage" IS NOT NULL)))),
    CONSTRAINT timing_positive CHECK ((timing > 0)),
    CONSTRAINT website_format CHECK (((website)::text ~ '[Hh][Tt][Tt][Pp][Ss]?:\/\/(?:(?:[a-zA-Z¡-￿0-9]+-?)*[a-zA-Z¡-￿0-9]+)(?:.(?:[a-zA-Z¡-￿0-9]+-?)*[a-zA-Z¡-￿0-9]+)*(?:.(?:[a-zA-Z¡-￿]{0,}))(?::d{2,5})?(?:\/[^s]*)?'::text))
);


ALTER TABLE public."Facility" OWNER TO pgsync;

--
-- TOC entry 242 (class 1259 OID 17877)
-- Name: FacilityDiscount; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityDiscount" (
    "facilityDiscountID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "discountID" uuid NOT NULL,
    "sizeCategoryID" integer,
    "storageTypeID" integer
);


ALTER TABLE public."FacilityDiscount" OWNER TO pgsync;

--
-- TOC entry 243 (class 1259 OID 17881)
-- Name: FacilityEmail; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityEmail" (
    "facilityID" uuid NOT NULL,
    email character varying(255) NOT NULL,
    CONSTRAINT email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."FacilityEmail" OWNER TO pgsync;

--
-- TOC entry 244 (class 1259 OID 17885)
-- Name: FacilityEvent; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityEvent" (
    "facilityEventID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "sessionFacilityID" uuid NOT NULL,
    name character varying NOT NULL,
    data json NOT NULL
);


ALTER TABLE public."FacilityEvent" OWNER TO pgsync;

--
-- TOC entry 245 (class 1259 OID 17891)
-- Name: FacilityImage; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityImage" (
    "facilityID" uuid NOT NULL,
    "imageID" uuid NOT NULL,
    "position" smallint NOT NULL
);


ALTER TABLE public."FacilityImage" OWNER TO pgsync;

--
-- TOC entry 246 (class 1259 OID 17894)
-- Name: FacilityPhoneNumber; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityPhoneNumber" (
    "facilityID" uuid NOT NULL,
    "phoneNumber" character varying(255) NOT NULL,
    "dialCode" smallint NOT NULL,
    "formattedPhoneNumber" character varying(255) NOT NULL
);


ALTER TABLE public."FacilityPhoneNumber" OWNER TO pgsync;

--
-- TOC entry 247 (class 1259 OID 17899)
-- Name: FacilityTag; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityTag" (
    "tagID" smallint NOT NULL,
    "facilityID" uuid NOT NULL
);


ALTER TABLE public."FacilityTag" OWNER TO pgsync;

--
-- TOC entry 248 (class 1259 OID 17902)
-- Name: FacilityType; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityType" (
    "facilityTypeID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "facilityID" uuid NOT NULL,
    "storageTypeID" integer NOT NULL,
    "insuranceMandatory" boolean DEFAULT false NOT NULL,
    "insuranceAvailable" boolean DEFAULT false NOT NULL,
    "personalInsurance" boolean DEFAULT false NOT NULL,
    "monthlyBilling" boolean DEFAULT true NOT NULL,
    "billingFrequency" smallint,
    "billingOnMoveInDate" boolean DEFAULT true NOT NULL,
    "billingDate" smallint,
    "administrativeFees" smallint,
    "daysNotice" smallint,
    "keyDeposit" smallint,
    "earlyBooking" smallint,
    "lateBooking" smallint,
    "minBookingDays" smallint,
    "minBookingMonths" smallint,
    "interiorLoadingDock" boolean DEFAULT false NOT NULL,
    elevator boolean DEFAULT false NOT NULL,
    "disabledAccessible" boolean DEFAULT false NOT NULL,
    "electronicGate" boolean DEFAULT false NOT NULL,
    "padlockSale" boolean DEFAULT false NOT NULL,
    "videoSurveillance" boolean DEFAULT false NOT NULL,
    alarm boolean DEFAULT false NOT NULL,
    "lightingSystem" boolean DEFAULT false NOT NULL,
    "fencedBuilding" boolean DEFAULT false NOT NULL,
    "armoredDoors" boolean DEFAULT false NOT NULL,
    "staffOnSite" boolean DEFAULT false NOT NULL,
    "freeSackTruck" boolean DEFAULT false NOT NULL,
    "movingEquipmentSale" boolean DEFAULT false NOT NULL,
    "truckRental" boolean DEFAULT false NOT NULL,
    movers boolean DEFAULT false NOT NULL,
    cash boolean DEFAULT false NOT NULL,
    transfer boolean DEFAULT false NOT NULL,
    debit boolean DEFAULT false NOT NULL,
    mastercard boolean DEFAULT true NOT NULL,
    visa boolean DEFAULT true NOT NULL,
    amex boolean DEFAULT false NOT NULL,
    "onlinePayment" boolean DEFAULT false NOT NULL,
    "phonePayment" boolean DEFAULT false NOT NULL,
    interac boolean DEFAULT false NOT NULL,
    "outdoorLoadingDock" boolean DEFAULT false NOT NULL,
    "automaticPayment" boolean DEFAULT false NOT NULL,
    "bankCheck" boolean DEFAULT false NOT NULL,
    "securityGuard" boolean DEFAULT false NOT NULL,
    "fireSprinkler" boolean DEFAULT false NOT NULL,
    "heatDetector" boolean DEFAULT false NOT NULL,
    "someHeating" boolean DEFAULT false NOT NULL,
    "someAirConditioning" boolean DEFAULT false NOT NULL,
    "someHeatedFloor" boolean DEFAULT false NOT NULL,
    "packageReception" boolean DEFAULT false NOT NULL,
    "controlledAccess" boolean DEFAULT false NOT NULL,
    "smokeDetector" boolean DEFAULT false NOT NULL,
    "alarmInEachUnit" boolean DEFAULT false NOT NULL,
    "firstMonthProrata" boolean DEFAULT false NOT NULL,
    "antiBacterialCleaning" boolean DEFAULT false NOT NULL,
    "freeUseOfATrailer" boolean DEFAULT false NOT NULL,
    "alarmInSomeUnits" boolean DEFAULT false NOT NULL,
    "someElectricity" boolean DEFAULT false NOT NULL,
    CONSTRAINT administrativefees_not_negative CHECK ((("administrativeFees" >= 0) OR ("administrativeFees" IS NULL))),
    CONSTRAINT billingdate_valid CHECK ((("billingDate" > 0) AND ("billingDate" <= 31))),
    CONSTRAINT billingfrequency_positive CHECK (("billingFrequency" > 0)),
    CONSTRAINT booking_interval_valid CHECK (("earlyBooking" < "lateBooking")),
    CONSTRAINT daysnotice_not_null CHECK (("daysNotice" >= 0)),
    CONSTRAINT earlybooking_not_null CHECK (("earlyBooking" >= 0))
);


ALTER TABLE public."FacilityType" OWNER TO pgsync;

--
-- TOC entry 249 (class 1259 OID 17959)
-- Name: FacilityUser; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FacilityUser" (
    "facilityID" uuid NOT NULL,
    "userID" uuid NOT NULL,
    date date DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."FacilityUser" OWNER TO pgsync;

--
-- TOC entry 250 (class 1259 OID 17963)
-- Name: FocusSession; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."FocusSession" (
    "focusSessionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "sessionID" uuid NOT NULL,
    "startTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endTime" timestamp without time zone,
    CONSTRAINT "endTime_greater_than_startTime" CHECK (("startTime" <= "endTime"))
);


ALTER TABLE public."FocusSession" OWNER TO pgsync;

--
-- TOC entry 251 (class 1259 OID 17969)
-- Name: Image; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Image" (
    "imageID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key character varying(255) NOT NULL,
    "authorName" character varying(255),
    "authorProfile" character varying(255),
    CONSTRAINT authorprofile_format CHECK ((("authorProfile")::text ~ 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,255}\.[a-z]{2,9}\y([-a-zA-Z0-9@:%_\+.,~#?!&>//=]*)$'::text)),
    CONSTRAINT key_format CHECK (((key)::text ~ '^[a-zA-Z0-9-]+(?:\/[a-zA-Z0-9-]+)*$'::text))
);


ALTER TABLE public."Image" OWNER TO pgsync;

--
-- TOC entry 252 (class 1259 OID 17977)
-- Name: InfoVerifiedHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."InfoVerifiedHistory" (
    "facilityID" uuid NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "infoVerifiedHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    status boolean
);


ALTER TABLE public."InfoVerifiedHistory" OWNER TO pgsync;

--
-- TOC entry 253 (class 1259 OID 17982)
-- Name: Insurance; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Insurance" (
    "facilityTypeID" uuid NOT NULL,
    "monthlyFee" numeric(10,2) NOT NULL,
    coverage numeric(10,2) NOT NULL,
    terms text,
    CONSTRAINT coverage_positive CHECK (((coverage)::double precision > (0)::double precision)),
    CONSTRAINT coverage_superior_than_monthlyfee CHECK (((coverage)::double precision >= ("monthlyFee")::double precision)),
    CONSTRAINT coverage_valid CHECK (((coverage)::double precision > ("monthlyFee")::double precision)),
    CONSTRAINT monthlyfee_positive CHECK ((("monthlyFee")::double precision > (0)::double precision))
);


ALTER TABLE public."Insurance" OWNER TO pgsync;

--
-- TOC entry 254 (class 1259 OID 17991)
-- Name: MaskedPhoneNumber; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."MaskedPhoneNumber" (
    "maskedPhoneNumber" character varying(255) NOT NULL,
    available boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "dialCode" smallint NOT NULL,
    "formattedPhoneNumber" character varying(255) NOT NULL
);


ALTER TABLE public."MaskedPhoneNumber" OWNER TO pgsync;

--
-- TOC entry 255 (class 1259 OID 17998)
-- Name: MaskedPhoneNumberAvailabilityHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."MaskedPhoneNumberAvailabilityHistory" (
    "maskedPhoneNumberAvailabilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "maskedPhoneNumber" character varying(255) NOT NULL,
    available boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."MaskedPhoneNumberAvailabilityHistory" OWNER TO pgsync;

--
-- TOC entry 256 (class 1259 OID 18003)
-- Name: Region; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Region" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
)
PARTITION BY LIST (type);


ALTER TABLE public."Region" OWNER TO pgsync;

--
-- TOC entry 257 (class 1259 OID 18007)
-- Name: Neighborhood; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Neighborhood" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."Neighborhood" OWNER TO pgsync;

--
-- TOC entry 258 (class 1259 OID 18013)
-- Name: NewsletterMember; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."NewsletterMember" (
    "memberID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    language character varying(5) DEFAULT 'en-CA'::character varying NOT NULL,
    CONSTRAINT mail_valid CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."NewsletterMember" OWNER TO pgsync;

--
-- TOC entry 259 (class 1259 OID 18022)
-- Name: Note; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Note" (
    "noteID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "facilityID" uuid NOT NULL,
    body text NOT NULL,
    author character varying(255),
    "creationDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Note" OWNER TO pgsync;

--
-- TOC entry 260 (class 1259 OID 18030)
-- Name: OfficeHours; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."OfficeHours" (
    "facilityID" uuid NOT NULL,
    "dayOfWeek" smallint NOT NULL,
    "openingTime" smallint NOT NULL,
    "closingTime" smallint NOT NULL,
    type character varying(255) NOT NULL,
    CONSTRAINT closing_time_inferior_to_24hrs CHECK (("closingTime" < 1440)),
    CONSTRAINT dayofweek_valid CHECK ((("dayOfWeek" >= 1) AND ("dayOfWeek" <= 7))),
    CONSTRAINT opening_time_inferior_to_24hrs CHECK (("openingTime" < 1440)),
    CONSTRAINT openingtime_not_null CHECK (("openingTime" >= 0)),
    CONSTRAINT time_order CHECK (("openingTime" < "closingTime"))
);


ALTER TABLE public."OfficeHours" OWNER TO pgsync;

--
-- TOC entry 261 (class 1259 OID 18038)
-- Name: PostalCode; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."PostalCode" (
    "postalCodeID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "postalCode" character varying(255),
    "cityID" uuid NOT NULL,
    "neighborhoodID" uuid,
    "placeID" character varying(255)
);


ALTER TABLE public."PostalCode" OWNER TO pgsync;

--
-- TOC entry 262 (class 1259 OID 18044)
-- Name: Reminder; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Reminder" (
    "reminderID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    weekdays integer[],
    "userID" uuid NOT NULL,
    "facilityID" uuid NOT NULL,
    "creationDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastUpdateTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Reminder" OWNER TO pgsync;

--
-- TOC entry 263 (class 1259 OID 18052)
-- Name: SearchedCity; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SearchedCity" (
    "searchedCityID" integer NOT NULL,
    name character varying(255) NOT NULL,
    coordinates public.geometry NOT NULL,
    "epicenterCityID" uuid NOT NULL
);


ALTER TABLE public."SearchedCity" OWNER TO pgsync;

--
-- TOC entry 264 (class 1259 OID 18057)
-- Name: Session; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Session" (
    "sessionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "user" character varying,
    "startTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endTime" timestamp without time zone,
    "latestActivityTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "endTime_greater_than_startTime" CHECK (("startTime" <= "endTime"))
);


ALTER TABLE public."Session" OWNER TO pgsync;

--
-- TOC entry 265 (class 1259 OID 18066)
-- Name: SessionFacility; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SessionFacility" (
    "sessionFacilityID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "facilityID" uuid NOT NULL,
    "sessionID" uuid NOT NULL,
    "startTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endTime" timestamp without time zone,
    "focusDuration" integer,
    "firstCompletion" boolean NOT NULL,
    "nbActions" integer,
    "notSaved" boolean DEFAULT false NOT NULL,
    CONSTRAINT "endTime_greater_than_startTime" CHECK (("startTime" <= "endTime")),
    CONSTRAINT "focusDuration_positive" CHECK (("focusDuration" > 0)),
    CONSTRAINT "nbActions_positive" CHECK (("nbActions" > 0)),
    CONSTRAINT "notSaved_only_if_ended" CHECK (((("notSaved" IS TRUE) AND ("endTime" IS NOT NULL)) OR ("notSaved" IS FALSE)))
);


ALTER TABLE public."SessionFacility" OWNER TO pgsync;

--
-- TOC entry 266 (class 1259 OID 18076)
-- Name: size_category_sequence; Type: SEQUENCE; Schema: public; Owner: pgsync
--

CREATE SEQUENCE public.size_category_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.size_category_sequence OWNER TO pgsync;

--
-- TOC entry 267 (class 1259 OID 18077)
-- Name: SizeCategory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SizeCategory" (
    "sizeCategoryID" integer DEFAULT nextval('public.size_category_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT sizecategoryid_positive CHECK (("sizeCategoryID" >= 0))
);


ALTER TABLE public."SizeCategory" OWNER TO pgsync;

--
-- TOC entry 268 (class 1259 OID 18082)
-- Name: storage_type_sequence; Type: SEQUENCE; Schema: public; Owner: pgsync
--

CREATE SEQUENCE public.storage_type_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.storage_type_sequence OWNER TO pgsync;

--
-- TOC entry 269 (class 1259 OID 18083)
-- Name: Software; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Software" (
    "softwareID" smallint DEFAULT nextval('public.storage_type_sequence'::regclass) NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public."Software" OWNER TO pgsync;

--
-- TOC entry 270 (class 1259 OID 18089)
-- Name: StorageType; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."StorageType" (
    "storageTypeID" integer DEFAULT nextval('public.storage_type_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT storagetypeid_positive CHECK (("storageTypeID" > 0))
);


ALTER TABLE public."StorageType" OWNER TO pgsync;

--
-- TOC entry 271 (class 1259 OID 18094)
-- Name: StorageTypeMatch; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."StorageTypeMatch" (
    "storageTypeMatchID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    description character varying NOT NULL,
    features json,
    "synchronizationConfigID" uuid NOT NULL,
    "storageTypeID" character varying NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public."StorageTypeMatch" OWNER TO pgsync;

--
-- TOC entry 272 (class 1259 OID 18101)
-- Name: SuperArea1; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SuperArea1" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."SuperArea1" OWNER TO pgsync;

--
-- TOC entry 273 (class 1259 OID 18107)
-- Name: SuperArea2; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SuperArea2" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."SuperArea2" OWNER TO pgsync;

--
-- TOC entry 274 (class 1259 OID 18113)
-- Name: SynchronizationConfig; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."SynchronizationConfig" (
    "synchronizationConfigID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config json NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    "integrationSchema" json NOT NULL,
    "softwareID" smallint NOT NULL,
    "inboundKey" character varying(15) DEFAULT concat('CS-', upper(substr((public.uuid_generate_v4())::text, 25))) NOT NULL
);


ALTER TABLE public."SynchronizationConfig" OWNER TO pgsync;

--
-- TOC entry 275 (class 1259 OID 18121)
-- Name: Tag; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Tag" (
    description character varying(255) NOT NULL,
    "tagID" smallint NOT NULL
);


ALTER TABLE public."Tag" OWNER TO pgsync;

--
-- TOC entry 276 (class 1259 OID 18124)
-- Name: Unit; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."Unit" (
    "unitID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "sizeCategoryID" smallint,
    covered boolean DEFAULT false NOT NULL,
    "carAccess" boolean DEFAULT false NOT NULL,
    heating boolean DEFAULT false NOT NULL,
    "heatedFloor" boolean DEFAULT false NOT NULL,
    "airConditioning" boolean DEFAULT false NOT NULL,
    "noStairs" boolean DEFAULT false NOT NULL,
    "electronicKey" boolean DEFAULT false NOT NULL,
    h24 boolean DEFAULT false NOT NULL,
    width numeric(10,2) NOT NULL,
    length numeric(10,2) NOT NULL,
    height numeric(10,2) DEFAULT 2.5,
    "floorNb" smallint DEFAULT 0,
    "narrowestPassage" numeric(10,2),
    "regularPrice" numeric(10,2),
    "discountedPrice" numeric(10,2),
    motorcycle boolean DEFAULT false NOT NULL,
    car boolean DEFAULT false NOT NULL,
    rv boolean DEFAULT false NOT NULL,
    boat boolean DEFAULT false NOT NULL,
    "facilityTypeID" uuid NOT NULL,
    "rentalDeposit" smallint,
    "accessCode" boolean DEFAULT false NOT NULL,
    "possiblyVehicle" boolean DEFAULT false NOT NULL,
    outdoor boolean DEFAULT false NOT NULL,
    snowmobile boolean DEFAULT false NOT NULL,
    trailer boolean DEFAULT false NOT NULL,
    visible boolean DEFAULT true NOT NULL,
    "externalID" character varying(255),
    available boolean DEFAULT true NOT NULL,
    archived boolean DEFAULT false NOT NULL,
    electricity boolean DEFAULT false NOT NULL,
    CONSTRAINT archived_or_visible CHECK ((((archived IS TRUE) AND (visible IS FALSE)) OR (archived IS FALSE))),
    CONSTRAINT discountedprice_positive CHECK (("discountedPrice" > (0)::numeric)),
    CONSTRAINT height_positive CHECK ((height > (0)::numeric)),
    CONSTRAINT lenght_positive CHECK ((length > (0)::numeric)),
    CONSTRAINT length_superior_than_width CHECK ((length >= width)),
    CONSTRAINT narrowestpassage_positive CHECK (("narrowestPassage" > (0)::numeric)),
    CONSTRAINT price_order CHECK ((("discountedPrice" IS NULL) OR ("discountedPrice" < "regularPrice"))),
    CONSTRAINT regularprice_positive CHECK (("regularPrice" > (0)::numeric)),
    CONSTRAINT width_positive CHECK ((width > (0)::numeric))
);


ALTER TABLE public."Unit" OWNER TO pgsync;

--
-- TOC entry 277 (class 1259 OID 18160)
-- Name: UnitArchivalHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."UnitArchivalHistory" (
    "unitArchivalHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    archived boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."UnitArchivalHistory" OWNER TO pgsync;

--
-- TOC entry 278 (class 1259 OID 18165)
-- Name: UnitAvailabilityHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."UnitAvailabilityHistory" (
    "unitID" uuid NOT NULL,
    available boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "unitAvailabilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


ALTER TABLE public."UnitAvailabilityHistory" OWNER TO pgsync;

--
-- TOC entry 279 (class 1259 OID 18170)
-- Name: UnitDiscount; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."UnitDiscount" (
    "discountID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


ALTER TABLE public."UnitDiscount" OWNER TO pgsync;

--
-- TOC entry 280 (class 1259 OID 18175)
-- Name: UnitPriceHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."UnitPriceHistory" (
    "unitPriceHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    "newPrice" numeric(10,2),
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "priceType" character varying(255) DEFAULT 'regular'::character varying NOT NULL
);


ALTER TABLE public."UnitPriceHistory" OWNER TO pgsync;

--
-- TOC entry 281 (class 1259 OID 18181)
-- Name: UnitVisibilityHistory; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."UnitVisibilityHistory" (
    "unitVisibilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    visible boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."UnitVisibilityHistory" OWNER TO pgsync;

--
-- TOC entry 282 (class 1259 OID 18186)
-- Name: ValidationCode; Type: TABLE; Schema: public; Owner: pgsync
--

CREATE TABLE public."ValidationCode" (
    "validationCodeID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "userID" uuid NOT NULL,
    "expirationTime" timestamp without time zone NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    code character varying(4) NOT NULL,
    method character varying(255) NOT NULL,
    "phoneNumber" character varying(255),
    email character varying(255),
    "placeID" character varying(255),
    "remainingTrials" smallint DEFAULT 3 NOT NULL,
    CONSTRAINT expiration_greater_than_creation CHECK (("expirationTime" > date))
);


ALTER TABLE public."ValidationCode" OWNER TO pgsync;

--
-- TOC entry 4543 (class 0 OID 0)
-- Name: AccessHours; Type: TABLE ATTACH; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."OpeningHours" ATTACH PARTITION public."AccessHours" FOR VALUES IN ('access');


--
-- TOC entry 4544 (class 0 OID 0)
-- Name: Neighborhood; Type: TABLE ATTACH; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."Neighborhood" FOR VALUES IN ('neighborhood');


--
-- TOC entry 4545 (class 0 OID 0)
-- Name: OfficeHours; Type: TABLE ATTACH; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."OpeningHours" ATTACH PARTITION public."OfficeHours" FOR VALUES IN ('office');


--
-- TOC entry 4546 (class 0 OID 0)
-- Name: SuperArea1; Type: TABLE ATTACH; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."SuperArea1" FOR VALUES IN ('superArea1');


--
-- TOC entry 4547 (class 0 OID 0)
-- Name: SuperArea2; Type: TABLE ATTACH; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."SuperArea2" FOR VALUES IN ('superArea2');


--
-- TOC entry 4846 (class 2606 OID 18196)
-- Name: OpeningHours OpeningHours_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."OpeningHours"
    ADD CONSTRAINT "OpeningHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4848 (class 2606 OID 18200)
-- Name: AccessHours AccessHours_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."AccessHours"
    ADD CONSTRAINT "AccessHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4850 (class 2606 OID 18207)
-- Name: AdAccessRequest AdAccessRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."AdAccessRequest"
    ADD CONSTRAINT "AdAccessRequest_pkey" PRIMARY KEY ("adAccessRequestID");


--
-- TOC entry 4861 (class 2606 OID 18213)
-- Name: BookingCall BookingCall_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_pkey" PRIMARY KEY ("bookingID", "callID");


--
-- TOC entry 4865 (class 2606 OID 18222)
-- Name: BookingReason BookingReason_description_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingReason"
    ADD CONSTRAINT "BookingReason_description_key" UNIQUE (description);


--
-- TOC entry 4867 (class 2606 OID 18226)
-- Name: BookingReason BookingReason_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingReason"
    ADD CONSTRAINT "BookingReason_pkey" PRIMARY KEY ("bookingReasonID");


--
-- TOC entry 4856 (class 2606 OID 18230)
-- Name: Booking Booking_facilityBookingID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_facilityBookingID_key" UNIQUE ("facilityBookingID");


--
-- TOC entry 4869 (class 2606 OID 18236)
-- Name: Call Call_callAnalyticsJobName_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_callAnalyticsJobName_key" UNIQUE ("recordingID");


--
-- TOC entry 4871 (class 2606 OID 18241)
-- Name: Call Call_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_pkey" PRIMARY KEY ("callID");


--
-- TOC entry 4893 (class 2606 OID 18245)
-- Name: Email Email_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_pkey" PRIMARY KEY ("emailID");


--
-- TOC entry 4895 (class 2606 OID 18247)
-- Name: EpicenterCity EpicenterCity_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT "EpicenterCity_pkey" PRIMARY KEY ("epicenterCityID");


--
-- TOC entry 4907 (class 2606 OID 18252)
-- Name: FacilityEmail FacilityEmail_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityEmail"
    ADD CONSTRAINT "FacilityEmail_pkey" PRIMARY KEY ("facilityID", email);


--
-- TOC entry 4909 (class 2606 OID 18257)
-- Name: FacilityEvent FacilityEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityEvent"
    ADD CONSTRAINT "FacilityEvent_pkey" PRIMARY KEY ("facilityEventID");


--
-- TOC entry 4913 (class 2606 OID 18265)
-- Name: FacilityPhoneNumber FacilityPhoneNumber_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityPhoneNumber"
    ADD CONSTRAINT "FacilityPhoneNumber_pkey" PRIMARY KEY ("facilityID", "phoneNumber");


--
-- TOC entry 4915 (class 2606 OID 18268)
-- Name: FacilityTag FacilityTag_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_pkey" PRIMARY KEY ("tagID", "facilityID");


--
-- TOC entry 4921 (class 2606 OID 18272)
-- Name: FacilityUser FacilityUser_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityUser"
    ADD CONSTRAINT "FacilityUser_pkey" PRIMARY KEY ("userID", "facilityID");


--
-- TOC entry 4923 (class 2606 OID 18276)
-- Name: FocusSession FocusSession_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FocusSession"
    ADD CONSTRAINT "FocusSession_pkey" PRIMARY KEY ("focusSessionID");


--
-- TOC entry 4927 (class 2606 OID 18279)
-- Name: InfoVerifiedHistory InfoVerifiedHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."InfoVerifiedHistory"
    ADD CONSTRAINT "InfoVerifiedHistory_pkey" PRIMARY KEY ("infoVerifiedHistoryID");


--
-- TOC entry 4933 (class 2606 OID 18281)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_date_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_date_key" UNIQUE ("maskedPhoneNumber", date);


--
-- TOC entry 4935 (class 2606 OID 18283)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_pkey" PRIMARY KEY ("maskedPhoneNumberAvailabilityHistoryID");


--
-- TOC entry 4931 (class 2606 OID 18285)
-- Name: MaskedPhoneNumber MaskedPhoneNumber_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."MaskedPhoneNumber"
    ADD CONSTRAINT "MaskedPhoneNumber_pkey" PRIMARY KEY ("maskedPhoneNumber");


--
-- TOC entry 4941 (class 2606 OID 18287)
-- Name: Neighborhood Neighborhood_regionID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhood_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4937 (class 2606 OID 18289)
-- Name: Region Region_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Region"
    ADD CONSTRAINT "Region_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4943 (class 2606 OID 18291)
-- Name: Neighborhood Neighborhoodd_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhoodd_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4939 (class 2606 OID 18293)
-- Name: Region region_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Region"
    ADD CONSTRAINT region_unique UNIQUE ("placeID", type);


--
-- TOC entry 4945 (class 2606 OID 18295)
-- Name: Neighborhood Neighborhoodd_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhoodd_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4947 (class 2606 OID 18297)
-- Name: NewsletterMember NewsletterMember_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."NewsletterMember"
    ADD CONSTRAINT "NewsletterMember_pkey" PRIMARY KEY ("memberID");


--
-- TOC entry 4951 (class 2606 OID 18299)
-- Name: Note Note_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Note"
    ADD CONSTRAINT "Note_pkey" PRIMARY KEY ("noteID");


--
-- TOC entry 4953 (class 2606 OID 18301)
-- Name: OfficeHours OfficeHours_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."OfficeHours"
    ADD CONSTRAINT "OfficeHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4965 (class 2606 OID 18303)
-- Name: SearchedCity SearchedCity_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SearchedCity"
    ADD CONSTRAINT "SearchedCity_pkey" PRIMARY KEY ("searchedCityID");


--
-- TOC entry 4969 (class 2606 OID 18305)
-- Name: SessionFacility SessionFacility_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "SessionFacility_pkey" PRIMARY KEY ("sessionFacilityID");


--
-- TOC entry 4967 (class 2606 OID 18307)
-- Name: Session Session_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Session"
    ADD CONSTRAINT "Session_pkey" PRIMARY KEY ("sessionID");


--
-- TOC entry 4973 (class 2606 OID 18309)
-- Name: Software Software_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Software"
    ADD CONSTRAINT "Software_pkey" PRIMARY KEY ("softwareID");


--
-- TOC entry 4979 (class 2606 OID 18311)
-- Name: StorageTypeMatch StorageTypeMatch_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_pkey" PRIMARY KEY ("storageTypeMatchID");


--
-- TOC entry 4981 (class 2606 OID 18313)
-- Name: StorageTypeMatch StorageTypeMatch_storageTypeID_synchronizationConfigID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_storageTypeID_synchronizationConfigID_key" UNIQUE ("storageTypeID", "synchronizationConfigID");


--
-- TOC entry 4975 (class 2606 OID 18315)
-- Name: StorageType StorageType_description_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."StorageType"
    ADD CONSTRAINT "StorageType_description_key" UNIQUE (description);


--
-- TOC entry 4983 (class 2606 OID 18317)
-- Name: SuperArea1 SuperArea1_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4985 (class 2606 OID 18319)
-- Name: SuperArea1 SuperArea1_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4987 (class 2606 OID 18321)
-- Name: SuperArea1 SuperArea1_regionID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4989 (class 2606 OID 18323)
-- Name: SuperArea2 SuperArea2_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4991 (class 2606 OID 18325)
-- Name: SuperArea2 SuperArea2_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4993 (class 2606 OID 18327)
-- Name: SuperArea2 SuperArea2_regionID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4995 (class 2606 OID 18329)
-- Name: SynchronizationConfig SynchronizationConfig_inboundKey_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_inboundKey_key" UNIQUE ("inboundKey");


--
-- TOC entry 4997 (class 2606 OID 18331)
-- Name: SynchronizationConfig SynchronizationConfig_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_pkey" PRIMARY KEY ("synchronizationConfigID");


--
-- TOC entry 5007 (class 2606 OID 18333)
-- Name: UnitArchivalHistory UnitArchivalHistory_date_unitID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_date_unitID_key" UNIQUE (date, "unitID");


--
-- TOC entry 5009 (class 2606 OID 18335)
-- Name: UnitArchivalHistory UnitArchivalHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_pkey" PRIMARY KEY ("unitArchivalHistoryID");


--
-- TOC entry 5011 (class 2606 OID 18337)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_pkey" PRIMARY KEY ("unitAvailabilityHistoryID");


--
-- TOC entry 5013 (class 2606 OID 18339)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_unitID_date_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_unitID_date_key" UNIQUE ("unitID", date);


--
-- TOC entry 5017 (class 2606 OID 18341)
-- Name: UnitPriceHistory UnitPriceHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_pkey" PRIMARY KEY ("unitPriceHistoryID");


--
-- TOC entry 5019 (class 2606 OID 18343)
-- Name: UnitPriceHistory UnitPriceHistory_unitID_date_priceType_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_unitID_date_priceType_key" UNIQUE ("unitID", date, "priceType");


--
-- TOC entry 5021 (class 2606 OID 18345)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_date_unitID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_date_unitID_key" UNIQUE (date, "unitID");


--
-- TOC entry 5023 (class 2606 OID 18347)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_pkey" PRIMARY KEY ("unitVisibilityHistoryID");


--
-- TOC entry 5001 (class 2606 OID 18349)
-- Name: Unit Unit_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT "Unit_pkey" PRIMARY KEY ("unitID");


--
-- TOC entry 5025 (class 2606 OID 18351)
-- Name: ValidationCode ValidationCode_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."ValidationCode"
    ADD CONSTRAINT "ValidationCode_pkey" PRIMARY KEY ("validationCodeID");


--
-- TOC entry 4746 (class 2606 OID 18352)
-- Name: Booking abortionSource_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "abortionSource_valid" CHECK ((("abortionSource" IS NULL) OR (("abortionSource")::text = 'call'::text) OR (("abortionSource")::text = 'sms'::text) OR (("abortionSource")::text = 'email'::text) OR (("abortionSource")::text = 'customer'::text) OR (("abortionSource")::text = 'facility'::text))) NOT VALID;


--
-- TOC entry 4814 (class 2606 OID 18353)
-- Name: MaskedPhoneNumber active_or_unavailable; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."MaskedPhoneNumber"
    ADD CONSTRAINT active_or_unavailable CHECK (((active IS TRUE) OR (available IS FALSE))) NOT VALID;


--
-- TOC entry 4852 (class 2606 OID 18355)
-- Name: Address address_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT address_pkey PRIMARY KEY ("addressID");


--
-- TOC entry 4854 (class 2606 OID 18357)
-- Name: Address address_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT address_unique UNIQUE ("streetName", "streetNumber", "postalCodeID");


--
-- TOC entry 4766 (class 2606 OID 18358)
-- Name: Call agentSentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "agentSentiment_interval" CHECK ((("agentSentiment" >= ('-5'::integer)::numeric) AND ("agentSentiment" <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4747 (class 2606 OID 18359)
-- Name: Booking approved_or_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT approved_or_refused CHECK ((((approved IS TRUE) AND (refused IS FALSE)) OR ((approved IS FALSE) AND (refused IS TRUE)) OR ((approved IS FALSE) AND (refused IS FALSE)))) NOT VALID;


--
-- TOC entry 4787 (class 2606 OID 18360)
-- Name: Email booking_confirmed_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Email"
    ADD CONSTRAINT booking_confirmed_or_aborted CHECK (((("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS TRUE)) OR (("bookingAborted" IS TRUE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS FALSE)))) NOT VALID;


--
-- TOC entry 4767 (class 2606 OID 18361)
-- Name: Call booking_confirmed_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT booking_confirmed_or_aborted CHECK (((("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS TRUE)) OR (("bookingAborted" IS TRUE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS NULL) AND ("bookingConfirmed" IS NULL)))) NOT VALID;


--
-- TOC entry 4858 (class 2606 OID 18363)
-- Name: Booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT booking_pkey PRIMARY KEY ("bookingID");


--
-- TOC entry 4788 (class 2606 OID 18364)
-- Name: Email bounced_and_not_in_spam; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Email"
    ADD CONSTRAINT bounced_and_not_in_spam CHECK (((bounced IS FALSE) OR ("inSpam" IS FALSE))) NOT VALID;


--
-- TOC entry 4873 (class 2606 OID 18366)
-- Name: City city_areas; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT city_areas UNIQUE ("superArea1ID", "superArea2ID", name);


--
-- TOC entry 4875 (class 2606 OID 18368)
-- Name: City city_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT city_pkey PRIMARY KEY ("cityID");


--
-- TOC entry 4877 (class 2606 OID 18370)
-- Name: City city_placeID_key; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "city_placeID_key" UNIQUE ("placeID");


--
-- TOC entry 4897 (class 2606 OID 18372)
-- Name: EpicenterCity cityid_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT cityid_unique UNIQUE ("cityID");


--
-- TOC entry 4881 (class 2606 OID 18374)
-- Name: Currency code_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Currency"
    ADD CONSTRAINT code_unique UNIQUE (code);


--
-- TOC entry 4903 (class 2606 OID 18376)
-- Name: FacilityDiscount conf_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT conf_unique UNIQUE ("discountID", "sizeCategoryID", "storageTypeID");


--
-- TOC entry 4748 (class 2606 OID 18377)
-- Name: Booking confirmationSource_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "confirmationSource_valid" CHECK ((("confirmationSource" IS NULL) OR (("confirmationSource")::text = 'call'::text) OR (("confirmationSource")::text = 'sms'::text) OR (("confirmationSource")::text = 'email'::text) OR (("confirmationSource")::text = 'facility'::text) OR (("confirmationSource")::text = 'customer'::text))) NOT VALID;


--
-- TOC entry 4879 (class 2606 OID 18379)
-- Name: Country country_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT country_pkey PRIMARY KEY ("countryID");


--
-- TOC entry 4883 (class 2606 OID 18381)
-- Name: Currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Currency"
    ADD CONSTRAINT currency_pkey PRIMARY KEY ("currencyID");


--
-- TOC entry 4770 (class 2606 OID 18382)
-- Name: Call customerSentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "customerSentiment_interval" CHECK ((("customerSentiment" >= ('-5'::integer)::numeric) AND ("customerSentiment" <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4885 (class 2606 OID 18384)
-- Name: Customer customer_email_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT customer_email_unique UNIQUE (email);


--
-- TOC entry 4887 (class 2606 OID 18386)
-- Name: Customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT customer_pkey PRIMARY KEY ("customerID");


--
-- TOC entry 4749 (class 2606 OID 18387)
-- Name: Booking dateAborted_null_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateAborted_null_or_aborted" CHECK ((((aborted IS FALSE) AND ("dateAborted" IS NULL) AND ("abortionSource" IS NULL)) OR ((aborted IS TRUE) AND ("dateAborted" IS NOT NULL) AND ("abortionSource" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4750 (class 2606 OID 18388)
-- Name: Booking dateApproved_null_or_approved; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateApproved_null_or_approved" CHECK ((((approved IS FALSE) AND ("dateApproved" IS NULL)) OR ((approved IS TRUE) AND ("dateApproved" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4751 (class 2606 OID 18389)
-- Name: Booking dateCanceled_null_or_canceled; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateCanceled_null_or_canceled" CHECK ((((canceled IS FALSE) AND ("dateCanceled" IS NULL) AND ("cancelReason" IS NULL)) OR ((canceled IS TRUE) AND ("dateCanceled" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4752 (class 2606 OID 18390)
-- Name: Booking dateConfirmed_null_or_confirmed; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateConfirmed_null_or_confirmed" CHECK ((((confirmed IS FALSE) AND ("dateConfirmed" IS NULL) AND ("confirmationSource" IS NULL)) OR ((confirmed IS TRUE) AND ("dateConfirmed" IS NOT NULL) AND ("confirmationSource" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4753 (class 2606 OID 18391)
-- Name: Booking dateExpired_null_or_expired; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateExpired_null_or_expired" CHECK ((((expired IS FALSE) AND ("dateExpired" IS NULL)) OR ((expired IS TRUE) AND ("dateExpired" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4754 (class 2606 OID 18392)
-- Name: Booking dateRefused_null_or_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateRefused_null_or_refused" CHECK ((((refused IS FALSE) AND ("dateRefused" IS NULL) AND ("refusalReason" IS NULL)) OR ((refused IS TRUE) AND ("dateRefused" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4755 (class 2606 OID 18393)
-- Name: Booking date_order; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT date_order CHECK (((date < "moveInDate") AND ("moveInDate" <= "endDate") AND ("dateCanceled" > date) AND ("dateConfirmed" > date) AND ("dateExpired" > date))) NOT VALID;


--
-- TOC entry 4889 (class 2606 OID 18395)
-- Name: Discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT discount_pkey PRIMARY KEY ("discountID");


--
-- TOC entry 4891 (class 2606 OID 18397)
-- Name: Discount discount_title_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT discount_title_unique UNIQUE (title, "facilityID");


--
-- TOC entry 4863 (class 2606 OID 18399)
-- Name: BookingDiscount discountofbooking_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT discountofbooking_pkey PRIMARY KEY ("discountID", "bookingID");


--
-- TOC entry 4839 (class 2606 OID 18400)
-- Name: ValidationCode email_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text)) NOT VALID;


--
-- TOC entry 4949 (class 2606 OID 18402)
-- Name: NewsletterMember email_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."NewsletterMember"
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- TOC entry 4771 (class 2606 OID 18403)
-- Name: Call endTime_greater_than_startTime; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "endTime_greater_than_startTime" CHECK ((("endTime" IS NULL) OR ("endTime" >= "startTime"))) NOT VALID;


--
-- TOC entry 4911 (class 2606 OID 18405)
-- Name: FacilityImage facility_image_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT facility_image_unique PRIMARY KEY ("facilityID", "imageID");


--
-- TOC entry 4899 (class 2606 OID 18407)
-- Name: Facility facility_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT facility_pkey PRIMARY KEY ("facilityID");


--
-- TOC entry 4905 (class 2606 OID 18409)
-- Name: FacilityDiscount facilitydiscount_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT facilitydiscount_pkey PRIMARY KEY ("facilityDiscountID");


--
-- TOC entry 4917 (class 2606 OID 18411)
-- Name: FacilityType facilitytype_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT facilitytype_pkey PRIMARY KEY ("facilityTypeID");


--
-- TOC entry 4829 (class 2606 OID 18412)
-- Name: StorageTypeMatch features_or_inactive; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."StorageTypeMatch"
    ADD CONSTRAINT features_or_inactive CHECK (((features IS NOT NULL) OR (active IS FALSE))) NOT VALID;


--
-- TOC entry 4925 (class 2606 OID 18414)
-- Name: Image image_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Image"
    ADD CONSTRAINT image_pkey PRIMARY KEY ("imageID");


--
-- TOC entry 4790 (class 2606 OID 18415)
-- Name: Email initiator_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Email"
    ADD CONSTRAINT initiator_dependence CHECK (((((initiator)::text = 'customer'::text) IS TRUE) OR (("bookingReasonID" IS NULL) AND ("contactInfoShared" IS NOT TRUE) AND ("storedItems" IS NULL)))) NOT VALID;


--
-- TOC entry 4772 (class 2606 OID 18416)
-- Name: Call initiator_value; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT initiator_value CHECK ((((initiator)::text = 'customer'::text) OR ((initiator)::text = 'facility'::text))) NOT VALID;


--
-- TOC entry 4929 (class 2606 OID 18418)
-- Name: Insurance insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Insurance"
    ADD CONSTRAINT insurance_pkey PRIMARY KEY ("facilityTypeID", "monthlyFee", coverage);


--
-- TOC entry 4757 (class 2606 OID 18419)
-- Name: Booking isRequest_or_not_approved; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "isRequest_or_not_approved" CHECK ((("isRequest" IS TRUE) OR ((approved IS FALSE) AND ("dateApproved" IS NULL)))) NOT VALID;


--
-- TOC entry 4758 (class 2606 OID 18420)
-- Name: Booking isRequest_or_not_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "isRequest_or_not_refused" CHECK ((("isRequest" IS TRUE) OR ((refused IS FALSE) AND ("dateRefused" IS NULL)))) NOT VALID;


--
-- TOC entry 4773 (class 2606 OID 18421)
-- Name: Call language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4796 (class 2606 OID 18422)
-- Name: Facility language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Facility"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4783 (class 2606 OID 18423)
-- Name: Customer language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4815 (class 2606 OID 18424)
-- Name: NewsletterMember language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."NewsletterMember"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4774 (class 2606 OID 18425)
-- Name: Call leftMessage_or_unanswered; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "leftMessage_or_unanswered" CHECK ((("leftMessage" IS FALSE) OR (((status)::text = 'unanswered'::text) OR (((status)::text = 'busy'::text) AND (voicemail IS TRUE))))) NOT VALID;


--
-- TOC entry 4780 (class 2606 OID 18426)
-- Name: Country measurementSystem_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Country"
    ADD CONSTRAINT "measurementSystem_valid" CHECK (((("measurementSystem")::text = 'metric'::text) OR (("measurementSystem")::text = 'imperial'::text))) NOT VALID;


--
-- TOC entry 4784 (class 2606 OID 18427)
-- Name: Customer measurementSystem_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT "measurementSystem_valid" CHECK (((("measurementSystem")::text = 'metric'::text) OR (("measurementSystem")::text = 'imperial'::text))) NOT VALID;


--
-- TOC entry 4759 (class 2606 OID 18428)
-- Name: Booking not_contactInfoShared_or_not_phoneNumberActive; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "not_contactInfoShared_or_not_phoneNumberActive" CHECK ((("contactInfoShared" IS FALSE) OR ("phoneNumberActive" IS FALSE))) NOT VALID;


--
-- TOC entry 4775 (class 2606 OID 18429)
-- Name: Call outputReason_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "outputReason_dependence" CHECK ((("outputReason" IS NOT NULL) OR ((("bookingConfirmed" IS NULL) AND ("contactInfoShared" IS NULL)) OR (voicemail IS TRUE)))) NOT VALID;


--
-- TOC entry 4761 (class 2606 OID 18430)
-- Name: Booking pending_or_expired_or_confirmed_or_refused_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT pending_or_expired_or_confirmed_or_refused_or_aborted CHECK ((((pending IS TRUE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS TRUE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS TRUE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS TRUE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS TRUE)))) NOT VALID;


--
-- TOC entry 4762 (class 2606 OID 18431)
-- Name: Booking phoneNumberActive_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "phoneNumberActive_dependence" CHECK ((("phoneNumberActive" IS FALSE) OR ((confirmed IS FALSE) AND (canceled IS FALSE) AND (expired IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)))) NOT VALID;


--
-- TOC entry 4800 (class 2606 OID 18432)
-- Name: FacilityPhoneNumber phoneNumber_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."FacilityPhoneNumber"
    ADD CONSTRAINT "phoneNumber_format" CHECK ((("phoneNumber")::text ~ '^\+'::text)) NOT VALID;


--
-- TOC entry 4785 (class 2606 OID 18433)
-- Name: Customer phoneNumber_format; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT "phoneNumber_format" CHECK ((("phoneNumber")::text ~ '^\+'::text)) NOT VALID;


--
-- TOC entry 4841 (class 2606 OID 18434)
-- Name: ValidationCode phoneNumber_or_email; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT "phoneNumber_or_email" CHECK ((("phoneNumber" IS NOT NULL) OR (email IS NOT NULL))) NOT VALID;


--
-- TOC entry 4786 (class 2606 OID 18435)
-- Name: Customer phone_number_dependencies; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT phone_number_dependencies CHECK (((("phoneNumber" IS NULL) AND ("formattedPhoneNumber" IS NULL) AND ("dialCode" IS NULL)) OR (("phoneNumber" IS NOT NULL) AND ("formattedPhoneNumber" IS NOT NULL) AND ("dialCode" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4955 (class 2606 OID 18437)
-- Name: PostalCode placeID_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT "placeID_unique" UNIQUE ("placeID");


--
-- TOC entry 4901 (class 2606 OID 18439)
-- Name: Facility placeid_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT placeid_unique UNIQUE ("placeID");


--
-- TOC entry 4957 (class 2606 OID 18441)
-- Name: PostalCode postal_code_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT postal_code_unique UNIQUE ("postalCode", "cityID");


--
-- TOC entry 4959 (class 2606 OID 18443)
-- Name: PostalCode postalcode_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT postalcode_pkey PRIMARY KEY ("postalCodeID");


--
-- TOC entry 5003 (class 2606 OID 18445)
-- Name: Unit price_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT price_unique UNIQUE NULLS NOT DISTINCT (covered, "carAccess", heating, "heatedFloor", "airConditioning", "noStairs", "electronicKey", h24, width, length, height, "floorNb", "narrowestPassage", motorcycle, car, rv, boat, "facilityTypeID", "rentalDeposit", "accessCode", "possiblyVehicle", outdoor, snowmobile, trailer, electricity, "externalID");


--
-- TOC entry 4776 (class 2606 OID 18446)
-- Name: Call recording_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT recording_dependence CHECK ((("recordingID" IS NOT NULL) OR (("leftMessage" IS FALSE) AND ("customerSentiment" IS NULL) AND ("agentSentiment" IS NULL) AND ("bookingConfirmed" IS NULL) AND ("outputReason" IS NULL) AND ("contactInfoShared" IS NULL)))) NOT VALID;


--
-- TOC entry 4842 (class 2606 OID 18447)
-- Name: ValidationCode remainingTrials_below_3; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT "remainingTrials_below_3" CHECK (("remainingTrials" <= 3)) NOT VALID;


--
-- TOC entry 4961 (class 2606 OID 18449)
-- Name: Reminder reminder_pk; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT reminder_pk PRIMARY KEY ("reminderID");


--
-- TOC entry 4793 (class 2606 OID 18450)
-- Name: Email sentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Email"
    ADD CONSTRAINT sentiment_interval CHECK (((sentiment >= ('-5'::integer)::numeric) AND (sentiment <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4971 (class 2606 OID 18452)
-- Name: SizeCategory sizecategory_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SizeCategory"
    ADD CONSTRAINT sizecategory_pkey PRIMARY KEY ("sizeCategoryID");


--
-- TOC entry 4777 (class 2606 OID 18453)
-- Name: Call status_value; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT status_value CHECK ((((status)::text = 'ongoing'::text) OR ((status)::text = 'answered'::text) OR ((status)::text = 'unanswered'::text))) NOT VALID;


--
-- TOC entry 4977 (class 2606 OID 18455)
-- Name: StorageType storagetype_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."StorageType"
    ADD CONSTRAINT storagetype_pkey PRIMARY KEY ("storageTypeID");


--
-- TOC entry 4999 (class 2606 OID 18457)
-- Name: Tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Tag"
    ADD CONSTRAINT tag_pkey PRIMARY KEY ("tagID");


--
-- TOC entry 4778 (class 2606 OID 18458)
-- Name: Call twilioCallID_different_from_twilioParentCallID; Type: CHECK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "twilioCallID_different_from_twilioParentCallID" CHECK ((("twilioCallID")::text <> ("twilioParentCallID")::text)) NOT VALID;


--
-- TOC entry 4919 (class 2606 OID 18460)
-- Name: FacilityType type_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT type_unique UNIQUE ("facilityID", "storageTypeID");


--
-- TOC entry 5005 (class 2606 OID 18462)
-- Name: Unit unit_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT unit_unique UNIQUE NULLS NOT DISTINCT (covered, "carAccess", heating, "heatedFloor", "airConditioning", "noStairs", "electronicKey", h24, width, length, height, "floorNb", "narrowestPassage", "regularPrice", "discountedPrice", motorcycle, car, rv, boat, "facilityTypeID", "rentalDeposit", "accessCode", "possiblyVehicle", outdoor, snowmobile, trailer, electricity, "externalID");


--
-- TOC entry 5015 (class 2606 OID 18464)
-- Name: UnitDiscount unitdiscount_pkey; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT unitdiscount_pkey PRIMARY KEY ("discountID", "unitID");


--
-- TOC entry 4963 (class 2606 OID 18466)
-- Name: Reminder user_and_facility_unique; Type: CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT user_and_facility_unique UNIQUE ("userID", "facilityID");


--
-- TOC entry 4859 (class 1259 OID 18467)
-- Name: fki_unitid_fkey; Type: INDEX; Schema: public; Owner: pgsync
--

CREATE INDEX fki_unitid_fkey ON public."Booking" USING btree ("unitID");


--
-- TOC entry 5026 (class 0 OID 0)
-- Name: AccessHours_pkey; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public."OpeningHours_pkey" ATTACH PARTITION public."AccessHours_pkey";


--
-- TOC entry 5027 (class 0 OID 0)
-- Name: Neighborhoodd_pkey; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."Neighborhoodd_pkey";


--
-- TOC entry 5028 (class 0 OID 0)
-- Name: Neighborhoodd_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public.region_unique ATTACH PARTITION public."Neighborhoodd_placeID_type_key";


--
-- TOC entry 5029 (class 0 OID 0)
-- Name: OfficeHours_pkey; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public."OpeningHours_pkey" ATTACH PARTITION public."OfficeHours_pkey";


--
-- TOC entry 5030 (class 0 OID 0)
-- Name: SuperArea1_pkey; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."SuperArea1_pkey";


--
-- TOC entry 5031 (class 0 OID 0)
-- Name: SuperArea1_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public.region_unique ATTACH PARTITION public."SuperArea1_placeID_type_key";


--
-- TOC entry 5032 (class 0 OID 0)
-- Name: SuperArea2_pkey; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."SuperArea2_pkey";


--
-- TOC entry 5033 (class 0 OID 0)
-- Name: SuperArea2_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: pgsync
--

ALTER INDEX public.region_unique ATTACH PARTITION public."SuperArea2_placeID_type_key";


--
-- TOC entry 5096 (class 2620 OID 18468)
-- Name: Address address_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER address_replace_empty_strings BEFORE INSERT OR UPDATE OF "apartmentNumber", "streetNumber", "streetName" ON public."Address" FOR EACH ROW EXECUTE FUNCTION public.replace_address_empty_strings();


--
-- TOC entry 5097 (class 2620 OID 18469)
-- Name: Booking booking_check_is_request; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_check_is_request BEFORE INSERT OR UPDATE OF "unitID" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_booking_is_request();


--
-- TOC entry 5098 (class 2620 OID 18470)
-- Name: Booking booking_check_move_in_date; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_check_move_in_date BEFORE INSERT OR UPDATE OF "moveInDate" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_booking_move_in_date();


--
-- TOC entry 5099 (class 2620 OID 18471)
-- Name: Booking booking_check_primary_customer; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_check_primary_customer BEFORE INSERT OR UPDATE OF "primaryBookingID", "customerID" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_primary_booking_customer();


--
-- TOC entry 5100 (class 2620 OID 18472)
-- Name: Booking booking_copy_price_info; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_copy_price_info BEFORE INSERT ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.copy_price_info();


--
-- TOC entry 5101 (class 2620 OID 18473)
-- Name: Booking booking_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_delete_dependencies BEFORE DELETE ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.delete_booking_dependencies();


--
-- TOC entry 5102 (class 2620 OID 18474)
-- Name: Booking booking_insert_discounts; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_insert_discounts AFTER INSERT ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.insert_booking_discounts();


--
-- TOC entry 5103 (class 2620 OID 18475)
-- Name: Booking booking_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_replace_empty_strings BEFORE INSERT OR UPDATE OF "cancelReason", review ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.replace_booking_empty_strings();


--
-- TOC entry 5104 (class 2620 OID 18476)
-- Name: Booking booking_update_aborted; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_aborted BEFORE INSERT OR UPDATE OF aborted ON public."Booking" FOR EACH ROW WHEN ((new.aborted IS TRUE)) EXECUTE FUNCTION public.update_booking_aborted();


--
-- TOC entry 5105 (class 2620 OID 18477)
-- Name: Booking booking_update_approved; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_approved BEFORE INSERT OR UPDATE OF approved ON public."Booking" FOR EACH ROW WHEN ((new.approved IS TRUE)) EXECUTE FUNCTION public.update_booking_approved();


--
-- TOC entry 5106 (class 2620 OID 18478)
-- Name: Booking booking_update_canceled; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_canceled BEFORE INSERT OR UPDATE OF canceled ON public."Booking" FOR EACH ROW WHEN ((new.canceled IS TRUE)) EXECUTE FUNCTION public.update_booking_canceled();


--
-- TOC entry 5107 (class 2620 OID 18479)
-- Name: Booking booking_update_confirmed; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_confirmed BEFORE INSERT OR UPDATE OF confirmed ON public."Booking" FOR EACH ROW WHEN ((new.confirmed IS TRUE)) EXECUTE FUNCTION public.update_booking_confirmed();


--
-- TOC entry 5108 (class 2620 OID 18480)
-- Name: Booking booking_update_expired; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_expired BEFORE INSERT OR UPDATE OF expired ON public."Booking" FOR EACH ROW WHEN ((new.expired IS TRUE)) EXECUTE FUNCTION public.update_booking_expired();


--
-- TOC entry 5109 (class 2620 OID 18481)
-- Name: Booking booking_update_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_masked_phone_number_availability AFTER INSERT OR DELETE OR UPDATE OF "maskedPhoneNumber", "phoneNumberActive", expired, canceled, confirmed, refused, aborted ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.update_booking_masked_phone_number_availability();


--
-- TOC entry 5110 (class 2620 OID 18482)
-- Name: Booking booking_update_refused; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER booking_update_refused BEFORE INSERT OR UPDATE OF refused ON public."Booking" FOR EACH ROW WHEN ((new.refused IS TRUE)) EXECUTE FUNCTION public.update_booking_refused();


--
-- TOC entry 5112 (class 2620 OID 18483)
-- Name: Call call_add_bookings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER call_add_bookings AFTER INSERT ON public."Call" FOR EACH ROW WHEN (((new.called IS NOT NULL) AND (new.caller IS NOT NULL))) EXECUTE FUNCTION public.add_call_bookings();


--
-- TOC entry 5113 (class 2620 OID 18484)
-- Name: Call call_add_facility_id; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER call_add_facility_id BEFORE INSERT ON public."Call" FOR EACH ROW WHEN (((new.called IS NOT NULL) AND (new.caller IS NOT NULL))) EXECUTE FUNCTION public.add_call_facility_id();


--
-- TOC entry 5114 (class 2620 OID 18485)
-- Name: Call call_update_booking_status; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER call_update_booking_status AFTER INSERT OR UPDATE OF "bookingConfirmed", "contactInfoShared" ON public."Call" FOR EACH ROW WHEN (((new."bookingConfirmed" IS TRUE) OR (new."contactInfoShared" IS TRUE))) EXECUTE FUNCTION public.update_call_booking_status();


--
-- TOC entry 5115 (class 2620 OID 18486)
-- Name: Call call_update_end_time; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER call_update_end_time BEFORE INSERT OR UPDATE OF "endTime", status ON public."Call" FOR EACH ROW WHEN ((((new.status)::text = 'unanswered'::text) AND (new."endTime" IS NULL))) EXECUTE FUNCTION public.update_call_end_time();


--
-- TOC entry 5111 (class 2620 OID 18487)
-- Name: Booking check_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER check_masked_phone_number_availability BEFORE INSERT OR UPDATE OF "maskedPhoneNumber" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availabiity();


--
-- TOC entry 5116 (class 2620 OID 18488)
-- Name: City city_check_timezone; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER city_check_timezone BEFORE INSERT OR UPDATE OF timezone ON public."City" FOR EACH ROW EXECUTE FUNCTION public.check_timezone();


--
-- TOC entry 5117 (class 2620 OID 18489)
-- Name: City city_delete_independencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER city_delete_independencies AFTER DELETE ON public."City" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5118 (class 2620 OID 18490)
-- Name: Country country_delete_independencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER country_delete_independencies AFTER DELETE ON public."Country" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5119 (class 2620 OID 18491)
-- Name: Customer customer_add_to_newsletter; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER customer_add_to_newsletter AFTER INSERT ON public."Customer" FOR EACH ROW WHEN (((new.newsletter IS TRUE) AND (new.email IS NOT NULL))) EXECUTE FUNCTION public.add_customer_to_newsletter();


--
-- TOC entry 5120 (class 2620 OID 18492)
-- Name: Customer customer_update_newsletter_email; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER customer_update_newsletter_email AFTER UPDATE OF email ON public."Customer" FOR EACH ROW EXECUTE FUNCTION public.update_customer_newsletter_email();


--
-- TOC entry 5121 (class 2620 OID 18493)
-- Name: Customer customer_update_newsletter_language; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER customer_update_newsletter_language AFTER INSERT OR UPDATE OF language ON public."Customer" FOR EACH ROW EXECUTE FUNCTION public.update_customer_newsletter_language();


--
-- TOC entry 5122 (class 2620 OID 18494)
-- Name: Discount discount_check_activity; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER discount_check_activity BEFORE INSERT OR UPDATE ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.check_discount_activity();


--
-- TOC entry 5123 (class 2620 OID 18495)
-- Name: Discount discount_check_expiration_date; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER discount_check_expiration_date BEFORE INSERT OR UPDATE OF "expirationDate" ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.check_discount_expiration_date();


--
-- TOC entry 5124 (class 2620 OID 18496)
-- Name: Discount discount_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER discount_delete_dependencies BEFORE DELETE ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.delete_discount_dependencies();


--
-- TOC entry 5125 (class 2620 OID 18497)
-- Name: Discount discount_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER discount_replace_empty_strings BEFORE INSERT OR UPDATE OF terms ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.replace_discount_empty_strings();


--
-- TOC entry 5126 (class 2620 OID 18498)
-- Name: Email email_check_is_allowed; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER email_check_is_allowed BEFORE INSERT OR UPDATE OF allowed ON public."Email" FOR EACH ROW EXECUTE FUNCTION public.check_email_is_allowed();


--
-- TOC entry 5127 (class 2620 OID 18499)
-- Name: Email email_update_booking_confirmed; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER email_update_booking_confirmed BEFORE UPDATE OF "linkClicked" ON public."Email" FOR EACH ROW WHEN (((old."linkClicked" IS FALSE) AND (new."linkClicked" IS TRUE))) EXECUTE FUNCTION public.update_email_booking_confirmed();


--
-- TOC entry 5128 (class 2620 OID 18500)
-- Name: Email email_update_booking_status; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER email_update_booking_status AFTER INSERT OR UPDATE OF "bookingConfirmed", "contactInfoShared", "bookingAborted" ON public."Email" FOR EACH ROW WHEN (((new."bookingConfirmed" IS TRUE) OR (new."bookingAborted" IS TRUE) OR (new."contactInfoShared" IS TRUE))) EXECUTE FUNCTION public.update_email_booking_status();


--
-- TOC entry 5129 (class 2620 OID 18501)
-- Name: EpicenterCity epicenter_city_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER epicenter_city_delete_dependencies BEFORE DELETE ON public."EpicenterCity" FOR EACH ROW EXECUTE FUNCTION public.delete_epicenter_city_dependencies();


--
-- TOC entry 5130 (class 2620 OID 18502)
-- Name: EpicenterCity epicenter_city_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER epicenter_city_replace_empty_strings BEFORE INSERT OR UPDATE OF token ON public."EpicenterCity" FOR EACH ROW EXECUTE FUNCTION public.replace_epicenter_city_empty_strings();


--
-- TOC entry 5131 (class 2620 OID 18503)
-- Name: Facility epicenter_update_radius; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER epicenter_update_radius AFTER INSERT OR DELETE OR UPDATE OF "addressID", "epicenterCityID" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.update_epicenter_radius();


--
-- TOC entry 5132 (class 2620 OID 18504)
-- Name: Facility facility_add_last_update_time; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_add_last_update_time BEFORE INSERT OR UPDATE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.add_facility_last_update_time();


--
-- TOC entry 5133 (class 2620 OID 18505)
-- Name: Facility facility_add_short_title; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_add_short_title BEFORE INSERT OR UPDATE OF title, "shortTitle" ON public."Facility" FOR EACH ROW WHEN (((new.title IS NOT NULL) AND (new."shortTitle" IS NULL))) EXECUTE FUNCTION public.add_facility_short_title();


--
-- TOC entry 5134 (class 2620 OID 18506)
-- Name: Facility facility_check_info_verified_synchronization_config; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_info_verified_synchronization_config BEFORE INSERT OR UPDATE OF "infoVerified" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_info_verified_synchronization_config();


--
-- TOC entry 5135 (class 2620 OID 18507)
-- Name: Facility facility_check_masked_phone_number_and_partner; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_masked_phone_number_and_partner BEFORE INSERT OR UPDATE OF partner ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_masked_phone_number_and_partner();


--
-- TOC entry 5136 (class 2620 OID 18508)
-- Name: Facility facility_check_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_masked_phone_number_availability BEFORE INSERT OR UPDATE OF "maskedPhoneNumber" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availabiity();


--
-- TOC entry 5137 (class 2620 OID 18509)
-- Name: Facility facility_check_status; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_status BEFORE INSERT OR UPDATE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_status();


--
-- TOC entry 5174 (class 2620 OID 18510)
-- Name: SynchronizationConfig facility_check_synchronization; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_synchronization AFTER INSERT OR UPDATE OF enabled ON public."SynchronizationConfig" FOR EACH ROW WHEN ((new.enabled IS TRUE)) EXECUTE FUNCTION public.check_facility_synchronisation();


--
-- TOC entry 5138 (class 2620 OID 18511)
-- Name: Facility facility_check_title; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_check_title BEFORE INSERT OR UPDATE OF title ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_title();


--
-- TOC entry 5139 (class 2620 OID 18512)
-- Name: Facility facility_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_delete_dependencies BEFORE DELETE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.delete_facility_dependencies();


--
-- TOC entry 5143 (class 2620 OID 18513)
-- Name: FacilityDiscount facility_discount_check_activity; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE CONSTRAINT TRIGGER facility_discount_check_activity AFTER INSERT OR DELETE ON public."FacilityDiscount" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.check_facility_discount_activity();


--
-- TOC entry 5144 (class 2620 OID 18515)
-- Name: FacilityDiscount facility_discount_check_apparition; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_discount_check_apparition BEFORE INSERT OR UPDATE ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NULL) AND (new."storageTypeID" IS NULL))) EXECUTE FUNCTION public.check_facility_discount_apparition();


--
-- TOC entry 5145 (class 2620 OID 18516)
-- Name: FacilityDiscount facility_discount_insert_category; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_discount_insert_category AFTER INSERT OR UPDATE OF "sizeCategoryID", "storageTypeID" ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NOT NULL) OR (new."storageTypeID" IS NOT NULL))) EXECUTE FUNCTION public.check_others_for_category_discounts();


--
-- TOC entry 5146 (class 2620 OID 18517)
-- Name: FacilityDiscount facility_discount_insert_global; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_discount_insert_global AFTER INSERT OR UPDATE OF "sizeCategoryID", "storageTypeID" ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NULL) AND (new."storageTypeID" IS NULL))) EXECUTE FUNCTION public.check_others_for_global_discounts();


--
-- TOC entry 5147 (class 2620 OID 18518)
-- Name: FacilityImage facility_image_add_position; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_image_add_position BEFORE INSERT OR UPDATE ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.add_facility_image_position();


--
-- TOC entry 5148 (class 2620 OID 18519)
-- Name: FacilityImage facility_image_check_position; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_image_check_position AFTER INSERT OR UPDATE OF "position" ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.check_facility_image_position();


--
-- TOC entry 5149 (class 2620 OID 18520)
-- Name: FacilityImage facility_image_update_position; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_image_update_position AFTER DELETE ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.update_facility_image_position();


--
-- TOC entry 5140 (class 2620 OID 18521)
-- Name: Facility facility_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_replace_empty_strings BEFORE INSERT OR UPDATE OF "placeID", author, description, title, website, "externalID", language, "welcomeNote" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.replace_facility_empty_strings();


--
-- TOC entry 5141 (class 2620 OID 18522)
-- Name: Facility facility_save_info_verified_history; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_save_info_verified_history AFTER UPDATE OF "infoVerified" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.save_info_verified_history();


--
-- TOC entry 5150 (class 2620 OID 18523)
-- Name: FacilityType facility_type_check_alarm; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_type_check_alarm AFTER INSERT OR UPDATE OF "alarmInEachUnit", "alarmInSomeUnits" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_alarm();


--
-- TOC entry 5151 (class 2620 OID 18524)
-- Name: FacilityType facility_type_check_prorata; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_type_check_prorata BEFORE INSERT OR UPDATE OF "firstMonthProrata", "billingDate" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_prorata();


--
-- TOC entry 5152 (class 2620 OID 18525)
-- Name: FacilityType facility_type_check_some; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_type_check_some AFTER INSERT OR UPDATE OF "someHeating", "someAirConditioning", "someHeatedFloor" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_some();


--
-- TOC entry 5153 (class 2620 OID 18526)
-- Name: FacilityType facility_type_check_terms; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_type_check_terms BEFORE INSERT OR UPDATE OF "monthlyBilling", "billingFrequency", "billingOnMoveInDate", "billingDate", "minBookingDays", "minBookingMonths" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_terms();


--
-- TOC entry 5154 (class 2620 OID 18527)
-- Name: FacilityType facility_type_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_type_delete_dependencies BEFORE DELETE ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.delete_facility_type_dependencies();


--
-- TOC entry 5142 (class 2620 OID 18528)
-- Name: Facility facility_update_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_update_masked_phone_number_availability AFTER INSERT OR DELETE OR UPDATE OF "maskedPhoneNumber" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.update_facility_masked_phone_number_availability();


--
-- TOC entry 5155 (class 2620 OID 18529)
-- Name: FacilityUser facility_user_add_locale; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER facility_user_add_locale BEFORE INSERT OR UPDATE ON public."FacilityUser" FOR EACH ROW EXECUTE FUNCTION public.add_facility_user_locale();


--
-- TOC entry 5157 (class 2620 OID 18530)
-- Name: FocusSession focus_session_check_start_time; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER focus_session_check_start_time BEFORE INSERT ON public."FocusSession" FOR EACH ROW WHEN ((new."startTime" IS NOT NULL)) EXECUTE FUNCTION public.check_focus_session_start_time();


--
-- TOC entry 5158 (class 2620 OID 18531)
-- Name: Image image_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER image_delete_dependencies BEFORE DELETE ON public."Image" FOR EACH ROW EXECUTE FUNCTION public.delete_image_dependencies();


--
-- TOC entry 5159 (class 2620 OID 18532)
-- Name: Image image_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER image_replace_empty_strings BEFORE INSERT OR UPDATE OF "authorName", "authorProfile" ON public."Image" FOR EACH ROW EXECUTE FUNCTION public.replace_image_empty_strings();


--
-- TOC entry 5161 (class 2620 OID 18533)
-- Name: Insurance insurance_check_monthly_fee; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER insurance_check_monthly_fee BEFORE INSERT OR UPDATE OF "monthlyFee", coverage ON public."Insurance" FOR EACH ROW EXECUTE FUNCTION public.check_insurance_monthly_fee();


--
-- TOC entry 5162 (class 2620 OID 18534)
-- Name: Insurance insurance_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER insurance_replace_empty_strings BEFORE INSERT OR UPDATE OF terms ON public."Insurance" FOR EACH ROW EXECUTE FUNCTION public.replace_insurance_empty_strings();


--
-- TOC entry 5163 (class 2620 OID 18535)
-- Name: MaskedPhoneNumber masked_phone_number_check_availability_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER masked_phone_number_check_availability_dependencies BEFORE INSERT OR UPDATE OF available ON public."MaskedPhoneNumber" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availability_dependencies();


--
-- TOC entry 5164 (class 2620 OID 18536)
-- Name: MaskedPhoneNumber masked_phone_number_save_availability; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER masked_phone_number_save_availability AFTER INSERT OR UPDATE OF available ON public."MaskedPhoneNumber" FOR EACH ROW EXECUTE FUNCTION public.save_masked_phone_number_availability_history();


--
-- TOC entry 5095 (class 2620 OID 18537)
-- Name: OpeningHours opening_hours_check_logic; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER opening_hours_check_logic BEFORE INSERT OR UPDATE ON public."OpeningHours" FOR EACH ROW EXECUTE FUNCTION public.check_opening_hours_logic();


--
-- TOC entry 5160 (class 2620 OID 18540)
-- Name: InfoVerifiedHistory reminder_update_last_update_time; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER reminder_update_last_update_time AFTER INSERT ON public."InfoVerifiedHistory" FOR EACH ROW EXECUTE FUNCTION public.update_reminder_last_update_time();


--
-- TOC entry 5167 (class 2620 OID 18541)
-- Name: Session session_check_change; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_check_change AFTER INSERT OR UPDATE OF "latestActivityTime" ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.check_session_change();


--
-- TOC entry 5168 (class 2620 OID 18542)
-- Name: Session session_check_lastest_activity_time; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_check_lastest_activity_time BEFORE UPDATE OF "latestActivityTime" ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.check_session_lastest_activity_time();


--
-- TOC entry 5169 (class 2620 OID 18543)
-- Name: Session session_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_delete_dependencies BEFORE DELETE ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.delete_session_dependencies();


--
-- TOC entry 5170 (class 2620 OID 18544)
-- Name: Session session_delete_oldest; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_delete_oldest AFTER INSERT ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.delete_session_oldest();


--
-- TOC entry 5171 (class 2620 OID 18545)
-- Name: Session session_end_active; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_end_active AFTER UPDATE OF "endTime" ON public."Session" FOR EACH ROW WHEN ((new."endTime" IS NOT NULL)) EXECUTE FUNCTION public.end_session_active();


--
-- TOC entry 5172 (class 2620 OID 18546)
-- Name: SessionFacility session_facility_check_focus_duration; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_facility_check_focus_duration BEFORE INSERT OR UPDATE OF "focusDuration", "startTime", "endTime" ON public."SessionFacility" FOR EACH ROW WHEN (((new."focusDuration" IS NOT NULL) AND (new."startTime" IS NOT NULL) AND (new."endTime" IS NOT NULL))) EXECUTE FUNCTION public.check_session_facility_focus_duration();


--
-- TOC entry 5173 (class 2620 OID 18547)
-- Name: SessionFacility session_facility_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER session_facility_delete_dependencies BEFORE DELETE ON public."SessionFacility" FOR EACH ROW EXECUTE FUNCTION public.delete_session_facility_dependencies();


--
-- TOC entry 5165 (class 2620 OID 18548)
-- Name: Region superarea_delete_image_independencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER superarea_delete_image_independencies AFTER DELETE ON public."Region" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5175 (class 2620 OID 18552)
-- Name: SynchronizationConfig synchronization_update_config_info_verified; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER synchronization_update_config_info_verified BEFORE INSERT OR UPDATE OF enabled ON public."SynchronizationConfig" FOR EACH ROW EXECUTE FUNCTION public.update_synchronization_config_info_verified();


--
-- TOC entry 5176 (class 2620 OID 18553)
-- Name: Unit unit_check_archived; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_archived BEFORE INSERT OR UPDATE OF archived ON public."Unit" FOR EACH ROW WHEN ((new.archived IS TRUE)) EXECUTE FUNCTION public.check_unit_archived();


--
-- TOC entry 5177 (class 2620 OID 18554)
-- Name: Unit unit_check_floor; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_floor BEFORE INSERT OR UPDATE OF "noStairs", "floorNb" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_floor();


--
-- TOC entry 5178 (class 2620 OID 18555)
-- Name: Unit unit_check_outdoor; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_outdoor BEFORE INSERT OR UPDATE OF heating, "heatedFloor", "airConditioning", "facilityTypeID", outdoor ON public."Unit" FOR EACH ROW WHEN ((new.outdoor IS TRUE)) EXECUTE FUNCTION public.check_unit_outdoor();


--
-- TOC entry 5179 (class 2620 OID 18556)
-- Name: Unit unit_check_price; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_price BEFORE INSERT OR UPDATE OF "regularPrice", "discountedPrice" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_price();


--
-- TOC entry 5180 (class 2620 OID 18557)
-- Name: Unit unit_check_size; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_size BEFORE INSERT OR UPDATE OF "sizeCategoryID", width, length, "facilityTypeID" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_size();


--
-- TOC entry 5181 (class 2620 OID 18558)
-- Name: Unit unit_check_some; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_some AFTER INSERT OR UPDATE OF heating, "airConditioning" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_some();


--
-- TOC entry 5182 (class 2620 OID 18559)
-- Name: Unit unit_check_vehicles; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_check_vehicles BEFORE INSERT OR UPDATE OF motorcycle, car, rv, boat, "rentalDeposit" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_vehicles();


--
-- TOC entry 5183 (class 2620 OID 18560)
-- Name: Unit unit_delete_dependencies; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_delete_dependencies BEFORE DELETE ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.delete_unit_dependencies();


--
-- TOC entry 5188 (class 2620 OID 18561)
-- Name: UnitDiscount unit_discount_check_activity; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE CONSTRAINT TRIGGER unit_discount_check_activity AFTER INSERT OR DELETE ON public."UnitDiscount" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_activity();


--
-- TOC entry 5189 (class 2620 OID 18563)
-- Name: UnitDiscount unit_discount_check_apparition; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_discount_check_apparition BEFORE INSERT OR UPDATE ON public."UnitDiscount" FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_apparition();


--
-- TOC entry 5190 (class 2620 OID 18564)
-- Name: UnitDiscount unit_discount_check_facility_id; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_discount_check_facility_id BEFORE INSERT OR UPDATE ON public."UnitDiscount" FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_facility_id();


--
-- TOC entry 5184 (class 2620 OID 18565)
-- Name: Unit unit_save_archival_history; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_save_archival_history AFTER INSERT OR UPDATE OF archived ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_archival_history();


--
-- TOC entry 5185 (class 2620 OID 18566)
-- Name: Unit unit_save_availability_history; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_save_availability_history AFTER INSERT OR UPDATE OF available ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_availability_history();


--
-- TOC entry 5186 (class 2620 OID 18567)
-- Name: Unit unit_save_price_history; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_save_price_history AFTER INSERT OR UPDATE OF "regularPrice", "discountedPrice" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_price_history();


--
-- TOC entry 5187 (class 2620 OID 18568)
-- Name: Unit unit_save_visibility_history; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER unit_save_visibility_history AFTER INSERT OR UPDATE OF visible ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_visibility_history();


--
-- TOC entry 5156 (class 2620 OID 18569)
-- Name: FacilityUser user_check_exist; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER user_check_exist BEFORE INSERT OR UPDATE ON public."FacilityUser" FOR EACH ROW EXECUTE FUNCTION public.check_user_exist();


--
-- TOC entry 5166 (class 2620 OID 18570)
-- Name: Reminder user_check_exist; Type: TRIGGER; Schema: public; Owner: pgsync
--

CREATE TRIGGER user_check_exist BEFORE INSERT ON public."Reminder" FOR EACH ROW EXECUTE FUNCTION public.check_user_exist();


--
-- TOC entry 5040 (class 2606 OID 18571)
-- Name: BookingCall BookingCall_bookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_bookingID_fkey" FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5041 (class 2606 OID 18576)
-- Name: BookingCall BookingCall_callID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_callID_fkey" FOREIGN KEY ("callID") REFERENCES public."Call"("callID");


--
-- TOC entry 5036 (class 2606 OID 18581)
-- Name: Booking Booking_maskedPhoneNumberID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_maskedPhoneNumberID_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5037 (class 2606 OID 18586)
-- Name: Booking Booking_primaryBookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_primaryBookingID_fkey" FOREIGN KEY ("primaryBookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5044 (class 2606 OID 18591)
-- Name: Call Call_bookingReasonID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_bookingReasonID_fkey" FOREIGN KEY ("bookingReasonID") REFERENCES public."BookingReason"("bookingReasonID") NOT VALID;


--
-- TOC entry 5045 (class 2606 OID 18596)
-- Name: Call Call_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5046 (class 2606 OID 18601)
-- Name: Call Call_maskedPhoneNumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_maskedPhoneNumber_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5047 (class 2606 OID 18606)
-- Name: City City_superArea1ID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "City_superArea1ID_fkey" FOREIGN KEY ("superArea1ID") REFERENCES public."SuperArea1"("regionID");


--
-- TOC entry 5048 (class 2606 OID 18611)
-- Name: City City_superArea2ID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "City_superArea2ID_fkey" FOREIGN KEY ("superArea2ID") REFERENCES public."SuperArea2"("regionID");


--
-- TOC entry 5054 (class 2606 OID 18616)
-- Name: Email Email_bookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_bookingID_fkey" FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5055 (class 2606 OID 18621)
-- Name: Email Email_bookingReasonID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_bookingReasonID_fkey" FOREIGN KEY ("bookingReasonID") REFERENCES public."BookingReason"("bookingReasonID") NOT VALID;


--
-- TOC entry 5064 (class 2606 OID 18626)
-- Name: FacilityEmail FacilityEmail_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityEmail"
    ADD CONSTRAINT "FacilityEmail_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5068 (class 2606 OID 18631)
-- Name: FacilityPhoneNumber FacilityPhoneNumber_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityPhoneNumber"
    ADD CONSTRAINT "FacilityPhoneNumber_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID") NOT VALID;


--
-- TOC entry 5069 (class 2606 OID 18636)
-- Name: FacilityTag FacilityTag_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5070 (class 2606 OID 18641)
-- Name: FacilityTag FacilityTag_tagID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_tagID_fkey" FOREIGN KEY ("tagID") REFERENCES public."Tag"("tagID");


--
-- TOC entry 5057 (class 2606 OID 18646)
-- Name: Facility Facility_maskedPhoneNumberID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT "Facility_maskedPhoneNumberID_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5058 (class 2606 OID 18651)
-- Name: Facility Facility_synchronizationConfigID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT "Facility_synchronizationConfigID_fkey" FOREIGN KEY ("synchronizationConfigID") REFERENCES public."SynchronizationConfig"("synchronizationConfigID") NOT VALID;


--
-- TOC entry 5077 (class 2606 OID 18656)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber");


--
-- TOC entry 5079 (class 2606 OID 18661)
-- Name: Note Note_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Note"
    ADD CONSTRAINT "Note_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5034 (class 2606 OID 18666)
-- Name: OpeningHours OpeningHours_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."OpeningHours"
    ADD CONSTRAINT "OpeningHours_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5080 (class 2606 OID 18677)
-- Name: PostalCode PostalCode_neighborhoodID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT "PostalCode_neighborhoodID_fkey" FOREIGN KEY ("neighborhoodID") REFERENCES public."Neighborhood"("regionID");


--
-- TOC entry 5078 (class 2606 OID 18682)
-- Name: Region Region_imageID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE public."Region"
    ADD CONSTRAINT "Region_imageID_fkey" FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5083 (class 2606 OID 18696)
-- Name: SearchedCity SearchedCity_epicenterCityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SearchedCity"
    ADD CONSTRAINT "SearchedCity_epicenterCityID_fkey" FOREIGN KEY ("epicenterCityID") REFERENCES public."EpicenterCity"("epicenterCityID");


--
-- TOC entry 5086 (class 2606 OID 18701)
-- Name: StorageTypeMatch StorageTypeMatch_synchronizationConfigID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_synchronizationConfigID_fkey" FOREIGN KEY ("synchronizationConfigID") REFERENCES public."SynchronizationConfig"("synchronizationConfigID");


--
-- TOC entry 5087 (class 2606 OID 18706)
-- Name: SynchronizationConfig SynchronizationConfig_softwareID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_softwareID_fkey" FOREIGN KEY ("softwareID") REFERENCES public."Software"("softwareID") NOT VALID;


--
-- TOC entry 5089 (class 2606 OID 18711)
-- Name: UnitArchivalHistory UnitArchivalHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5090 (class 2606 OID 18716)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5093 (class 2606 OID 18721)
-- Name: UnitPriceHistory UnitPriceHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5094 (class 2606 OID 18726)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5059 (class 2606 OID 18731)
-- Name: Facility addressid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT addressid_fkey FOREIGN KEY ("addressID") REFERENCES public."Address"("addressID");


--
-- TOC entry 5042 (class 2606 OID 18736)
-- Name: BookingDiscount bookingid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT bookingid_fkey FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5081 (class 2606 OID 18741)
-- Name: PostalCode cityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT cityid_fkey FOREIGN KEY ("cityID") REFERENCES public."City"("cityID");


--
-- TOC entry 5056 (class 2606 OID 18746)
-- Name: EpicenterCity cityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT cityid_fkey FOREIGN KEY ("cityID") REFERENCES public."City"("cityID");


--
-- TOC entry 5049 (class 2606 OID 18751)
-- Name: City countryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT countryid_fkey FOREIGN KEY ("countryID") REFERENCES public."Country"("countryID");


--
-- TOC entry 5051 (class 2606 OID 18756)
-- Name: Country currencyid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT currencyid_fkey FOREIGN KEY ("currencyID") REFERENCES public."Currency"("currencyID");


--
-- TOC entry 5038 (class 2606 OID 18761)
-- Name: Booking customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT customerid_fkey FOREIGN KEY ("customerID") REFERENCES public."Customer"("customerID");


--
-- TOC entry 5061 (class 2606 OID 18766)
-- Name: FacilityDiscount discountid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT discountid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5043 (class 2606 OID 18771)
-- Name: BookingDiscount discountid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT discountid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5091 (class 2606 OID 18776)
-- Name: UnitDiscount discoutid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT discoutid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5060 (class 2606 OID 18781)
-- Name: Facility epicentercityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT epicentercityid_fkey FOREIGN KEY ("epicenterCityID") REFERENCES public."EpicenterCity"("epicenterCityID");


--
-- TOC entry 5084 (class 2606 OID 18786)
-- Name: SessionFacility facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5082 (class 2606 OID 18791)
-- Name: Reminder facility_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT facility_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5053 (class 2606 OID 18796)
-- Name: Discount facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5066 (class 2606 OID 18801)
-- Name: FacilityImage facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5071 (class 2606 OID 18806)
-- Name: FacilityType facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5076 (class 2606 OID 18811)
-- Name: Insurance facilitytypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Insurance"
    ADD CONSTRAINT facilitytypeid_fkey FOREIGN KEY ("facilityTypeID") REFERENCES public."FacilityType"("facilityTypeID");


--
-- TOC entry 5075 (class 2606 OID 18816)
-- Name: InfoVerifiedHistory fk_facilityID; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."InfoVerifiedHistory"
    ADD CONSTRAINT "fk_facilityID" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5073 (class 2606 OID 18821)
-- Name: FacilityUser fk_facilityID; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityUser"
    ADD CONSTRAINT "fk_facilityID" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5067 (class 2606 OID 18826)
-- Name: FacilityImage imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5050 (class 2606 OID 18831)
-- Name: City imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5052 (class 2606 OID 18836)
-- Name: Country imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5035 (class 2606 OID 18841)
-- Name: Address postalcodeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT postalcodeid_fkey FOREIGN KEY ("postalCodeID") REFERENCES public."PostalCode"("postalCodeID");


--
-- TOC entry 5065 (class 2606 OID 18846)
-- Name: FacilityEvent sessionFacilityID; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityEvent"
    ADD CONSTRAINT "sessionFacilityID" FOREIGN KEY ("sessionFacilityID") REFERENCES public."SessionFacility"("sessionFacilityID");


--
-- TOC entry 5074 (class 2606 OID 18851)
-- Name: FocusSession sessionID_fk; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FocusSession"
    ADD CONSTRAINT "sessionID_fk" FOREIGN KEY ("sessionID") REFERENCES public."Session"("sessionID");


--
-- TOC entry 5085 (class 2606 OID 18856)
-- Name: SessionFacility sessionID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "sessionID_fkey" FOREIGN KEY ("sessionID") REFERENCES public."Session"("sessionID");


--
-- TOC entry 5088 (class 2606 OID 18861)
-- Name: Unit sizeCategoryID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT "sizeCategoryID_fkey" FOREIGN KEY ("sizeCategoryID") REFERENCES public."SizeCategory"("sizeCategoryID");


--
-- TOC entry 5062 (class 2606 OID 18866)
-- Name: FacilityDiscount sizecategoryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT sizecategoryid_fkey FOREIGN KEY ("sizeCategoryID") REFERENCES public."SizeCategory"("sizeCategoryID");


--
-- TOC entry 5063 (class 2606 OID 18871)
-- Name: FacilityDiscount storagetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT storagetypeid_fkey FOREIGN KEY ("storageTypeID") REFERENCES public."StorageType"("storageTypeID");


--
-- TOC entry 5072 (class 2606 OID 18876)
-- Name: FacilityType storagetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT storagetypeid_fkey FOREIGN KEY ("storageTypeID") REFERENCES public."StorageType"("storageTypeID");


--
-- TOC entry 5092 (class 2606 OID 18881)
-- Name: UnitDiscount unitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT unitid_fkey FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5039 (class 2606 OID 18886)
-- Name: Booking unitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: pgsync
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT unitid_fkey FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pgsync
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2023-06-08 15:35:35

--
-- pgsyncQL database dump complete
--

