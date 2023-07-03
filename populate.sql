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


ALTER TABLE public."OpeningHours" OWNER TO postgres;

SET default_table_access_method = heap;

--
-- TOC entry 225 (class 1259 OID 17721)
-- Name: AccessHours; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."AccessHours" OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 17729)
-- Name: AdAccessRequest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."AdAccessRequest" (
    "adAccessRequestID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "placeID" character varying(255) NOT NULL,
    "userID" uuid NOT NULL,
    "phoneNumber" character varying(255) NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."AdAccessRequest" OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 17736)
-- Name: Address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Address" (
    "addressID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "apartmentNumber" character varying(255),
    "streetName" character varying(255),
    "postalCodeID" uuid NOT NULL,
    coordinates public.geometry NOT NULL,
    "streetNumber" character varying(255)
);


ALTER TABLE public."Address" OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 17742)
-- Name: Booking; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Booking" OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 17765)
-- Name: BookingCall; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."BookingCall" (
    "bookingID" uuid NOT NULL,
    "callID" uuid NOT NULL,
    "pendingBooking" boolean NOT NULL
);


ALTER TABLE public."BookingCall" OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 17768)
-- Name: BookingDiscount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."BookingDiscount" (
    "discountID" uuid NOT NULL,
    "bookingID" uuid NOT NULL
);


ALTER TABLE public."BookingDiscount" OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 17771)
-- Name: booking_reason_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.booking_reason_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.booking_reason_sequence OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 17772)
-- Name: BookingReason; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."BookingReason" (
    "bookingReasonID" integer DEFAULT nextval('public.booking_reason_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT bookingreasonid_positive CHECK (("bookingReasonID" > 0))
);


ALTER TABLE public."BookingReason" OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 17777)
-- Name: Call; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Call" OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 17788)
-- Name: City; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."City" OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 17796)
-- Name: Country; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Country" OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 17806)
-- Name: Currency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Currency" (
    "currencyID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    code character varying(255) NOT NULL,
    currency character varying(255) NOT NULL,
    CONSTRAINT code_valid CHECK ((length((code)::text) = 3))
);


ALTER TABLE public."Currency" OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 17813)
-- Name: Customer; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Customer" OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 17823)
-- Name: Discount; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Discount" OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 17831)
-- Name: Email; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Email" OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 17849)
-- Name: EpicenterCity; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."EpicenterCity" OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 17858)
-- Name: Facility; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Facility" OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 17877)
-- Name: FacilityDiscount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityDiscount" (
    "facilityDiscountID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "discountID" uuid NOT NULL,
    "sizeCategoryID" integer,
    "storageTypeID" integer
);


ALTER TABLE public."FacilityDiscount" OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 17881)
-- Name: FacilityEmail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityEmail" (
    "facilityID" uuid NOT NULL,
    email character varying(255) NOT NULL,
    CONSTRAINT email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."FacilityEmail" OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 17885)
-- Name: FacilityEvent; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityEvent" (
    "facilityEventID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "sessionFacilityID" uuid NOT NULL,
    name character varying NOT NULL,
    data json NOT NULL
);


ALTER TABLE public."FacilityEvent" OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 17891)
-- Name: FacilityImage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityImage" (
    "facilityID" uuid NOT NULL,
    "imageID" uuid NOT NULL,
    "position" smallint NOT NULL
);


ALTER TABLE public."FacilityImage" OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 17894)
-- Name: FacilityPhoneNumber; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityPhoneNumber" (
    "facilityID" uuid NOT NULL,
    "phoneNumber" character varying(255) NOT NULL,
    "dialCode" smallint NOT NULL,
    "formattedPhoneNumber" character varying(255) NOT NULL
);


ALTER TABLE public."FacilityPhoneNumber" OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 17899)
-- Name: FacilityTag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityTag" (
    "tagID" smallint NOT NULL,
    "facilityID" uuid NOT NULL
);


ALTER TABLE public."FacilityTag" OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 17902)
-- Name: FacilityType; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."FacilityType" OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 17959)
-- Name: FacilityUser; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FacilityUser" (
    "facilityID" uuid NOT NULL,
    "userID" uuid NOT NULL,
    date date DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."FacilityUser" OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 17963)
-- Name: FocusSession; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."FocusSession" (
    "focusSessionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "sessionID" uuid NOT NULL,
    "startTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endTime" timestamp without time zone,
    CONSTRAINT "endTime_greater_than_startTime" CHECK (("startTime" <= "endTime"))
);


ALTER TABLE public."FocusSession" OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 17969)
-- Name: Image; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Image" (
    "imageID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    key character varying(255) NOT NULL,
    "authorName" character varying(255),
    "authorProfile" character varying(255),
    CONSTRAINT authorprofile_format CHECK ((("authorProfile")::text ~ 'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,255}\.[a-z]{2,9}\y([-a-zA-Z0-9@:%_\+.,~#?!&>//=]*)$'::text)),
    CONSTRAINT key_format CHECK (((key)::text ~ '^[a-zA-Z0-9-]+(?:\/[a-zA-Z0-9-]+)*$'::text))
);


ALTER TABLE public."Image" OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 17977)
-- Name: InfoVerifiedHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."InfoVerifiedHistory" (
    "facilityID" uuid NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "infoVerifiedHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    status boolean
);


ALTER TABLE public."InfoVerifiedHistory" OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 17982)
-- Name: Insurance; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Insurance" OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 17991)
-- Name: MaskedPhoneNumber; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MaskedPhoneNumber" (
    "maskedPhoneNumber" character varying(255) NOT NULL,
    available boolean DEFAULT true NOT NULL,
    active boolean DEFAULT true NOT NULL,
    "dialCode" smallint NOT NULL,
    "formattedPhoneNumber" character varying(255) NOT NULL
);


ALTER TABLE public."MaskedPhoneNumber" OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 17998)
-- Name: MaskedPhoneNumberAvailabilityHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MaskedPhoneNumberAvailabilityHistory" (
    "maskedPhoneNumberAvailabilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "maskedPhoneNumber" character varying(255) NOT NULL,
    available boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."MaskedPhoneNumberAvailabilityHistory" OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 18003)
-- Name: Region; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Region" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
)
PARTITION BY LIST (type);


ALTER TABLE public."Region" OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 18007)
-- Name: Neighborhood; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Neighborhood" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."Neighborhood" OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 18013)
-- Name: NewsletterMember; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."NewsletterMember" (
    "memberID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email character varying NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    language character varying(5) DEFAULT 'en-CA'::character varying NOT NULL,
    CONSTRAINT mail_valid CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text))
);


ALTER TABLE public."NewsletterMember" OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 18022)
-- Name: Note; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Note" (
    "noteID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "facilityID" uuid NOT NULL,
    body text NOT NULL,
    author character varying(255),
    "creationDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pinned boolean DEFAULT false NOT NULL
);


ALTER TABLE public."Note" OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 18030)
-- Name: OfficeHours; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."OfficeHours" OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 18038)
-- Name: PostalCode; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PostalCode" (
    "postalCodeID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "postalCode" character varying(255),
    "cityID" uuid NOT NULL,
    "neighborhoodID" uuid,
    "placeID" character varying(255)
);


ALTER TABLE public."PostalCode" OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 18044)
-- Name: Reminder; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Reminder" (
    "reminderID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    weekdays integer[],
    "userID" uuid NOT NULL,
    "facilityID" uuid NOT NULL,
    "creationDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "lastUpdateTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."Reminder" OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 18052)
-- Name: SearchedCity; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SearchedCity" (
    "searchedCityID" integer NOT NULL,
    name character varying(255) NOT NULL,
    coordinates public.geometry NOT NULL,
    "epicenterCityID" uuid NOT NULL
);


ALTER TABLE public."SearchedCity" OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 18057)
-- Name: Session; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Session" (
    "sessionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "user" character varying,
    "startTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "endTime" timestamp without time zone,
    "latestActivityTime" timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "endTime_greater_than_startTime" CHECK (("startTime" <= "endTime"))
);


ALTER TABLE public."Session" OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 18066)
-- Name: SessionFacility; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."SessionFacility" OWNER TO postgres;

--
-- TOC entry 266 (class 1259 OID 18076)
-- Name: size_category_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.size_category_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.size_category_sequence OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 18077)
-- Name: SizeCategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SizeCategory" (
    "sizeCategoryID" integer DEFAULT nextval('public.size_category_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT sizecategoryid_positive CHECK (("sizeCategoryID" >= 0))
);


ALTER TABLE public."SizeCategory" OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 18082)
-- Name: storage_type_sequence; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.storage_type_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.storage_type_sequence OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 18083)
-- Name: Software; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Software" (
    "softwareID" smallint DEFAULT nextval('public.storage_type_sequence'::regclass) NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public."Software" OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 18089)
-- Name: StorageType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StorageType" (
    "storageTypeID" integer DEFAULT nextval('public.storage_type_sequence'::regclass) NOT NULL,
    description character varying(255) NOT NULL,
    CONSTRAINT storagetypeid_positive CHECK (("storageTypeID" > 0))
);


ALTER TABLE public."StorageType" OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 18094)
-- Name: StorageTypeMatch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StorageTypeMatch" (
    "storageTypeMatchID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    description character varying NOT NULL,
    features json,
    "synchronizationConfigID" uuid NOT NULL,
    "storageTypeID" character varying NOT NULL,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public."StorageTypeMatch" OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 18101)
-- Name: SuperArea1; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SuperArea1" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."SuperArea1" OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 18107)
-- Name: SuperArea2; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SuperArea2" (
    "regionID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    "imageID" uuid,
    "placeID" character varying(255),
    type character varying(255) NOT NULL
);


ALTER TABLE public."SuperArea2" OWNER TO postgres;

--
-- TOC entry 274 (class 1259 OID 18113)
-- Name: SynchronizationConfig; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SynchronizationConfig" (
    "synchronizationConfigID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    config json NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    "integrationSchema" json NOT NULL,
    "softwareID" smallint NOT NULL,
    "inboundKey" character varying(15) DEFAULT concat('CS-', upper(substr((public.uuid_generate_v4())::text, 25))) NOT NULL
);


ALTER TABLE public."SynchronizationConfig" OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 18121)
-- Name: Tag; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Tag" (
    description character varying(255) NOT NULL,
    "tagID" smallint NOT NULL
);


ALTER TABLE public."Tag" OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 18124)
-- Name: Unit; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."Unit" OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 18160)
-- Name: UnitArchivalHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UnitArchivalHistory" (
    "unitArchivalHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    archived boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."UnitArchivalHistory" OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 18165)
