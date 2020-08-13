PGDMP     4    	                x           GT ATL    12.2    12.2 .    J           0    0    ENCODING    ENCODING         SET client_encoding = 'LATIN1';
                      false            K           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            L           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            M           1262    25107    GT ATL    DATABASE     �   CREATE DATABASE "GT ATL" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_United States.1252' LC_CTYPE = 'English_United States.1252';
    DROP DATABASE "GT ATL";
                postgres    false            N           0    0    DATABASE "GT ATL"    COMMENT     8   COMMENT ON DATABASE "GT ATL" IS 'here be sql practice';
                   postgres    false    2893                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                postgres    false            O           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   postgres    false    3            �           1247    25116    mpaa_rating    TYPE     a   CREATE TYPE public.mpaa_rating AS ENUM (
    'G',
    'PG',
    'PG-13',
    'R',
    'NC-17'
);
    DROP TYPE public.mpaa_rating;
       public          postgres    false    3            �           1247    25128    year    DOMAIN     k   CREATE DOMAIN public.year AS integer
	CONSTRAINT year_check CHECK (((VALUE >= 1901) AND (VALUE <= 2155)));
    DROP DOMAIN public.year;
       public          postgres    false    3            �            1255    25130    _group_concat(text, text)    FUNCTION     �   CREATE FUNCTION public._group_concat(text, text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT CASE
  WHEN $2 IS NULL THEN $1
  WHEN $1 IS NULL THEN $2
  ELSE $1 || ', ' || $2
END
$_$;
 0   DROP FUNCTION public._group_concat(text, text);
       public          postgres    false    3            �            1255    25131    film_in_stock(integer, integer)    FUNCTION     $  CREATE FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
     SELECT inventory_id
     FROM inventory
     WHERE film_id = $1
     AND store_id = $2
     AND inventory_in_stock(inventory_id);
$_$;
 e   DROP FUNCTION public.film_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer);
       public          postgres    false    3            �            1255    25132 #   film_not_in_stock(integer, integer)    FUNCTION     '  CREATE FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$
    SELECT inventory_id
    FROM inventory
    WHERE film_id = $1
    AND store_id = $2
    AND NOT inventory_in_stock(inventory_id);
$_$;
 i   DROP FUNCTION public.film_not_in_stock(p_film_id integer, p_store_id integer, OUT p_film_count integer);
       public          postgres    false    3            �            1255    25133 7   get_customer_balance(integer, timestamp with time zone)    FUNCTION       CREATE FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp with time zone) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
       --#OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       --#THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       --#   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       --#   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       --#   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       --#   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED
DECLARE
    v_rentfees DECIMAL(5,2); --#FEES PAID TO RENT THE VIDEOS INITIALLY
    v_overfees INTEGER;      --#LATE FEES FOR PRIOR RENTALS
    v_payments DECIMAL(5,2); --#SUM OF PAYMENTS MADE PREVIOUSLY
BEGIN
    SELECT COALESCE(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(IF((rental.return_date - rental.rental_date) > (film.rental_duration * '1 day'::interval),
        ((rental.return_date - rental.rental_date) - (film.rental_duration * '1 day'::interval)),0)),0) INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

    SELECT COALESCE(SUM(payment.amount),0) INTO v_payments
    FROM payment
    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

    RETURN v_rentfees + v_overfees - v_payments;
END
$$;
 m   DROP FUNCTION public.get_customer_balance(p_customer_id integer, p_effective_date timestamp with time zone);
       public          postgres    false    3            �            1255    25134 #   inventory_held_by_customer(integer)    FUNCTION     ;  CREATE FUNCTION public.inventory_held_by_customer(p_inventory_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN

  SELECT customer_id INTO v_customer_id
  FROM rental
  WHERE return_date IS NULL
  AND inventory_id = p_inventory_id;

  RETURN v_customer_id;
