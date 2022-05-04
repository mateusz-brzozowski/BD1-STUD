--1. Napisz prosty blok anonimowy zawierający blok wykonawczy z instrukcją NULL. Uruchom ten program.
BEGIN
NULL;
END;
/
--2. Zmodyfikuj program powyżej i wykorzystaj procedurę dbms_output.put_line przyjmującą jako parametr łańcuch znakowy do wyświetlenia na konsoli. Uruchom program i odnajdź napis.
BEGIN
dbms_output.put_line('balbinka');
END;
/
--3. Napisz blok anonimowy który doda do tabeli region nowy rekord (np. ‘Oceania’). Uruchom program i zweryfikuj działanie.
BEGIN
INSERT INTO regions VALUES (DEFAULT, 'Oceania', 'oc');
END;
/
--4. Napisz blok anonimowy, który wygeneruje błąd (RAISE_APPLICATION_ERROR przyjmującą 2 parametry: kod błędu oraz wiadomość)
BEGIN
RAISE_APPLICATION_ERROR(-20666, 'Nie dziala');
END;
/
--1. Napisz blok anonimowy który będzie korzystał z dwóch zmiennych (v_min_sal oraz v_emp_id)
--i który będzie wypisywał na ekran imię i nazwisko pracownika o wskazanym id tylko jeśli jego zarobki są wyższe niż v_min_sal.
DECLARE
    v_min_sal NUMBER := 1000;
    v_emp_id NUMBER := 102;
    v_name VARCHAR2(20);
    v_surname VARCHAR2(20);
BEGIN
    SELECT name, surname
    INTO v_name, v_surname
    FROM employees
    WHERE employee_id = v_emp_id AND salary > v_min_sal;

    dbms_output.put_line(v_name || ' ' || v_surname);
END;
/
--1. Napisz funkcję, która wyliczy roczną wartość podatku pracownika. Zakładamy podatek progresywny. Początkowo stawka to 15%, po przekroczeniu progu 100000 stawka wynosi 25%.
CREATE OR replace FUNCTION calculate_tax(p_id NUMBER)
RETURN NUMBER
AS
    v_year_salary NUMBER;
    v_tax NUMBER;
BEGIN
    SELECT 12 * salary INTO v_year_salary FROM employees WHERE employee_id = p_id;
    IF v_year_salary > 10000 THEN
        v_tax := (v_year_salary - 10000) * 0.25 + 10000 * 0.15;
    ELSE
        v_tax := v_year_salary * 0.15;
    END IF;
    RETURN v_tax;
END;
/
SELECT calculate_tax(101) FROM DUAL;
/
--2. Stwórz widok łączący departamenty, adresy i kraje. Napisz zapytanie, które pokaże sumę zapłaconych podatków w krajach.
SELECT country_id, sum(calculate_tax(employee_id))
FROM employees JOIN departments USING(department_id) JOIN addresses USING(address_id) JOIN countries USING (country_id)
GROUP BY country_id;
/
--3. Napisz funkcję, która wyliczy dodatek funkcyjny dla kierowników zespołów. Dodatek funkcyjny powinien wynosić 10% pensji za każdego podległego pracownika, ale nie może przekraczać 50% miesięcznej pensji.
CREATE OR replace FUNCTION calculate_funcionaly_bonus(p_id NUMBER)
RETURN NUMBER
AS
    v_num_of_emp NUMBER;
    v_salary NUMBER;
    v_bonus NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_num_of_emp FROM employees WHERE manager_id = p_id;
    SELECT salary INTO v_salary FROM employees WHERE employee_id = p_id;
    v_bonus := v_salary * 0.1 * v_num_of_emp;
    IF v_bonus > v_salary * 0.5 THEN
        v_bonus := v_salary * 0.5;
    END IF;
    RETURN v_bonus;
END;
/
SELECT calculate_funcionaly_bonus(101) FROM DUAL;
/
--4. Zmodyfikuj funkcję calculate_total_bonus, żeby wyliczała całość dodatku dla pracownika (stażowy i funkcyjny).
CREATE OR replace FUNCTION calculate_seniority_bonus(p_id NUMBER)
RETURN NUMBER
AS
    v_age NUMBER;
    v_yrs_employed NUMBER;
    v_birth_date DATE;
    v_date_employed DATE;
    v_salary NUMBER;
    v_bonus NUMBER := 0;
    c_sal_multiplier CONSTANT NUMBER := 2;
    c_age_min CONSTANT NUMBER := 30;
    c_emp_min CONSTANT NUMBER := 3;
BEGIN
    SELECT birth_date,date_employed, salary
    INTO v_birth_date, v_date_employed, v_salary
    FROM employees
    WHERE employee_id = p_id;
    v_age := extract (year FROM SYSDATE) - extract (year FROM v_birth_date);
    v_yrs_employed := extract (year FROM SYSDATE) - extract (year FROM v_date_employed);
    IF v_age > c_age_min AND v_yrs_employed > c_emp_min THEN
        v_bonus := c_sal_multiplier * v_salary;
    END IF;
    RETURN v_bonus;