-- Name: UnitAvailabilityHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UnitAvailabilityHistory" (
    "unitID" uuid NOT NULL,
    available boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "unitAvailabilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


ALTER TABLE public."UnitAvailabilityHistory" OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 18170)
-- Name: UnitDiscount; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UnitDiscount" (
    "discountID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid DEFAULT public.uuid_generate_v4() NOT NULL
);


ALTER TABLE public."UnitDiscount" OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 18175)
-- Name: UnitPriceHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UnitPriceHistory" (
    "unitPriceHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    "newPrice" numeric(10,2),
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "priceType" character varying(255) DEFAULT 'regular'::character varying NOT NULL
);


ALTER TABLE public."UnitPriceHistory" OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 18181)
-- Name: UnitVisibilityHistory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."UnitVisibilityHistory" (
    "unitVisibilityHistoryID" uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    "unitID" uuid NOT NULL,
    visible boolean NOT NULL,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public."UnitVisibilityHistory" OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 18186)
-- Name: ValidationCode; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public."ValidationCode" OWNER TO postgres;

--
-- TOC entry 4543 (class 0 OID 0)
-- Name: AccessHours; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OpeningHours" ATTACH PARTITION public."AccessHours" FOR VALUES IN ('access');


--
-- TOC entry 4544 (class 0 OID 0)
-- Name: Neighborhood; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."Neighborhood" FOR VALUES IN ('neighborhood');


--
-- TOC entry 4545 (class 0 OID 0)
-- Name: OfficeHours; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OpeningHours" ATTACH PARTITION public."OfficeHours" FOR VALUES IN ('office');


--
-- TOC entry 4546 (class 0 OID 0)
-- Name: SuperArea1; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."SuperArea1" FOR VALUES IN ('superArea1');


--
-- TOC entry 4547 (class 0 OID 0)
-- Name: SuperArea2; Type: TABLE ATTACH; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Region" ATTACH PARTITION public."SuperArea2" FOR VALUES IN ('superArea2');


--
-- TOC entry 4846 (class 2606 OID 18196)
-- Name: OpeningHours OpeningHours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OpeningHours"
    ADD CONSTRAINT "OpeningHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4848 (class 2606 OID 18200)
-- Name: AccessHours AccessHours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AccessHours"
    ADD CONSTRAINT "AccessHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4850 (class 2606 OID 18207)
-- Name: AdAccessRequest AdAccessRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."AdAccessRequest"
    ADD CONSTRAINT "AdAccessRequest_pkey" PRIMARY KEY ("adAccessRequestID");


--
-- TOC entry 4861 (class 2606 OID 18213)
-- Name: BookingCall BookingCall_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_pkey" PRIMARY KEY ("bookingID", "callID");


--
-- TOC entry 4865 (class 2606 OID 18222)
-- Name: BookingReason BookingReason_description_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingReason"
    ADD CONSTRAINT "BookingReason_description_key" UNIQUE (description);


--
-- TOC entry 4867 (class 2606 OID 18226)
-- Name: BookingReason BookingReason_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingReason"
    ADD CONSTRAINT "BookingReason_pkey" PRIMARY KEY ("bookingReasonID");


--
-- TOC entry 4856 (class 2606 OID 18230)
-- Name: Booking Booking_facilityBookingID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_facilityBookingID_key" UNIQUE ("facilityBookingID");


--
-- TOC entry 4869 (class 2606 OID 18236)
-- Name: Call Call_callAnalyticsJobName_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_callAnalyticsJobName_key" UNIQUE ("recordingID");


--
-- TOC entry 4871 (class 2606 OID 18241)
-- Name: Call Call_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_pkey" PRIMARY KEY ("callID");


--
-- TOC entry 4893 (class 2606 OID 18245)
-- Name: Email Email_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_pkey" PRIMARY KEY ("emailID");


--
-- TOC entry 4895 (class 2606 OID 18247)
-- Name: EpicenterCity EpicenterCity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT "EpicenterCity_pkey" PRIMARY KEY ("epicenterCityID");


--
-- TOC entry 4907 (class 2606 OID 18252)
-- Name: FacilityEmail FacilityEmail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityEmail"
    ADD CONSTRAINT "FacilityEmail_pkey" PRIMARY KEY ("facilityID", email);


--
-- TOC entry 4909 (class 2606 OID 18257)
-- Name: FacilityEvent FacilityEvent_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityEvent"
    ADD CONSTRAINT "FacilityEvent_pkey" PRIMARY KEY ("facilityEventID");


--
-- TOC entry 4913 (class 2606 OID 18265)
-- Name: FacilityPhoneNumber FacilityPhoneNumber_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityPhoneNumber"
    ADD CONSTRAINT "FacilityPhoneNumber_pkey" PRIMARY KEY ("facilityID", "phoneNumber");


--
-- TOC entry 4915 (class 2606 OID 18268)
-- Name: FacilityTag FacilityTag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_pkey" PRIMARY KEY ("tagID", "facilityID");


--
-- TOC entry 4921 (class 2606 OID 18272)
-- Name: FacilityUser FacilityUser_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityUser"
    ADD CONSTRAINT "FacilityUser_pkey" PRIMARY KEY ("userID", "facilityID");


--
-- TOC entry 4923 (class 2606 OID 18276)
-- Name: FocusSession FocusSession_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FocusSession"
    ADD CONSTRAINT "FocusSession_pkey" PRIMARY KEY ("focusSessionID");


--
-- TOC entry 4927 (class 2606 OID 18279)
-- Name: InfoVerifiedHistory InfoVerifiedHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InfoVerifiedHistory"
    ADD CONSTRAINT "InfoVerifiedHistory_pkey" PRIMARY KEY ("infoVerifiedHistoryID");


--
-- TOC entry 4933 (class 2606 OID 18281)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_date_key" UNIQUE ("maskedPhoneNumber", date);


--
-- TOC entry 4935 (class 2606 OID 18283)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_pkey" PRIMARY KEY ("maskedPhoneNumberAvailabilityHistoryID");


--
-- TOC entry 4931 (class 2606 OID 18285)
-- Name: MaskedPhoneNumber MaskedPhoneNumber_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MaskedPhoneNumber"
    ADD CONSTRAINT "MaskedPhoneNumber_pkey" PRIMARY KEY ("maskedPhoneNumber");


--
-- TOC entry 4941 (class 2606 OID 18287)
-- Name: Neighborhood Neighborhood_regionID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhood_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4937 (class 2606 OID 18289)
-- Name: Region Region_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Region"
    ADD CONSTRAINT "Region_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4943 (class 2606 OID 18291)
-- Name: Neighborhood Neighborhoodd_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhoodd_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4939 (class 2606 OID 18293)
-- Name: Region region_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Region"
    ADD CONSTRAINT region_unique UNIQUE ("placeID", type);


--
-- TOC entry 4945 (class 2606 OID 18295)
-- Name: Neighborhood Neighborhoodd_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Neighborhood"
    ADD CONSTRAINT "Neighborhoodd_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4947 (class 2606 OID 18297)
-- Name: NewsletterMember NewsletterMember_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NewsletterMember"
    ADD CONSTRAINT "NewsletterMember_pkey" PRIMARY KEY ("memberID");


--
-- TOC entry 4951 (class 2606 OID 18299)
-- Name: Note Note_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Note"
    ADD CONSTRAINT "Note_pkey" PRIMARY KEY ("noteID");


--
-- TOC entry 4953 (class 2606 OID 18301)
-- Name: OfficeHours OfficeHours_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."OfficeHours"
    ADD CONSTRAINT "OfficeHours_pkey" PRIMARY KEY ("facilityID", "dayOfWeek", "openingTime", "closingTime", type);


--
-- TOC entry 4965 (class 2606 OID 18303)
-- Name: SearchedCity SearchedCity_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SearchedCity"
    ADD CONSTRAINT "SearchedCity_pkey" PRIMARY KEY ("searchedCityID");


--
-- TOC entry 4969 (class 2606 OID 18305)
-- Name: SessionFacility SessionFacility_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "SessionFacility_pkey" PRIMARY KEY ("sessionFacilityID");


--
-- TOC entry 4967 (class 2606 OID 18307)
-- Name: Session Session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Session"
    ADD CONSTRAINT "Session_pkey" PRIMARY KEY ("sessionID");


--
-- TOC entry 4973 (class 2606 OID 18309)
-- Name: Software Software_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Software"
    ADD CONSTRAINT "Software_pkey" PRIMARY KEY ("softwareID");


--
-- TOC entry 4979 (class 2606 OID 18311)
-- Name: StorageTypeMatch StorageTypeMatch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_pkey" PRIMARY KEY ("storageTypeMatchID");


--
-- TOC entry 4981 (class 2606 OID 18313)
-- Name: StorageTypeMatch StorageTypeMatch_storageTypeID_synchronizationConfigID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_storageTypeID_synchronizationConfigID_key" UNIQUE ("storageTypeID", "synchronizationConfigID");


--
-- TOC entry 4975 (class 2606 OID 18315)
-- Name: StorageType StorageType_description_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StorageType"
    ADD CONSTRAINT "StorageType_description_key" UNIQUE (description);


--
-- TOC entry 4983 (class 2606 OID 18317)
-- Name: SuperArea1 SuperArea1_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4985 (class 2606 OID 18319)
-- Name: SuperArea1 SuperArea1_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4987 (class 2606 OID 18321)
-- Name: SuperArea1 SuperArea1_regionID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea1"
    ADD CONSTRAINT "SuperArea1_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4989 (class 2606 OID 18323)
-- Name: SuperArea2 SuperArea2_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_pkey" PRIMARY KEY ("regionID", type);


--
-- TOC entry 4991 (class 2606 OID 18325)
-- Name: SuperArea2 SuperArea2_placeID_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_placeID_type_key" UNIQUE ("placeID", type);


--
-- TOC entry 4993 (class 2606 OID 18327)
-- Name: SuperArea2 SuperArea2_regionID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SuperArea2"
    ADD CONSTRAINT "SuperArea2_regionID_key" UNIQUE ("regionID");


--
-- TOC entry 4995 (class 2606 OID 18329)
-- Name: SynchronizationConfig SynchronizationConfig_inboundKey_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_inboundKey_key" UNIQUE ("inboundKey");