END $$;
 I   DROP FUNCTION public.inventory_held_by_customer(p_inventory_id integer);
       public          postgres    false    3            �            1255    25135    inventory_in_stock(integer)    FUNCTION     �  CREATE FUNCTION public.inventory_in_stock(p_inventory_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rentals INTEGER;
    v_out     INTEGER;
BEGIN
    -- AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    -- FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT count(*) INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
      RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO v_out
    FROM inventory LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
    AND rental.return_date IS NULL;

    IF v_out > 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END $$;
 A   DROP FUNCTION public.inventory_in_stock(p_inventory_id integer);
       public          postgres    false    3            �            1255    25136 "   last_day(timestamp with time zone)    FUNCTION     �  CREATE FUNCTION public.last_day(timestamp with time zone) RETURNS date
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$
  SELECT CASE
    WHEN EXTRACT(MONTH FROM $1) = 12 THEN
      (((EXTRACT(YEAR FROM $1) + 1) operator(pg_catalog.||) '-01-01')::date - INTERVAL '1 day')::date
    ELSE
      ((EXTRACT(YEAR FROM $1) operator(pg_catalog.||) '-' operator(pg_catalog.||) (EXTRACT(MONTH FROM $1) + 1) operator(pg_catalog.||) '-01')::date - INTERVAL '1 day')::date
    END
$_$;
 9   DROP FUNCTION public.last_day(timestamp with time zone);
       public          postgres    false    3            �            1255    25137    last_updated()    FUNCTION     �   CREATE FUNCTION public.last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END $$;
 %   DROP FUNCTION public.last_updated();
       public          postgres    false    3            �           1255    25155    group_concat(text) 	   AGGREGATE     c   CREATE AGGREGATE public.group_concat(text) (
    SFUNC = public._group_concat,
    STYPE = text
);
 *   DROP AGGREGATE public.group_concat(text);
       public          postgres    false    222    3            �            1259    25156    actor_actor_id_seq    SEQUENCE     {   CREATE SEQUENCE public.actor_actor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.actor_actor_id_seq;
       public          postgres    false    3            �            1259    25203    address_address_id_seq    SEQUENCE        CREATE SEQUENCE public.address_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.address_address_id_seq;
       public          postgres    false    3            �            1259    25166    category_category_id_seq    SEQUENCE     �   CREATE SEQUENCE public.category_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.category_category_id_seq;
       public          postgres    false    3            �            1259    25213    city_city_id_seq    SEQUENCE     y   CREATE SEQUENCE public.city_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.city_city_id_seq;
       public          postgres    false    3            �            1259    25223    country_country_id_seq    SEQUENCE        CREATE SEQUENCE public.country_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.country_country_id_seq;
       public          postgres    false    3            �            1259    25138    customer_customer_id_seq    SEQUENCE     �   CREATE SEQUENCE public.customer_customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.customer_customer_id_seq;
       public          postgres    false    3            �            1259    33299    departments    TABLE     u   CREATE TABLE public.departments (
    dept_no character varying(20) NOT NULL,
    dept_name character varying(20)
);
    DROP TABLE public.departments;
       public         heap    postgres    false    3            �            1259    33346    dept_emp    TABLE     W   CREATE TABLE public.dept_emp (
    emp_no integer,
    dept_no character varying(5)
);
    DROP TABLE public.dept_emp;
       public         heap    postgres    false    3            �            1259    33359    dept_man    TABLE     X   CREATE TABLE public.dept_man (
    dept_no character varying(10),
    emp_no integer
);
    DROP TABLE public.dept_man;
       public         heap    postgres    false    3            �            1259    33323 	   employees    TABLE     �   CREATE TABLE public.employees (
    emp_no integer NOT NULL,
    emp_title character varying(15) NOT NULL,
    birth_date date,
    first_name character varying(20),
    last_name character varying(20),
    sex character varying(5),
    hire_date date
);
    DROP TABLE public.employees;
       public         heap    postgres    false    3            �            1259    25176    film_film_id_seq    SEQUENCE     y   CREATE SEQUENCE public.film_film_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.film_film_id_seq;
       public          postgres    false    3            �            1259    25243    inventory_inventory_id_seq    SEQUENCE     �   CREATE SEQUENCE public.inventory_inventory_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.inventory_inventory_id_seq;
       public          postgres    false    3            �            1259    25250    language_language_id_seq    SEQUENCE     �   CREATE SEQUENCE public.language_language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.language_language_id_seq;
       public          postgres    false    3            �            1259    25262    payment_payment_id_seq    SEQUENCE        CREATE SEQUENCE public.payment_payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.payment_payment_id_seq;
       public          postgres    false    3            �            1259    25268    rental_rental_id_seq    SEQUENCE     }   CREATE SEQUENCE public.rental_rental_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.rental_rental_id_seq;
       public          postgres    false    3            �            1259    33372    salaries    TABLE     I   CREATE TABLE public.salaries (
    emp_no integer,
    salary integer
);
    DROP TABLE public.salaries;
       public         heap    postgres    false    3            �            1259    25280    staff_staff_id_seq    SEQUENCE     {   CREATE SEQUENCE public.staff_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.staff_staff_id_seq;
       public          postgres    false    3            �            1259    25291    store_store_id_seq    SEQUENCE     {   CREATE SEQUENCE public.store_store_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.store_store_id_seq;
       public          postgres    false    3            �            1259    33309    titles    TABLE     i   CREATE TABLE public.titles (
    title_id character varying NOT NULL,
    title character varying(25)
);
    DROP TABLE public.titles;
       public         heap    postgres    false    3            �
           2606    33303    departments departments_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (dept_no);
 F   ALTER TABLE ONLY public.departments DROP CONSTRAINT departments_pkey;
       public            postgres    false    216            �
           2606    33329    employees employees_emp_no_key 
   CONSTRAINT     [   ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_emp_no_key UNIQUE (emp_no);
 H   ALTER TABLE ONLY public.employees DROP CONSTRAINT employees_emp_no_key;
       public            postgres    false    218            �
           2606    33327    employees employees_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (emp_no, emp_title);
 B   ALTER TABLE ONLY public.employees DROP CONSTRAINT employees_pkey;
       public            postgres    false    218    218            �
           2606    33316    titles titles_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.titles
    ADD CONSTRAINT titles_pkey PRIMARY KEY (title_id);
 <   ALTER TABLE ONLY public.titles DROP CONSTRAINT titles_pkey;
       public            postgres    false    217            �
           2606    33354    dept_emp dept_emp_dept_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dept_emp
    ADD CONSTRAINT dept_emp_dept_no_fkey FOREIGN KEY (dept_no) REFERENCES public.departments(dept_no);
 H   ALTER TABLE ONLY public.dept_emp DROP CONSTRAINT dept_emp_dept_no_fkey;
       public          postgres    false    219    2750    216            �
           2606    33349    dept_emp dept_emp_emp_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dept_emp
    ADD CONSTRAINT dept_emp_emp_no_fkey FOREIGN KEY (emp_no) REFERENCES public.employees(emp_no);
 G   ALTER TABLE ONLY public.dept_emp DROP CONSTRAINT dept_emp_emp_no_fkey;
       public          postgres    false    219    218    2754            �
           2606    33362    dept_man dept_man_dept_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dept_man
    ADD CONSTRAINT dept_man_dept_no_fkey FOREIGN KEY (dept_no) REFERENCES public.departments(dept_no);
 H   ALTER TABLE ONLY public.dept_man DROP CONSTRAINT dept_man_dept_no_fkey;
       public          postgres    false    216    220    2750            �
           2606    33367    dept_man dept_man_emp_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dept_man
    ADD CONSTRAINT dept_man_emp_no_fkey FOREIGN KEY (emp_no) REFERENCES public.employees(emp_no);
 G   ALTER TABLE ONLY public.dept_man DROP CONSTRAINT dept_man_emp_no_fkey;
       public          postgres    false    2754    220    218            �
           2606    33375    salaries salaries_emp_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.salaries
    ADD CONSTRAINT salaries_emp_no_fkey FOREIGN KEY (emp_no) REFERENCES public.employees(emp_no);
 G   ALTER TABLE ONLY public.salaries DROP CONSTRAINT salaries_emp_no_fkey;
       public          postgres    false    218    2754    221           