END;
/
CREATE OR replace FUNCTION calculate_total_bonus(p_id NUMBER)
RETURN NUMBER
AS
    v_fun_bonus NUMBER;
    v_sen_bonus NUMBER;
    v_tot_bonus NUMBER;
BEGIN
    v_fun_bonus := calculate_funcionaly_bonus(p_id);
    v_sen_bonus := calculate_seniority_bonus(p_id);
    v_tot_bonus := v_fun_bonus + v_sen_bonus;
    RETURN v_tot_bonus;
END;
/
SELECT calculate_total_bonus(101) FROM DUAL;
/
--1. Napisz procedurę, która wykona zmianę stanowiska pracownika. Procedura powinna przyjmować identyfikator pracownika oraz identyfikator jego nowego stanowiska.
CREATE OR replace PROCEDURE change_position(p_id NUMBER, new_pos_id NUMBER)
AS
BEGIN
    UPDATE employees SET position_id = new_pos_id WHERE employee_id = p_id;
END;
/
--2. Sprawdź działanie procedury wywołując ją z bloku anonimowego
BEGIN
    change_position(105, 109);
END;
/
--3. Napisz procedurę, która zdegraduje zespołowego kierownika o danym identyfikatorze. Na nowego kierownika zespołu powołaj najstarszego z jego dotychczasowych podwładnych.
CREATE OR replace PROCEDURE new_manager(p_id NUMBER)
AS
    v_oldest_emp_id NUMBER;
BEGIN
    SELECT employee_id INTO v_oldest_emp_id FROM employees WHERE manager_id = 101 ORDER BY birth_date ASC FETCH NEXT 1 ROWS ONLY;
    UPDATE employees SET manager_id = v_oldest_emp_id WHERE manager_id = p_id;
    UPDATE employees SET manager_id = v_oldest_emp_id WHERE employee_id = p_id;
    UPDATE employees SET manager_id = NULL WHERE employee_id = v_oldest_emp_id;
END;
/
--4. Sprawdź działanie procedury.
BEGIN
    new_manager(101);
END;
/
/* ===========================
          PRACA DOMOWA
   =========================== */

--1. Napisz funkcję, która będzie tworzyła bazowy login dla każdego pracownika. Login ma się składać z pierwszej litery imienia i maksymalnie 7 znaków z nazwiska.

CREATE OR replace FUNCTION generate_login(p_id NUMBER)
RETURN VARCHAR2
AS
    v_name employees.name%TYPE;
    v_surname employees.surname%TYPE;
    v_login VARCHAR2(8);
BEGIN
    SELECT name, surname
    INTO v_name, v_surname
    FROM employees
    WHERE employee_id = p_id;

    v_login := SUBSTR(v_name,1,1) || SUBSTR(v_surname,1,7);
    dbms_output.put_line(v_login);
    RETURN v_login;
END;
/
SELECT generate_login(107) FROM dual;
/
--2. Napisz procedurę, która będzie zapisywać login pracownika do nowej kolumny w tabeli employees (dodaj ją). Zadbaj o to, żeby zapisywany login był unikalny (np. poprzez dodanie numerów do bazowego loginu).
ALTER TABLE employees ADD login VARCHAR2(20) UNIQUE;
/
CREATE OR replace PROCEDURE add_login(p_id NUMBER)
AS
    v_login VARCHAR2(20);
BEGIN
    v_login := generate_login(p_id) || p_id;
    UPDATE employees SET login = v_login WHERE employee_id = p_id;
END;
/
INSERT INTO employees VALUES (160, 'Pawel', 'Janowski', '20/08/1982', 'M', 301, 3000, '01/01/2009', 101, NULL, 101);
/
BEGIN
    add_login(160);
END;
/
--3. Sprawdź działanie trybów przekazania parametrów do procedury (IN, IN OUT i OUT).
CREATE OR replace PROCEDURE test_in(p_id IN NUMBER)
AS
BEGIN
    dbms_output.put_line(p_id);
END;
/
BEGIN
    test_in(160);
END;
/
CREATE OR replace PROCEDURE test_in_out(p_id IN OUT NUMBER)
AS
BEGIN
    dbms_output.put_line(p_id);
    p_id := p_id + 1;
END;
/
DECLARE
    v_id NUMBER := 106;
BEGIN
    test_in_out(v_id);
    dbms_output.put_line(v_id);
END;
/
CREATE OR replace PROCEDURE test_out(p_id OUT NUMBER)
AS
BEGIN
    p_id := 111;
    dbms_output.put_line(p_id);
    p_id := p_id + 1;
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    dbms_output.put_line(v_id);
    test_out(v_id);
    dbms_output.put_line(v_id);
END;
/