--
-- TOC entry 4997 (class 2606 OID 18331)
-- Name: SynchronizationConfig SynchronizationConfig_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_pkey" PRIMARY KEY ("synchronizationConfigID");


--
-- TOC entry 5007 (class 2606 OID 18333)
-- Name: UnitArchivalHistory UnitArchivalHistory_date_unitID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_date_unitID_key" UNIQUE (date, "unitID");


--
-- TOC entry 5009 (class 2606 OID 18335)
-- Name: UnitArchivalHistory UnitArchivalHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_pkey" PRIMARY KEY ("unitArchivalHistoryID");


--
-- TOC entry 5011 (class 2606 OID 18337)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_pkey" PRIMARY KEY ("unitAvailabilityHistoryID");


--
-- TOC entry 5013 (class 2606 OID 18339)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_unitID_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_unitID_date_key" UNIQUE ("unitID", date);


--
-- TOC entry 5017 (class 2606 OID 18341)
-- Name: UnitPriceHistory UnitPriceHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_pkey" PRIMARY KEY ("unitPriceHistoryID");


--
-- TOC entry 5019 (class 2606 OID 18343)
-- Name: UnitPriceHistory UnitPriceHistory_unitID_date_priceType_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_unitID_date_priceType_key" UNIQUE ("unitID", date, "priceType");


--
-- TOC entry 5021 (class 2606 OID 18345)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_date_unitID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_date_unitID_key" UNIQUE (date, "unitID");


--
-- TOC entry 5023 (class 2606 OID 18347)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_pkey" PRIMARY KEY ("unitVisibilityHistoryID");


--
-- TOC entry 5001 (class 2606 OID 18349)
-- Name: Unit Unit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT "Unit_pkey" PRIMARY KEY ("unitID");


--
-- TOC entry 5025 (class 2606 OID 18351)
-- Name: ValidationCode ValidationCode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ValidationCode"
    ADD CONSTRAINT "ValidationCode_pkey" PRIMARY KEY ("validationCodeID");


--
-- TOC entry 4746 (class 2606 OID 18352)
-- Name: Booking abortionSource_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "abortionSource_valid" CHECK ((("abortionSource" IS NULL) OR (("abortionSource")::text = 'call'::text) OR (("abortionSource")::text = 'sms'::text) OR (("abortionSource")::text = 'email'::text) OR (("abortionSource")::text = 'customer'::text) OR (("abortionSource")::text = 'facility'::text))) NOT VALID;


--
-- TOC entry 4814 (class 2606 OID 18353)
-- Name: MaskedPhoneNumber active_or_unavailable; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."MaskedPhoneNumber"
    ADD CONSTRAINT active_or_unavailable CHECK (((active IS TRUE) OR (available IS FALSE))) NOT VALID;


--
-- TOC entry 4852 (class 2606 OID 18355)
-- Name: Address address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT address_pkey PRIMARY KEY ("addressID");


--
-- TOC entry 4854 (class 2606 OID 18357)
-- Name: Address address_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT address_unique UNIQUE ("streetName", "streetNumber", "postalCodeID");


--
-- TOC entry 4766 (class 2606 OID 18358)
-- Name: Call agentSentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "agentSentiment_interval" CHECK ((("agentSentiment" >= ('-5'::integer)::numeric) AND ("agentSentiment" <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4747 (class 2606 OID 18359)
-- Name: Booking approved_or_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT approved_or_refused CHECK ((((approved IS TRUE) AND (refused IS FALSE)) OR ((approved IS FALSE) AND (refused IS TRUE)) OR ((approved IS FALSE) AND (refused IS FALSE)))) NOT VALID;


--
-- TOC entry 4787 (class 2606 OID 18360)
-- Name: Email booking_confirmed_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Email"
    ADD CONSTRAINT booking_confirmed_or_aborted CHECK (((("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS TRUE)) OR (("bookingAborted" IS TRUE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS FALSE)))) NOT VALID;


--
-- TOC entry 4767 (class 2606 OID 18361)
-- Name: Call booking_confirmed_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT booking_confirmed_or_aborted CHECK (((("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS TRUE)) OR (("bookingAborted" IS TRUE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS FALSE) AND ("bookingConfirmed" IS FALSE)) OR (("bookingAborted" IS NULL) AND ("bookingConfirmed" IS NULL)))) NOT VALID;


--
-- TOC entry 4858 (class 2606 OID 18363)
-- Name: Booking booking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT booking_pkey PRIMARY KEY ("bookingID");


--
-- TOC entry 4788 (class 2606 OID 18364)
-- Name: Email bounced_and_not_in_spam; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Email"
    ADD CONSTRAINT bounced_and_not_in_spam CHECK (((bounced IS FALSE) OR ("inSpam" IS FALSE))) NOT VALID;


--
-- TOC entry 4873 (class 2606 OID 18366)
-- Name: City city_areas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT city_areas UNIQUE ("superArea1ID", "superArea2ID", name);


--
-- TOC entry 4875 (class 2606 OID 18368)
-- Name: City city_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT city_pkey PRIMARY KEY ("cityID");


--
-- TOC entry 4877 (class 2606 OID 18370)
-- Name: City city_placeID_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "city_placeID_key" UNIQUE ("placeID");


--
-- TOC entry 4897 (class 2606 OID 18372)
-- Name: EpicenterCity cityid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT cityid_unique UNIQUE ("cityID");


--
-- TOC entry 4881 (class 2606 OID 18374)
-- Name: Currency code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Currency"
    ADD CONSTRAINT code_unique UNIQUE (code);


--
-- TOC entry 4903 (class 2606 OID 18376)
-- Name: FacilityDiscount conf_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT conf_unique UNIQUE ("discountID", "sizeCategoryID", "storageTypeID");


--
-- TOC entry 4748 (class 2606 OID 18377)
-- Name: Booking confirmationSource_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "confirmationSource_valid" CHECK ((("confirmationSource" IS NULL) OR (("confirmationSource")::text = 'call'::text) OR (("confirmationSource")::text = 'sms'::text) OR (("confirmationSource")::text = 'email'::text) OR (("confirmationSource")::text = 'facility'::text) OR (("confirmationSource")::text = 'customer'::text))) NOT VALID;


--
-- TOC entry 4879 (class 2606 OID 18379)
-- Name: Country country_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT country_pkey PRIMARY KEY ("countryID");


--
-- TOC entry 4883 (class 2606 OID 18381)
-- Name: Currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Currency"
    ADD CONSTRAINT currency_pkey PRIMARY KEY ("currencyID");


--
-- TOC entry 4770 (class 2606 OID 18382)
-- Name: Call customerSentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "customerSentiment_interval" CHECK ((("customerSentiment" >= ('-5'::integer)::numeric) AND ("customerSentiment" <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4885 (class 2606 OID 18384)
-- Name: Customer customer_email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT customer_email_unique UNIQUE (email);


--
-- TOC entry 4887 (class 2606 OID 18386)
-- Name: Customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT customer_pkey PRIMARY KEY ("customerID");


--
-- TOC entry 4749 (class 2606 OID 18387)
-- Name: Booking dateAborted_null_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateAborted_null_or_aborted" CHECK ((((aborted IS FALSE) AND ("dateAborted" IS NULL) AND ("abortionSource" IS NULL)) OR ((aborted IS TRUE) AND ("dateAborted" IS NOT NULL) AND ("abortionSource" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4750 (class 2606 OID 18388)
-- Name: Booking dateApproved_null_or_approved; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateApproved_null_or_approved" CHECK ((((approved IS FALSE) AND ("dateApproved" IS NULL)) OR ((approved IS TRUE) AND ("dateApproved" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4751 (class 2606 OID 18389)
-- Name: Booking dateCanceled_null_or_canceled; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateCanceled_null_or_canceled" CHECK ((((canceled IS FALSE) AND ("dateCanceled" IS NULL) AND ("cancelReason" IS NULL)) OR ((canceled IS TRUE) AND ("dateCanceled" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4752 (class 2606 OID 18390)
-- Name: Booking dateConfirmed_null_or_confirmed; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateConfirmed_null_or_confirmed" CHECK ((((confirmed IS FALSE) AND ("dateConfirmed" IS NULL) AND ("confirmationSource" IS NULL)) OR ((confirmed IS TRUE) AND ("dateConfirmed" IS NOT NULL) AND ("confirmationSource" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4753 (class 2606 OID 18391)
-- Name: Booking dateExpired_null_or_expired; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateExpired_null_or_expired" CHECK ((((expired IS FALSE) AND ("dateExpired" IS NULL)) OR ((expired IS TRUE) AND ("dateExpired" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4754 (class 2606 OID 18392)
-- Name: Booking dateRefused_null_or_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "dateRefused_null_or_refused" CHECK ((((refused IS FALSE) AND ("dateRefused" IS NULL) AND ("refusalReason" IS NULL)) OR ((refused IS TRUE) AND ("dateRefused" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4755 (class 2606 OID 18393)
-- Name: Booking date_order; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT date_order CHECK (((date < "moveInDate") AND ("moveInDate" <= "endDate") AND ("dateCanceled" > date) AND ("dateConfirmed" > date) AND ("dateExpired" > date))) NOT VALID;


--
-- TOC entry 4889 (class 2606 OID 18395)
-- Name: Discount discount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT discount_pkey PRIMARY KEY ("discountID");


--
-- TOC entry 4891 (class 2606 OID 18397)
-- Name: Discount discount_title_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT discount_title_unique UNIQUE (title, "facilityID");


--
-- TOC entry 4863 (class 2606 OID 18399)
-- Name: BookingDiscount discountofbooking_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT discountofbooking_pkey PRIMARY KEY ("discountID", "bookingID");


--
-- TOC entry 4839 (class 2606 OID 18400)
-- Name: ValidationCode email_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT email_format CHECK (((email)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text)) NOT VALID;


--
-- TOC entry 4949 (class 2606 OID 18402)
-- Name: NewsletterMember email_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."NewsletterMember"
    ADD CONSTRAINT email_unique UNIQUE (email);


--
-- TOC entry 4771 (class 2606 OID 18403)
-- Name: Call endTime_greater_than_startTime; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "endTime_greater_than_startTime" CHECK ((("endTime" IS NULL) OR ("endTime" >= "startTime"))) NOT VALID;


--
-- TOC entry 4911 (class 2606 OID 18405)
-- Name: FacilityImage facility_image_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT facility_image_unique PRIMARY KEY ("facilityID", "imageID");


--
-- TOC entry 4899 (class 2606 OID 18407)
-- Name: Facility facility_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT facility_pkey PRIMARY KEY ("facilityID");


--
-- TOC entry 4905 (class 2606 OID 18409)
-- Name: FacilityDiscount facilitydiscount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT facilitydiscount_pkey PRIMARY KEY ("facilityDiscountID");


--
-- TOC entry 4917 (class 2606 OID 18411)
-- Name: FacilityType facilitytype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT facilitytype_pkey PRIMARY KEY ("facilityTypeID");


--
-- TOC entry 4829 (class 2606 OID 18412)
-- Name: StorageTypeMatch features_or_inactive; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."StorageTypeMatch"
    ADD CONSTRAINT features_or_inactive CHECK (((features IS NOT NULL) OR (active IS FALSE))) NOT VALID;


--
-- TOC entry 4925 (class 2606 OID 18414)
-- Name: Image image_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Image"
    ADD CONSTRAINT image_pkey PRIMARY KEY ("imageID");


--
-- TOC entry 4790 (class 2606 OID 18415)
-- Name: Email initiator_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Email"
    ADD CONSTRAINT initiator_dependence CHECK (((((initiator)::text = 'customer'::text) IS TRUE) OR (("bookingReasonID" IS NULL) AND ("contactInfoShared" IS NOT TRUE) AND ("storedItems" IS NULL)))) NOT VALID;


--
-- TOC entry 4772 (class 2606 OID 18416)
-- Name: Call initiator_value; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT initiator_value CHECK ((((initiator)::text = 'customer'::text) OR ((initiator)::text = 'facility'::text))) NOT VALID;


--
-- TOC entry 4929 (class 2606 OID 18418)
-- Name: Insurance insurance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Insurance"
    ADD CONSTRAINT insurance_pkey PRIMARY KEY ("facilityTypeID", "monthlyFee", coverage);


--
-- TOC entry 4757 (class 2606 OID 18419)
-- Name: Booking isRequest_or_not_approved; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "isRequest_or_not_approved" CHECK ((("isRequest" IS TRUE) OR ((approved IS FALSE) AND ("dateApproved" IS NULL)))) NOT VALID;


--
-- TOC entry 4758 (class 2606 OID 18420)
-- Name: Booking isRequest_or_not_refused; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "isRequest_or_not_refused" CHECK ((("isRequest" IS TRUE) OR ((refused IS FALSE) AND ("dateRefused" IS NULL)))) NOT VALID;


--
-- TOC entry 4773 (class 2606 OID 18421)
-- Name: Call language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4796 (class 2606 OID 18422)
-- Name: Facility language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Facility"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4783 (class 2606 OID 18423)
-- Name: Customer language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4815 (class 2606 OID 18424)
-- Name: NewsletterMember language_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."NewsletterMember"
    ADD CONSTRAINT language_format CHECK (((language)::text ~* '^[a-z]{2}-[A-Z]{2}$'::text)) NOT VALID;


--
-- TOC entry 4774 (class 2606 OID 18425)
-- Name: Call leftMessage_or_unanswered; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "leftMessage_or_unanswered" CHECK ((("leftMessage" IS FALSE) OR (((status)::text = 'unanswered'::text) OR (((status)::text = 'busy'::text) AND (voicemail IS TRUE))))) NOT VALID;


--
-- TOC entry 4780 (class 2606 OID 18426)
-- Name: Country measurementSystem_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Country"
    ADD CONSTRAINT "measurementSystem_valid" CHECK (((("measurementSystem")::text = 'metric'::text) OR (("measurementSystem")::text = 'imperial'::text))) NOT VALID;


--
-- TOC entry 4784 (class 2606 OID 18427)
-- Name: Customer measurementSystem_valid; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT "measurementSystem_valid" CHECK (((("measurementSystem")::text = 'metric'::text) OR (("measurementSystem")::text = 'imperial'::text))) NOT VALID;


--
-- TOC entry 4759 (class 2606 OID 18428)
-- Name: Booking not_contactInfoShared_or_not_phoneNumberActive; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "not_contactInfoShared_or_not_phoneNumberActive" CHECK ((("contactInfoShared" IS FALSE) OR ("phoneNumberActive" IS FALSE))) NOT VALID;


--
-- TOC entry 4775 (class 2606 OID 18429)
-- Name: Call outputReason_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "outputReason_dependence" CHECK ((("outputReason" IS NOT NULL) OR ((("bookingConfirmed" IS NULL) AND ("contactInfoShared" IS NULL)) OR (voicemail IS TRUE)))) NOT VALID;


--
-- TOC entry 4761 (class 2606 OID 18430)
-- Name: Booking pending_or_expired_or_confirmed_or_refused_or_aborted; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT pending_or_expired_or_confirmed_or_refused_or_aborted CHECK ((((pending IS TRUE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS TRUE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS TRUE) AND (refused IS FALSE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS TRUE) AND (aborted IS FALSE)) OR ((pending IS FALSE) AND (expired IS FALSE) AND (confirmed IS FALSE) AND (refused IS FALSE) AND (aborted IS TRUE)))) NOT VALID;


--
-- TOC entry 4762 (class 2606 OID 18431)
-- Name: Booking phoneNumberActive_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Booking"
    ADD CONSTRAINT "phoneNumberActive_dependence" CHECK ((("phoneNumberActive" IS FALSE) OR ((confirmed IS FALSE) AND (canceled IS FALSE) AND (expired IS FALSE) AND (refused IS FALSE) AND (aborted IS FALSE)))) NOT VALID;


--
-- TOC entry 4800 (class 2606 OID 18432)
-- Name: FacilityPhoneNumber phoneNumber_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."FacilityPhoneNumber"
    ADD CONSTRAINT "phoneNumber_format" CHECK ((("phoneNumber")::text ~ '^\+'::text)) NOT VALID;


--
-- TOC entry 4785 (class 2606 OID 18433)
-- Name: Customer phoneNumber_format; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT "phoneNumber_format" CHECK ((("phoneNumber")::text ~ '^\+'::text)) NOT VALID;


--
-- TOC entry 4841 (class 2606 OID 18434)
-- Name: ValidationCode phoneNumber_or_email; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT "phoneNumber_or_email" CHECK ((("phoneNumber" IS NOT NULL) OR (email IS NOT NULL))) NOT VALID;


--
-- TOC entry 4786 (class 2606 OID 18435)
-- Name: Customer phone_number_dependencies; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Customer"
    ADD CONSTRAINT phone_number_dependencies CHECK (((("phoneNumber" IS NULL) AND ("formattedPhoneNumber" IS NULL) AND ("dialCode" IS NULL)) OR (("phoneNumber" IS NOT NULL) AND ("formattedPhoneNumber" IS NOT NULL) AND ("dialCode" IS NOT NULL)))) NOT VALID;


--
-- TOC entry 4955 (class 2606 OID 18437)
-- Name: PostalCode placeID_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT "placeID_unique" UNIQUE ("placeID");


--
-- TOC entry 4901 (class 2606 OID 18439)
-- Name: Facility placeid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT placeid_unique UNIQUE ("placeID");


--
-- TOC entry 4957 (class 2606 OID 18441)
-- Name: PostalCode postal_code_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT postal_code_unique UNIQUE ("postalCode", "cityID");


--
-- TOC entry 4959 (class 2606 OID 18443)
-- Name: PostalCode postalcode_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT postalcode_pkey PRIMARY KEY ("postalCodeID");


--
-- TOC entry 5003 (class 2606 OID 18445)
-- Name: Unit price_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT price_unique UNIQUE NULLS NOT DISTINCT (covered, "carAccess", heating, "heatedFloor", "airConditioning", "noStairs", "electronicKey", h24, width, length, height, "floorNb", "narrowestPassage", motorcycle, car, rv, boat, "facilityTypeID", "rentalDeposit", "accessCode", "possiblyVehicle", outdoor, snowmobile, trailer, electricity, "externalID");


--
-- TOC entry 4776 (class 2606 OID 18446)
-- Name: Call recording_dependence; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT recording_dependence CHECK ((("recordingID" IS NOT NULL) OR (("leftMessage" IS FALSE) AND ("customerSentiment" IS NULL) AND ("agentSentiment" IS NULL) AND ("bookingConfirmed" IS NULL) AND ("outputReason" IS NULL) AND ("contactInfoShared" IS NULL)))) NOT VALID;


--
-- TOC entry 4842 (class 2606 OID 18447)
-- Name: ValidationCode remainingTrials_below_3; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."ValidationCode"
    ADD CONSTRAINT "remainingTrials_below_3" CHECK (("remainingTrials" <= 3)) NOT VALID;


--
-- TOC entry 4961 (class 2606 OID 18449)
-- Name: Reminder reminder_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT reminder_pk PRIMARY KEY ("reminderID");


--
-- TOC entry 4793 (class 2606 OID 18450)
-- Name: Email sentiment_interval; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Email"
    ADD CONSTRAINT sentiment_interval CHECK (((sentiment >= ('-5'::integer)::numeric) AND (sentiment <= (5)::numeric))) NOT VALID;


--
-- TOC entry 4971 (class 2606 OID 18452)
-- Name: SizeCategory sizecategory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SizeCategory"
    ADD CONSTRAINT sizecategory_pkey PRIMARY KEY ("sizeCategoryID");


--
-- TOC entry 4777 (class 2606 OID 18453)
-- Name: Call status_value; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT status_value CHECK ((((status)::text = 'ongoing'::text) OR ((status)::text = 'answered'::text) OR ((status)::text = 'unanswered'::text))) NOT VALID;


--
-- TOC entry 4977 (class 2606 OID 18455)
-- Name: StorageType storagetype_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StorageType"
    ADD CONSTRAINT storagetype_pkey PRIMARY KEY ("storageTypeID");


--
-- TOC entry 4999 (class 2606 OID 18457)
-- Name: Tag tag_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Tag"
    ADD CONSTRAINT tag_pkey PRIMARY KEY ("tagID");


--
-- TOC entry 4778 (class 2606 OID 18458)
-- Name: Call twilioCallID_different_from_twilioParentCallID; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Call"
    ADD CONSTRAINT "twilioCallID_different_from_twilioParentCallID" CHECK ((("twilioCallID")::text <> ("twilioParentCallID")::text)) NOT VALID;


--
-- TOC entry 4919 (class 2606 OID 18460)
-- Name: FacilityType type_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT type_unique UNIQUE ("facilityID", "storageTypeID");


--
-- TOC entry 5005 (class 2606 OID 18462)
-- Name: Unit unit_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT unit_unique UNIQUE NULLS NOT DISTINCT (covered, "carAccess", heating, "heatedFloor", "airConditioning", "noStairs", "electronicKey", h24, width, length, height, "floorNb", "narrowestPassage", "regularPrice", "discountedPrice", motorcycle, car, rv, boat, "facilityTypeID", "rentalDeposit", "accessCode", "possiblyVehicle", outdoor, snowmobile, trailer, electricity, "externalID");


--
-- TOC entry 5015 (class 2606 OID 18464)
-- Name: UnitDiscount unitdiscount_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT unitdiscount_pkey PRIMARY KEY ("discountID", "unitID");


--
-- TOC entry 4963 (class 2606 OID 18466)
-- Name: Reminder user_and_facility_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT user_and_facility_unique UNIQUE ("userID", "facilityID");


--
-- TOC entry 4859 (class 1259 OID 18467)
-- Name: fki_unitid_fkey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fki_unitid_fkey ON public."Booking" USING btree ("unitID");


--
-- TOC entry 5026 (class 0 OID 0)
-- Name: AccessHours_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public."OpeningHours_pkey" ATTACH PARTITION public."AccessHours_pkey";


--
-- TOC entry 5027 (class 0 OID 0)
-- Name: Neighborhoodd_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."Neighborhoodd_pkey";


--
-- TOC entry 5028 (class 0 OID 0)
-- Name: Neighborhoodd_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.region_unique ATTACH PARTITION public."Neighborhoodd_placeID_type_key";


--
-- TOC entry 5029 (class 0 OID 0)
-- Name: OfficeHours_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public."OpeningHours_pkey" ATTACH PARTITION public."OfficeHours_pkey";


--
-- TOC entry 5030 (class 0 OID 0)
-- Name: SuperArea1_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."SuperArea1_pkey";


--
-- TOC entry 5031 (class 0 OID 0)
-- Name: SuperArea1_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.region_unique ATTACH PARTITION public."SuperArea1_placeID_type_key";


--
-- TOC entry 5032 (class 0 OID 0)
-- Name: SuperArea2_pkey; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public."Region_pkey" ATTACH PARTITION public."SuperArea2_pkey";


--
-- TOC entry 5033 (class 0 OID 0)
-- Name: SuperArea2_placeID_type_key; Type: INDEX ATTACH; Schema: public; Owner: postgres
--

ALTER INDEX public.region_unique ATTACH PARTITION public."SuperArea2_placeID_type_key";


--
-- TOC entry 5096 (class 2620 OID 18468)
-- Name: Address address_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER address_replace_empty_strings BEFORE INSERT OR UPDATE OF "apartmentNumber", "streetNumber", "streetName" ON public."Address" FOR EACH ROW EXECUTE FUNCTION public.replace_address_empty_strings();


--
-- TOC entry 5097 (class 2620 OID 18469)
-- Name: Booking booking_check_is_request; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_check_is_request BEFORE INSERT OR UPDATE OF "unitID" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_booking_is_request();


--
-- TOC entry 5098 (class 2620 OID 18470)
-- Name: Booking booking_check_move_in_date; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_check_move_in_date BEFORE INSERT OR UPDATE OF "moveInDate" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_booking_move_in_date();


--
-- TOC entry 5099 (class 2620 OID 18471)
-- Name: Booking booking_check_primary_customer; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_check_primary_customer BEFORE INSERT OR UPDATE OF "primaryBookingID", "customerID" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_primary_booking_customer();


--
-- TOC entry 5100 (class 2620 OID 18472)
-- Name: Booking booking_copy_price_info; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_copy_price_info BEFORE INSERT ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.copy_price_info();


--
-- TOC entry 5101 (class 2620 OID 18473)
-- Name: Booking booking_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_delete_dependencies BEFORE DELETE ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.delete_booking_dependencies();


--
-- TOC entry 5102 (class 2620 OID 18474)
-- Name: Booking booking_insert_discounts; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_insert_discounts AFTER INSERT ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.insert_booking_discounts();


--
-- TOC entry 5103 (class 2620 OID 18475)
-- Name: Booking booking_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_replace_empty_strings BEFORE INSERT OR UPDATE OF "cancelReason", review ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.replace_booking_empty_strings();


--
-- TOC entry 5104 (class 2620 OID 18476)
-- Name: Booking booking_update_aborted; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_aborted BEFORE INSERT OR UPDATE OF aborted ON public."Booking" FOR EACH ROW WHEN ((new.aborted IS TRUE)) EXECUTE FUNCTION public.update_booking_aborted();


--
-- TOC entry 5105 (class 2620 OID 18477)
-- Name: Booking booking_update_approved; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_approved BEFORE INSERT OR UPDATE OF approved ON public."Booking" FOR EACH ROW WHEN ((new.approved IS TRUE)) EXECUTE FUNCTION public.update_booking_approved();


--
-- TOC entry 5106 (class 2620 OID 18478)
-- Name: Booking booking_update_canceled; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_canceled BEFORE INSERT OR UPDATE OF canceled ON public."Booking" FOR EACH ROW WHEN ((new.canceled IS TRUE)) EXECUTE FUNCTION public.update_booking_canceled();


--
-- TOC entry 5107 (class 2620 OID 18479)
-- Name: Booking booking_update_confirmed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_confirmed BEFORE INSERT OR UPDATE OF confirmed ON public."Booking" FOR EACH ROW WHEN ((new.confirmed IS TRUE)) EXECUTE FUNCTION public.update_booking_confirmed();


--
-- TOC entry 5108 (class 2620 OID 18480)
-- Name: Booking booking_update_expired; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_expired BEFORE INSERT OR UPDATE OF expired ON public."Booking" FOR EACH ROW WHEN ((new.expired IS TRUE)) EXECUTE FUNCTION public.update_booking_expired();


--
-- TOC entry 5109 (class 2620 OID 18481)
-- Name: Booking booking_update_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_masked_phone_number_availability AFTER INSERT OR DELETE OR UPDATE OF "maskedPhoneNumber", "phoneNumberActive", expired, canceled, confirmed, refused, aborted ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.update_booking_masked_phone_number_availability();


--
-- TOC entry 5110 (class 2620 OID 18482)
-- Name: Booking booking_update_refused; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER booking_update_refused BEFORE INSERT OR UPDATE OF refused ON public."Booking" FOR EACH ROW WHEN ((new.refused IS TRUE)) EXECUTE FUNCTION public.update_booking_refused();


--
-- TOC entry 5112 (class 2620 OID 18483)
-- Name: Call call_add_bookings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER call_add_bookings AFTER INSERT ON public."Call" FOR EACH ROW WHEN (((new.called IS NOT NULL) AND (new.caller IS NOT NULL))) EXECUTE FUNCTION public.add_call_bookings();


--
-- TOC entry 5113 (class 2620 OID 18484)
-- Name: Call call_add_facility_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER call_add_facility_id BEFORE INSERT ON public."Call" FOR EACH ROW WHEN (((new.called IS NOT NULL) AND (new.caller IS NOT NULL))) EXECUTE FUNCTION public.add_call_facility_id();


--
-- TOC entry 5114 (class 2620 OID 18485)
-- Name: Call call_update_booking_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER call_update_booking_status AFTER INSERT OR UPDATE OF "bookingConfirmed", "contactInfoShared" ON public."Call" FOR EACH ROW WHEN (((new."bookingConfirmed" IS TRUE) OR (new."contactInfoShared" IS TRUE))) EXECUTE FUNCTION public.update_call_booking_status();


--
-- TOC entry 5115 (class 2620 OID 18486)
-- Name: Call call_update_end_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER call_update_end_time BEFORE INSERT OR UPDATE OF "endTime", status ON public."Call" FOR EACH ROW WHEN ((((new.status)::text = 'unanswered'::text) AND (new."endTime" IS NULL))) EXECUTE FUNCTION public.update_call_end_time();


--
-- TOC entry 5111 (class 2620 OID 18487)
-- Name: Booking check_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_masked_phone_number_availability BEFORE INSERT OR UPDATE OF "maskedPhoneNumber" ON public."Booking" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availabiity();


--
-- TOC entry 5116 (class 2620 OID 18488)
-- Name: City city_check_timezone; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER city_check_timezone BEFORE INSERT OR UPDATE OF timezone ON public."City" FOR EACH ROW EXECUTE FUNCTION public.check_timezone();


--
-- TOC entry 5117 (class 2620 OID 18489)
-- Name: City city_delete_independencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER city_delete_independencies AFTER DELETE ON public."City" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5118 (class 2620 OID 18490)
-- Name: Country country_delete_independencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER country_delete_independencies AFTER DELETE ON public."Country" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5119 (class 2620 OID 18491)
-- Name: Customer customer_add_to_newsletter; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER customer_add_to_newsletter AFTER INSERT ON public."Customer" FOR EACH ROW WHEN (((new.newsletter IS TRUE) AND (new.email IS NOT NULL))) EXECUTE FUNCTION public.add_customer_to_newsletter();


--
-- TOC entry 5120 (class 2620 OID 18492)
-- Name: Customer customer_update_newsletter_email; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER customer_update_newsletter_email AFTER UPDATE OF email ON public."Customer" FOR EACH ROW EXECUTE FUNCTION public.update_customer_newsletter_email();


--
-- TOC entry 5121 (class 2620 OID 18493)
-- Name: Customer customer_update_newsletter_language; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER customer_update_newsletter_language AFTER INSERT OR UPDATE OF language ON public."Customer" FOR EACH ROW EXECUTE FUNCTION public.update_customer_newsletter_language();


--
-- TOC entry 5122 (class 2620 OID 18494)
-- Name: Discount discount_check_activity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER discount_check_activity BEFORE INSERT OR UPDATE ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.check_discount_activity();


--
-- TOC entry 5123 (class 2620 OID 18495)
-- Name: Discount discount_check_expiration_date; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER discount_check_expiration_date BEFORE INSERT OR UPDATE OF "expirationDate" ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.check_discount_expiration_date();


--
-- TOC entry 5124 (class 2620 OID 18496)
-- Name: Discount discount_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER discount_delete_dependencies BEFORE DELETE ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.delete_discount_dependencies();


--
-- TOC entry 5125 (class 2620 OID 18497)
-- Name: Discount discount_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER discount_replace_empty_strings BEFORE INSERT OR UPDATE OF terms ON public."Discount" FOR EACH ROW EXECUTE FUNCTION public.replace_discount_empty_strings();


--
-- TOC entry 5126 (class 2620 OID 18498)
-- Name: Email email_check_is_allowed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER email_check_is_allowed BEFORE INSERT OR UPDATE OF allowed ON public."Email" FOR EACH ROW EXECUTE FUNCTION public.check_email_is_allowed();


--
-- TOC entry 5127 (class 2620 OID 18499)
-- Name: Email email_update_booking_confirmed; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER email_update_booking_confirmed BEFORE UPDATE OF "linkClicked" ON public."Email" FOR EACH ROW WHEN (((old."linkClicked" IS FALSE) AND (new."linkClicked" IS TRUE))) EXECUTE FUNCTION public.update_email_booking_confirmed();


--
-- TOC entry 5128 (class 2620 OID 18500)
-- Name: Email email_update_booking_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER email_update_booking_status AFTER INSERT OR UPDATE OF "bookingConfirmed", "contactInfoShared", "bookingAborted" ON public."Email" FOR EACH ROW WHEN (((new."bookingConfirmed" IS TRUE) OR (new."bookingAborted" IS TRUE) OR (new."contactInfoShared" IS TRUE))) EXECUTE FUNCTION public.update_email_booking_status();


--
-- TOC entry 5129 (class 2620 OID 18501)
-- Name: EpicenterCity epicenter_city_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER epicenter_city_delete_dependencies BEFORE DELETE ON public."EpicenterCity" FOR EACH ROW EXECUTE FUNCTION public.delete_epicenter_city_dependencies();


--
-- TOC entry 5130 (class 2620 OID 18502)
-- Name: EpicenterCity epicenter_city_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER epicenter_city_replace_empty_strings BEFORE INSERT OR UPDATE OF token ON public."EpicenterCity" FOR EACH ROW EXECUTE FUNCTION public.replace_epicenter_city_empty_strings();


--
-- TOC entry 5131 (class 2620 OID 18503)
-- Name: Facility epicenter_update_radius; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER epicenter_update_radius AFTER INSERT OR DELETE OR UPDATE OF "addressID", "epicenterCityID" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.update_epicenter_radius();


--
-- TOC entry 5132 (class 2620 OID 18504)
-- Name: Facility facility_add_last_update_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_add_last_update_time BEFORE INSERT OR UPDATE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.add_facility_last_update_time();


--
-- TOC entry 5133 (class 2620 OID 18505)
-- Name: Facility facility_add_short_title; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_add_short_title BEFORE INSERT OR UPDATE OF title, "shortTitle" ON public."Facility" FOR EACH ROW WHEN (((new.title IS NOT NULL) AND (new."shortTitle" IS NULL))) EXECUTE FUNCTION public.add_facility_short_title();


--
-- TOC entry 5134 (class 2620 OID 18506)
-- Name: Facility facility_check_info_verified_synchronization_config; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_info_verified_synchronization_config BEFORE INSERT OR UPDATE OF "infoVerified" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_info_verified_synchronization_config();


--
-- TOC entry 5135 (class 2620 OID 18507)
-- Name: Facility facility_check_masked_phone_number_and_partner; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_masked_phone_number_and_partner BEFORE INSERT OR UPDATE OF partner ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_masked_phone_number_and_partner();


--
-- TOC entry 5136 (class 2620 OID 18508)
-- Name: Facility facility_check_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_masked_phone_number_availability BEFORE INSERT OR UPDATE OF "maskedPhoneNumber" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availabiity();


--
-- TOC entry 5137 (class 2620 OID 18509)
-- Name: Facility facility_check_status; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_status BEFORE INSERT OR UPDATE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_status();


--
-- TOC entry 5174 (class 2620 OID 18510)
-- Name: SynchronizationConfig facility_check_synchronization; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_synchronization AFTER INSERT OR UPDATE OF enabled ON public."SynchronizationConfig" FOR EACH ROW WHEN ((new.enabled IS TRUE)) EXECUTE FUNCTION public.check_facility_synchronisation();


--
-- TOC entry 5138 (class 2620 OID 18511)
-- Name: Facility facility_check_title; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_check_title BEFORE INSERT OR UPDATE OF title ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.check_facility_title();


--
-- TOC entry 5139 (class 2620 OID 18512)
-- Name: Facility facility_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_delete_dependencies BEFORE DELETE ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.delete_facility_dependencies();


--
-- TOC entry 5143 (class 2620 OID 18513)
-- Name: FacilityDiscount facility_discount_check_activity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER facility_discount_check_activity AFTER INSERT OR DELETE ON public."FacilityDiscount" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.check_facility_discount_activity();


--
-- TOC entry 5144 (class 2620 OID 18515)
-- Name: FacilityDiscount facility_discount_check_apparition; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_discount_check_apparition BEFORE INSERT OR UPDATE ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NULL) AND (new."storageTypeID" IS NULL))) EXECUTE FUNCTION public.check_facility_discount_apparition();


--
-- TOC entry 5145 (class 2620 OID 18516)
-- Name: FacilityDiscount facility_discount_insert_category; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_discount_insert_category AFTER INSERT OR UPDATE OF "sizeCategoryID", "storageTypeID" ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NOT NULL) OR (new."storageTypeID" IS NOT NULL))) EXECUTE FUNCTION public.check_others_for_category_discounts();


--
-- TOC entry 5146 (class 2620 OID 18517)
-- Name: FacilityDiscount facility_discount_insert_global; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_discount_insert_global AFTER INSERT OR UPDATE OF "sizeCategoryID", "storageTypeID" ON public."FacilityDiscount" FOR EACH ROW WHEN (((new."sizeCategoryID" IS NULL) AND (new."storageTypeID" IS NULL))) EXECUTE FUNCTION public.check_others_for_global_discounts();


--
-- TOC entry 5147 (class 2620 OID 18518)
-- Name: FacilityImage facility_image_add_position; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_image_add_position BEFORE INSERT OR UPDATE ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.add_facility_image_position();


--
-- TOC entry 5148 (class 2620 OID 18519)
-- Name: FacilityImage facility_image_check_position; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_image_check_position AFTER INSERT OR UPDATE OF "position" ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.check_facility_image_position();


--
-- TOC entry 5149 (class 2620 OID 18520)
-- Name: FacilityImage facility_image_update_position; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_image_update_position AFTER DELETE ON public."FacilityImage" FOR EACH ROW EXECUTE FUNCTION public.update_facility_image_position();


--
-- TOC entry 5140 (class 2620 OID 18521)
-- Name: Facility facility_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_replace_empty_strings BEFORE INSERT OR UPDATE OF "placeID", author, description, title, website, "externalID", language, "welcomeNote" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.replace_facility_empty_strings();


--
-- TOC entry 5141 (class 2620 OID 18522)
-- Name: Facility facility_save_info_verified_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_save_info_verified_history AFTER UPDATE OF "infoVerified" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.save_info_verified_history();


--
-- TOC entry 5150 (class 2620 OID 18523)
-- Name: FacilityType facility_type_check_alarm; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_type_check_alarm AFTER INSERT OR UPDATE OF "alarmInEachUnit", "alarmInSomeUnits" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_alarm();


--
-- TOC entry 5151 (class 2620 OID 18524)
-- Name: FacilityType facility_type_check_prorata; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_type_check_prorata BEFORE INSERT OR UPDATE OF "firstMonthProrata", "billingDate" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_prorata();


--
-- TOC entry 5152 (class 2620 OID 18525)
-- Name: FacilityType facility_type_check_some; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_type_check_some AFTER INSERT OR UPDATE OF "someHeating", "someAirConditioning", "someHeatedFloor" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_some();


--
-- TOC entry 5153 (class 2620 OID 18526)
-- Name: FacilityType facility_type_check_terms; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_type_check_terms BEFORE INSERT OR UPDATE OF "monthlyBilling", "billingFrequency", "billingOnMoveInDate", "billingDate", "minBookingDays", "minBookingMonths" ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.check_facility_type_terms();


--
-- TOC entry 5154 (class 2620 OID 18527)
-- Name: FacilityType facility_type_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_type_delete_dependencies BEFORE DELETE ON public."FacilityType" FOR EACH ROW EXECUTE FUNCTION public.delete_facility_type_dependencies();


--
-- TOC entry 5142 (class 2620 OID 18528)
-- Name: Facility facility_update_masked_phone_number_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_update_masked_phone_number_availability AFTER INSERT OR DELETE OR UPDATE OF "maskedPhoneNumber" ON public."Facility" FOR EACH ROW EXECUTE FUNCTION public.update_facility_masked_phone_number_availability();


--
-- TOC entry 5155 (class 2620 OID 18529)
-- Name: FacilityUser facility_user_add_locale; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER facility_user_add_locale BEFORE INSERT OR UPDATE ON public."FacilityUser" FOR EACH ROW EXECUTE FUNCTION public.add_facility_user_locale();


--
-- TOC entry 5157 (class 2620 OID 18530)
-- Name: FocusSession focus_session_check_start_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER focus_session_check_start_time BEFORE INSERT ON public."FocusSession" FOR EACH ROW WHEN ((new."startTime" IS NOT NULL)) EXECUTE FUNCTION public.check_focus_session_start_time();


--
-- TOC entry 5158 (class 2620 OID 18531)
-- Name: Image image_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER image_delete_dependencies BEFORE DELETE ON public."Image" FOR EACH ROW EXECUTE FUNCTION public.delete_image_dependencies();


--
-- TOC entry 5159 (class 2620 OID 18532)
-- Name: Image image_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER image_replace_empty_strings BEFORE INSERT OR UPDATE OF "authorName", "authorProfile" ON public."Image" FOR EACH ROW EXECUTE FUNCTION public.replace_image_empty_strings();


--
-- TOC entry 5161 (class 2620 OID 18533)
-- Name: Insurance insurance_check_monthly_fee; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insurance_check_monthly_fee BEFORE INSERT OR UPDATE OF "monthlyFee", coverage ON public."Insurance" FOR EACH ROW EXECUTE FUNCTION public.check_insurance_monthly_fee();


--
-- TOC entry 5162 (class 2620 OID 18534)
-- Name: Insurance insurance_replace_empty_strings; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER insurance_replace_empty_strings BEFORE INSERT OR UPDATE OF terms ON public."Insurance" FOR EACH ROW EXECUTE FUNCTION public.replace_insurance_empty_strings();


--
-- TOC entry 5163 (class 2620 OID 18535)
-- Name: MaskedPhoneNumber masked_phone_number_check_availability_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER masked_phone_number_check_availability_dependencies BEFORE INSERT OR UPDATE OF available ON public."MaskedPhoneNumber" FOR EACH ROW EXECUTE FUNCTION public.check_masked_phone_number_availability_dependencies();


--
-- TOC entry 5164 (class 2620 OID 18536)
-- Name: MaskedPhoneNumber masked_phone_number_save_availability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER masked_phone_number_save_availability AFTER INSERT OR UPDATE OF available ON public."MaskedPhoneNumber" FOR EACH ROW EXECUTE FUNCTION public.save_masked_phone_number_availability_history();


--
-- TOC entry 5095 (class 2620 OID 18537)
-- Name: OpeningHours opening_hours_check_logic; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER opening_hours_check_logic BEFORE INSERT OR UPDATE ON public."OpeningHours" FOR EACH ROW EXECUTE FUNCTION public.check_opening_hours_logic();


--
-- TOC entry 5160 (class 2620 OID 18540)
-- Name: InfoVerifiedHistory reminder_update_last_update_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER reminder_update_last_update_time AFTER INSERT ON public."InfoVerifiedHistory" FOR EACH ROW EXECUTE FUNCTION public.update_reminder_last_update_time();


--
-- TOC entry 5167 (class 2620 OID 18541)
-- Name: Session session_check_change; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_check_change AFTER INSERT OR UPDATE OF "latestActivityTime" ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.check_session_change();


--
-- TOC entry 5168 (class 2620 OID 18542)
-- Name: Session session_check_lastest_activity_time; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_check_lastest_activity_time BEFORE UPDATE OF "latestActivityTime" ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.check_session_lastest_activity_time();


--
-- TOC entry 5169 (class 2620 OID 18543)
-- Name: Session session_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_delete_dependencies BEFORE DELETE ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.delete_session_dependencies();


--
-- TOC entry 5170 (class 2620 OID 18544)
-- Name: Session session_delete_oldest; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_delete_oldest AFTER INSERT ON public."Session" FOR EACH ROW EXECUTE FUNCTION public.delete_session_oldest();


--
-- TOC entry 5171 (class 2620 OID 18545)
-- Name: Session session_end_active; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_end_active AFTER UPDATE OF "endTime" ON public."Session" FOR EACH ROW WHEN ((new."endTime" IS NOT NULL)) EXECUTE FUNCTION public.end_session_active();


--
-- TOC entry 5172 (class 2620 OID 18546)
-- Name: SessionFacility session_facility_check_focus_duration; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_facility_check_focus_duration BEFORE INSERT OR UPDATE OF "focusDuration", "startTime", "endTime" ON public."SessionFacility" FOR EACH ROW WHEN (((new."focusDuration" IS NOT NULL) AND (new."startTime" IS NOT NULL) AND (new."endTime" IS NOT NULL))) EXECUTE FUNCTION public.check_session_facility_focus_duration();


--
-- TOC entry 5173 (class 2620 OID 18547)
-- Name: SessionFacility session_facility_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER session_facility_delete_dependencies BEFORE DELETE ON public."SessionFacility" FOR EACH ROW EXECUTE FUNCTION public.delete_session_facility_dependencies();


--
-- TOC entry 5165 (class 2620 OID 18548)
-- Name: Region superarea_delete_image_independencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER superarea_delete_image_independencies AFTER DELETE ON public."Region" FOR EACH ROW EXECUTE FUNCTION public.delete_image_independencies();


--
-- TOC entry 5175 (class 2620 OID 18552)
-- Name: SynchronizationConfig synchronization_update_config_info_verified; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER synchronization_update_config_info_verified BEFORE INSERT OR UPDATE OF enabled ON public."SynchronizationConfig" FOR EACH ROW EXECUTE FUNCTION public.update_synchronization_config_info_verified();


--
-- TOC entry 5176 (class 2620 OID 18553)
-- Name: Unit unit_check_archived; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_archived BEFORE INSERT OR UPDATE OF archived ON public."Unit" FOR EACH ROW WHEN ((new.archived IS TRUE)) EXECUTE FUNCTION public.check_unit_archived();


--
-- TOC entry 5177 (class 2620 OID 18554)
-- Name: Unit unit_check_floor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_floor BEFORE INSERT OR UPDATE OF "noStairs", "floorNb" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_floor();


--
-- TOC entry 5178 (class 2620 OID 18555)
-- Name: Unit unit_check_outdoor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_outdoor BEFORE INSERT OR UPDATE OF heating, "heatedFloor", "airConditioning", "facilityTypeID", outdoor ON public."Unit" FOR EACH ROW WHEN ((new.outdoor IS TRUE)) EXECUTE FUNCTION public.check_unit_outdoor();


--
-- TOC entry 5179 (class 2620 OID 18556)
-- Name: Unit unit_check_price; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_price BEFORE INSERT OR UPDATE OF "regularPrice", "discountedPrice" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_price();


--
-- TOC entry 5180 (class 2620 OID 18557)
-- Name: Unit unit_check_size; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_size BEFORE INSERT OR UPDATE OF "sizeCategoryID", width, length, "facilityTypeID" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_size();


--
-- TOC entry 5181 (class 2620 OID 18558)
-- Name: Unit unit_check_some; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_some AFTER INSERT OR UPDATE OF heating, "airConditioning" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_some();


--
-- TOC entry 5182 (class 2620 OID 18559)
-- Name: Unit unit_check_vehicles; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_check_vehicles BEFORE INSERT OR UPDATE OF motorcycle, car, rv, boat, "rentalDeposit" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.check_unit_vehicles();


--
-- TOC entry 5183 (class 2620 OID 18560)
-- Name: Unit unit_delete_dependencies; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_delete_dependencies BEFORE DELETE ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.delete_unit_dependencies();


--
-- TOC entry 5188 (class 2620 OID 18561)
-- Name: UnitDiscount unit_discount_check_activity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER unit_discount_check_activity AFTER INSERT OR DELETE ON public."UnitDiscount" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_activity();


--
-- TOC entry 5189 (class 2620 OID 18563)
-- Name: UnitDiscount unit_discount_check_apparition; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_discount_check_apparition BEFORE INSERT OR UPDATE ON public."UnitDiscount" FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_apparition();


--
-- TOC entry 5190 (class 2620 OID 18564)
-- Name: UnitDiscount unit_discount_check_facility_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_discount_check_facility_id BEFORE INSERT OR UPDATE ON public."UnitDiscount" FOR EACH ROW EXECUTE FUNCTION public.check_unit_discount_facility_id();


--
-- TOC entry 5184 (class 2620 OID 18565)
-- Name: Unit unit_save_archival_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_save_archival_history AFTER INSERT OR UPDATE OF archived ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_archival_history();


--
-- TOC entry 5185 (class 2620 OID 18566)
-- Name: Unit unit_save_availability_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_save_availability_history AFTER INSERT OR UPDATE OF available ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_availability_history();


--
-- TOC entry 5186 (class 2620 OID 18567)
-- Name: Unit unit_save_price_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_save_price_history AFTER INSERT OR UPDATE OF "regularPrice", "discountedPrice" ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_price_history();


--
-- TOC entry 5187 (class 2620 OID 18568)
-- Name: Unit unit_save_visibility_history; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unit_save_visibility_history AFTER INSERT OR UPDATE OF visible ON public."Unit" FOR EACH ROW EXECUTE FUNCTION public.save_unit_visibility_history();


--
-- TOC entry 5156 (class 2620 OID 18569)
-- Name: FacilityUser user_check_exist; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER user_check_exist BEFORE INSERT OR UPDATE ON public."FacilityUser" FOR EACH ROW EXECUTE FUNCTION public.check_user_exist();


--
-- TOC entry 5166 (class 2620 OID 18570)
-- Name: Reminder user_check_exist; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER user_check_exist BEFORE INSERT ON public."Reminder" FOR EACH ROW EXECUTE FUNCTION public.check_user_exist();


--
-- TOC entry 5040 (class 2606 OID 18571)
-- Name: BookingCall BookingCall_bookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_bookingID_fkey" FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5041 (class 2606 OID 18576)
-- Name: BookingCall BookingCall_callID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingCall"
    ADD CONSTRAINT "BookingCall_callID_fkey" FOREIGN KEY ("callID") REFERENCES public."Call"("callID");


--
-- TOC entry 5036 (class 2606 OID 18581)
-- Name: Booking Booking_maskedPhoneNumberID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_maskedPhoneNumberID_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5037 (class 2606 OID 18586)
-- Name: Booking Booking_primaryBookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT "Booking_primaryBookingID_fkey" FOREIGN KEY ("primaryBookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5044 (class 2606 OID 18591)
-- Name: Call Call_bookingReasonID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_bookingReasonID_fkey" FOREIGN KEY ("bookingReasonID") REFERENCES public."BookingReason"("bookingReasonID") NOT VALID;


--
-- TOC entry 5045 (class 2606 OID 18596)
-- Name: Call Call_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5046 (class 2606 OID 18601)
-- Name: Call Call_maskedPhoneNumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Call"
    ADD CONSTRAINT "Call_maskedPhoneNumber_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5047 (class 2606 OID 18606)
-- Name: City City_superArea1ID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "City_superArea1ID_fkey" FOREIGN KEY ("superArea1ID") REFERENCES public."SuperArea1"("regionID");


--
-- TOC entry 5048 (class 2606 OID 18611)
-- Name: City City_superArea2ID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT "City_superArea2ID_fkey" FOREIGN KEY ("superArea2ID") REFERENCES public."SuperArea2"("regionID");


--
-- TOC entry 5054 (class 2606 OID 18616)
-- Name: Email Email_bookingID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_bookingID_fkey" FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5055 (class 2606 OID 18621)
-- Name: Email Email_bookingReasonID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Email"
    ADD CONSTRAINT "Email_bookingReasonID_fkey" FOREIGN KEY ("bookingReasonID") REFERENCES public."BookingReason"("bookingReasonID") NOT VALID;


--
-- TOC entry 5064 (class 2606 OID 18626)
-- Name: FacilityEmail FacilityEmail_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityEmail"
    ADD CONSTRAINT "FacilityEmail_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5068 (class 2606 OID 18631)
-- Name: FacilityPhoneNumber FacilityPhoneNumber_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityPhoneNumber"
    ADD CONSTRAINT "FacilityPhoneNumber_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID") NOT VALID;


--
-- TOC entry 5069 (class 2606 OID 18636)
-- Name: FacilityTag FacilityTag_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5070 (class 2606 OID 18641)
-- Name: FacilityTag FacilityTag_tagID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityTag"
    ADD CONSTRAINT "FacilityTag_tagID_fkey" FOREIGN KEY ("tagID") REFERENCES public."Tag"("tagID");


--
-- TOC entry 5057 (class 2606 OID 18646)
-- Name: Facility Facility_maskedPhoneNumberID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT "Facility_maskedPhoneNumberID_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber") NOT VALID;


--
-- TOC entry 5058 (class 2606 OID 18651)
-- Name: Facility Facility_synchronizationConfigID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT "Facility_synchronizationConfigID_fkey" FOREIGN KEY ("synchronizationConfigID") REFERENCES public."SynchronizationConfig"("synchronizationConfigID") NOT VALID;


--
-- TOC entry 5077 (class 2606 OID 18656)
-- Name: MaskedPhoneNumberAvailabilityHistory MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MaskedPhoneNumberAvailabilityHistory"
    ADD CONSTRAINT "MaskedPhoneNumberAvailabilityHistory_maskedPhoneNumber_fkey" FOREIGN KEY ("maskedPhoneNumber") REFERENCES public."MaskedPhoneNumber"("maskedPhoneNumber");


--
-- TOC entry 5079 (class 2606 OID 18661)
-- Name: Note Note_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Note"
    ADD CONSTRAINT "Note_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5034 (class 2606 OID 18666)
-- Name: OpeningHours OpeningHours_facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."OpeningHours"
    ADD CONSTRAINT "OpeningHours_facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5080 (class 2606 OID 18677)
-- Name: PostalCode PostalCode_neighborhoodID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT "PostalCode_neighborhoodID_fkey" FOREIGN KEY ("neighborhoodID") REFERENCES public."Neighborhood"("regionID");


--
-- TOC entry 5078 (class 2606 OID 18682)
-- Name: Region Region_imageID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public."Region"
    ADD CONSTRAINT "Region_imageID_fkey" FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5083 (class 2606 OID 18696)
-- Name: SearchedCity SearchedCity_epicenterCityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SearchedCity"
    ADD CONSTRAINT "SearchedCity_epicenterCityID_fkey" FOREIGN KEY ("epicenterCityID") REFERENCES public."EpicenterCity"("epicenterCityID");


--
-- TOC entry 5086 (class 2606 OID 18701)
-- Name: StorageTypeMatch StorageTypeMatch_synchronizationConfigID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StorageTypeMatch"
    ADD CONSTRAINT "StorageTypeMatch_synchronizationConfigID_fkey" FOREIGN KEY ("synchronizationConfigID") REFERENCES public."SynchronizationConfig"("synchronizationConfigID");


--
-- TOC entry 5087 (class 2606 OID 18706)
-- Name: SynchronizationConfig SynchronizationConfig_softwareID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SynchronizationConfig"
    ADD CONSTRAINT "SynchronizationConfig_softwareID_fkey" FOREIGN KEY ("softwareID") REFERENCES public."Software"("softwareID") NOT VALID;


--
-- TOC entry 5089 (class 2606 OID 18711)
-- Name: UnitArchivalHistory UnitArchivalHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitArchivalHistory"
    ADD CONSTRAINT "UnitArchivalHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5090 (class 2606 OID 18716)
-- Name: UnitAvailabilityHistory UnitAvailabilityHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitAvailabilityHistory"
    ADD CONSTRAINT "UnitAvailabilityHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5093 (class 2606 OID 18721)
-- Name: UnitPriceHistory UnitPriceHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitPriceHistory"
    ADD CONSTRAINT "UnitPriceHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5094 (class 2606 OID 18726)
-- Name: UnitVisibilityHistory UnitVisibilityHistory_unitID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitVisibilityHistory"
    ADD CONSTRAINT "UnitVisibilityHistory_unitID_fkey" FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5059 (class 2606 OID 18731)
-- Name: Facility addressid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT addressid_fkey FOREIGN KEY ("addressID") REFERENCES public."Address"("addressID");


--
-- TOC entry 5042 (class 2606 OID 18736)
-- Name: BookingDiscount bookingid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT bookingid_fkey FOREIGN KEY ("bookingID") REFERENCES public."Booking"("bookingID");


--
-- TOC entry 5081 (class 2606 OID 18741)
-- Name: PostalCode cityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PostalCode"
    ADD CONSTRAINT cityid_fkey FOREIGN KEY ("cityID") REFERENCES public."City"("cityID");


--
-- TOC entry 5056 (class 2606 OID 18746)
-- Name: EpicenterCity cityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."EpicenterCity"
    ADD CONSTRAINT cityid_fkey FOREIGN KEY ("cityID") REFERENCES public."City"("cityID");


--
-- TOC entry 5049 (class 2606 OID 18751)
-- Name: City countryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT countryid_fkey FOREIGN KEY ("countryID") REFERENCES public."Country"("countryID");


--
-- TOC entry 5051 (class 2606 OID 18756)
-- Name: Country currencyid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT currencyid_fkey FOREIGN KEY ("currencyID") REFERENCES public."Currency"("currencyID");


--
-- TOC entry 5038 (class 2606 OID 18761)
-- Name: Booking customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT customerid_fkey FOREIGN KEY ("customerID") REFERENCES public."Customer"("customerID");


--
-- TOC entry 5061 (class 2606 OID 18766)
-- Name: FacilityDiscount discountid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT discountid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5043 (class 2606 OID 18771)
-- Name: BookingDiscount discountid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."BookingDiscount"
    ADD CONSTRAINT discountid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5091 (class 2606 OID 18776)
-- Name: UnitDiscount discoutid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT discoutid_fkey FOREIGN KEY ("discountID") REFERENCES public."Discount"("discountID");


--
-- TOC entry 5060 (class 2606 OID 18781)
-- Name: Facility epicentercityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Facility"
    ADD CONSTRAINT epicentercityid_fkey FOREIGN KEY ("epicenterCityID") REFERENCES public."EpicenterCity"("epicenterCityID");


--
-- TOC entry 5084 (class 2606 OID 18786)
-- Name: SessionFacility facilityID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "facilityID_fkey" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5082 (class 2606 OID 18791)
-- Name: Reminder facility_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Reminder"
    ADD CONSTRAINT facility_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5053 (class 2606 OID 18796)
-- Name: Discount facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Discount"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5066 (class 2606 OID 18801)
-- Name: FacilityImage facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5071 (class 2606 OID 18806)
-- Name: FacilityType facilityid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT facilityid_fkey FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5076 (class 2606 OID 18811)
-- Name: Insurance facilitytypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Insurance"
    ADD CONSTRAINT facilitytypeid_fkey FOREIGN KEY ("facilityTypeID") REFERENCES public."FacilityType"("facilityTypeID");


--
-- TOC entry 5075 (class 2606 OID 18816)
-- Name: InfoVerifiedHistory fk_facilityID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InfoVerifiedHistory"
    ADD CONSTRAINT "fk_facilityID" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5073 (class 2606 OID 18821)
-- Name: FacilityUser fk_facilityID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityUser"
    ADD CONSTRAINT "fk_facilityID" FOREIGN KEY ("facilityID") REFERENCES public."Facility"("facilityID");


--
-- TOC entry 5067 (class 2606 OID 18826)
-- Name: FacilityImage imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityImage"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5050 (class 2606 OID 18831)
-- Name: City imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."City"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5052 (class 2606 OID 18836)
-- Name: Country imageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Country"
    ADD CONSTRAINT imageid_fkey FOREIGN KEY ("imageID") REFERENCES public."Image"("imageID");


--
-- TOC entry 5035 (class 2606 OID 18841)
-- Name: Address postalcodeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Address"
    ADD CONSTRAINT postalcodeid_fkey FOREIGN KEY ("postalCodeID") REFERENCES public."PostalCode"("postalCodeID");


--
-- TOC entry 5065 (class 2606 OID 18846)
-- Name: FacilityEvent sessionFacilityID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityEvent"
    ADD CONSTRAINT "sessionFacilityID" FOREIGN KEY ("sessionFacilityID") REFERENCES public."SessionFacility"("sessionFacilityID");


--
-- TOC entry 5074 (class 2606 OID 18851)
-- Name: FocusSession sessionID_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FocusSession"
    ADD CONSTRAINT "sessionID_fk" FOREIGN KEY ("sessionID") REFERENCES public."Session"("sessionID");


--
-- TOC entry 5085 (class 2606 OID 18856)
-- Name: SessionFacility sessionID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SessionFacility"
    ADD CONSTRAINT "sessionID_fkey" FOREIGN KEY ("sessionID") REFERENCES public."Session"("sessionID");


--
-- TOC entry 5088 (class 2606 OID 18861)
-- Name: Unit sizeCategoryID_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Unit"
    ADD CONSTRAINT "sizeCategoryID_fkey" FOREIGN KEY ("sizeCategoryID") REFERENCES public."SizeCategory"("sizeCategoryID");


--
-- TOC entry 5062 (class 2606 OID 18866)
-- Name: FacilityDiscount sizecategoryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT sizecategoryid_fkey FOREIGN KEY ("sizeCategoryID") REFERENCES public."SizeCategory"("sizeCategoryID");


--
-- TOC entry 5063 (class 2606 OID 18871)
-- Name: FacilityDiscount storagetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityDiscount"
    ADD CONSTRAINT storagetypeid_fkey FOREIGN KEY ("storageTypeID") REFERENCES public."StorageType"("storageTypeID");


--
-- TOC entry 5072 (class 2606 OID 18876)
-- Name: FacilityType storagetypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."FacilityType"
    ADD CONSTRAINT storagetypeid_fkey FOREIGN KEY ("storageTypeID") REFERENCES public."StorageType"("storageTypeID");


--
-- TOC entry 5092 (class 2606 OID 18881)
-- Name: UnitDiscount unitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."UnitDiscount"
    ADD CONSTRAINT unitid_fkey FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5039 (class 2606 OID 18886)
-- Name: Booking unitid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Booking"
    ADD CONSTRAINT unitid_fkey FOREIGN KEY ("unitID") REFERENCES public."Unit"("unitID");


--
-- TOC entry 5345 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;


-- Completed on 2023-06-08 15:35:35

--
-- PostgreSQL database dump complete
--

