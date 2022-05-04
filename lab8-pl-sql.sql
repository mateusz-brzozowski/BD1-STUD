--1. Uzupełnij ciało pakietu z poprzedniego slajdu za pomocą definicji funkcji calculate_seniority_bonus oraz procedury add_candidate, które pojawiły się na
-- poprzednich zajęciach. Następnie wywołaj te podprogramy z wykorzystaniem nazwy pakietu.
--2. Dodaj do pakietu prywatną funkcję create_base_login, która będzie generowała bazowy login pracownika (ćwiczenie z pracy domowej BD1_8). Sprawdź możliwość wywołania tej funkcji.
CREATE OR REPLACE PACKAGE emp_management
AS
    FUNCTION calculate_seniority_bonus (p_id NUMBER) RETURN NUMBER;
    PROCEDURE add_candidate (p_name VARCHAR2, p_surname VARCHAR2, p_birth_date DATE, p_gender
    VARCHAR2, p_pos_name VARCHAR2, p_dep_name VARCHAR2);
END;
/
CREATE OR REPLACE PACKAGE BODY emp_management
AS
    FUNCTION create_login(emp_id NUMBER) RETURN VARCHAR2
    AS
        v_login VARCHAR2 (10);
    BEGIN
        SELECT SUBSTR(name, 1, 1) || SUBSTR(surname, 1, 7)
        INTO v_login
        FROM employees
         WHERE employee_id = emp_id;
        RETURN v_login;
    END create_login;
    FUNCTION calculate_seniority_bonus(p_id NUMBER) RETURN NUMBER
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
    END calculate_seniority_bonus;
    PROCEDURE add_candidate (p_name VARCHAR2, p_surname VARCHAR2, p_birth_date DATE, p_gender VARCHAR2, p_pos_name VARCHAR2, p_dep_name VARCHAR2)
    AS
        v_pos_id NUMBER; v_dep_id NUMBER; v_cand_num NUMBER;
        c_candidate_status CONSTANT NUMBER := 304; c_num_max CONSTANT NUMBER := 2;
    BEGIN
        SELECT position_id INTO v_pos_id FROM positions WHERE name=p_pos_name;
        SELECT department_id INTO v_dep_id FROM departments WHERE name = p_dep_name;
        SELECT COUNT(employee_id) INTO v_cand_num FROM employees WHERE department_id = v_dep_id and status_id = c_candidate_status;
        IF v_cand_num < c_num_max THEN
            INSERT INTO employees VALUES(NULL, p_name, p_surname, p_birth_date, p_gender, c_candidate_status, null, null, v_dep_id, v_pos_id,null);
            commit;
            dbms_output.put_line ('Dodano kandydata ' || p_name || ' ' || p_surname);
        ELSE
            dbms_output.put_line ('Za duzo kandydatów w departamencie: ' || p_dep_name);
        END IF;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line ('Niepoprawna nazwa stanowiska i/lub zakładu');
        RAISE;
        WHEN TOO_MANY_ROWS THEN
            dbms_output.put_line ('Nieunikalna nazwa stanowiska i/lub zakładu');
        RAISE;
    END add_candidate;
END emp_management;
/
SELECT emp_management.calculate_seniority_bonus(101) FROM DUAL;
/
SELECT emp_management.create_login(101) FROM DUAL;
/
-- Wyzwalacze
CREATE OR REPLACE TRIGGER tg_salary_emp
BEFORE INSERT or UPDATE ON employees FOR EACH ROW
DECLARE
    v_min_sal positions.min_salary%TYPE;
    v_max_sal positions.max_salary%TYPE;
BEGIN
    SELECT min_salary, max_salary INTO v_min_sal, v_max_sal
    FROM positions WHERE position_id = :new.position_id;
    IF :new.salary NOT BETWEEN v_min_sal AND v_max_sal THEN
        :new.salary := v_max_sal;
        dbms_output.put_line('Zarobki pracownika spoza zakresu płac: ' || v_min_sal || ' ' || v_max_sal);
--        raise_application_error(-20001, 'Przekroczony zakres płacy');
    END IF;
END;
/
UPDATE employees
SET salary = 10000
WHERE employee_id = 101;
/
SELECT salary
FROM employees
WHERE employee_id = 101;
/
UPDATE employees
SET salary = 10000
WHERE employee_id IN (101, 102, 103);
/
SELECT salary
FROM employees
WHERE employee_id IN (101, 102, 103);
/
CREATE OR REPLACE TRIGGER tg_emp_ph
AFTER UPDATE OF position_id ON employees FOR EACH ROW
WHEN (new.position_id != old.position_id)
DECLARE
    v_date_start DATE ;
BEGIN
    SELECT MAX(date_end) INTO v_date_start FROM positions_history where employee_id=:old.employee_id;
    IF v_date_start IS NULL THEN
        v_date_start := :old.date_employed;
    END IF;
    INSERT INTO positions_history (employee_id, position_id, date_start, date_end)
        VALUES (:old.employee_id, :old.position_id, v_date_start, SYSDATE);
END;
/
-- # Wyzwalacze - ćwiczenia #
--1. Stwórz wyzwalacz, który podczas uaktualniania zarobków pracownika wyświetli podatek 20% procent od nowych zarobków. Przetestuj działanie.
CREATE OR REPLACE TRIGGER tg_tax_info
AFTER UPDATE OF salary ON employees FOR EACH ROW
DECLARE
    v_tax NUMBER;
BEGIN
    v_tax := :new.salary * 12 * 0.2;
    dbms_output.put_line(v_tax);
END;
/
UPDATE employees
SET salary = 3500
WHERE employee_id IN (101, 102, 103);
/
--2. Stwórz wyzwalacz, który po dodaniu nowego pracownika, usunięciu pracownika lub modyfikacji zarobków pracowników wyświetli aktualne średnie zarobki wszystkich pracowników. Przetestuj działanie.
CREATE OR REPLACE TRIGGER tg_display_info
AFTER UPDATE OF salary OR INSERT OR DELETE ON employees
DECLARE
    v_avg_sal NUMBER;
BEGIN
    SELECT avg(salary) INTO v_avg_sal FROM employees;
    dbms_output.put_line(v_avg_sal);
END;
/
UPDATE employees
SET salary = 3500
WHERE employee_id IN (101, 102, 103);
/
--3. Stwórz wyzwalacz, który dla każdego nowego pracownika nieposiadającego managera, ale zatrudnionego w departamencie, przypisze temu pracownikowi managera
--będącego jednocześnie managerem departamentu, w którym ten pracownik pracuje. Wykorzystaj klauzulę WHEN wyzwalacza. Przetestuj działanie.
CREATE OR REPLACE TRIGGER tg_new_manager
BEFORE INSERT ON employees FOR EACH ROW
WHEN(new.manager_id IS NULL AND new.department_id IS NOT NULL)
DECLARE
    v_manager NUMBER;
BEGIN
    SELECT manager_id INTO v_manager FROM departments WHERE department_id = :new.department_id;
    :new.manager_id := v_manager;
END;
/
INSERT INTO employees VALUES (301, 'Piotr', 'Kowalski', SYSDATE, NULL, NULL, NULL, NULL, 101, NULL, NULL, NULL);
/
--4. Rozwiąż ponownie ćwiczenie nr 4, ale tym razem nie wykorzystuj klauzuli WHEN wyzwalacza. Przetestuj działanie.
CREATE OR REPLACE TRIGGER tg_new_manager_when
BEFORE INSERT ON employees FOR EACH ROW
DECLARE
    v_manager NUMBER;
BEGIN
    IF(:new.manager_id IS NULL AND :new.department_id IS NOT NULL) THEN
        SELECT manager_id INTO v_manager FROM departments WHERE department_id = :new.department_id;
        :new.manager_id := v_manager;
    END IF;
END;
/
INSERT INTO employees VALUES (303, 'Piotr', 'Kowalski', SYSDATE, NULL, NULL, NULL, NULL, 103, NULL, NULL, NULL);
/
--5. Stwórz wyzwalacz który będzie weryfikował, że w firmie pracuje tylko jeden Prezes.
CREATE OR REPLACE TRIGGER tg_one_prezes
BEFORE INSERT OR UPDATE of position_id ON employees
DECLARE
    v_position_id INTEGER;
    v_count INTEGER;
BEGIN
    SELECT position_id INTO v_position_id FROM positions WHERE name LIKE 'Prezes';
    SELECT count(employee_id) INTO v_count FROM employees WHERE position_id = v_position_id;
    IF v_count > 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wieciej niz jeden prezes');
    END IF;
END;
/
--1. Przygotuj procedurę PL/SQL, która z wykorzystaniem jawnego kursora udostępni średnie zarobki dla każdego z departamentów.
-- Następnie wykorzystując ten kursor wyświetl imiona, nazwiska i zarobki pracowników, którzy zarabiają więcej niż średnie zarobki w ich departamentach.
CREATE OR REPLACE PROCEDURE avg_salary
AS
    CURSOR cr IS SELECT avg(salary), department_id FROM employees GROUP BY department_id;
    CURSOR cr_emp IS SELECT * FROM employees;

    v_salary NUMBER(20, 2);
    v_did INTEGER;
    v_rec_employees employees%ROWTYPE;
BEGIN
    OPEN cr_emp;
    LOOP
        OPEN cr;
        FETCH cr_emp INTO v_rec_employees;
            LOOP
                FETCH cr INTO v_salary, v_did;
                    IF v_rec_employees.salary > v_salary AND v_rec_employees.department_id = v_did THEN
                        dbms_output.put_line(v_rec_employees.name ||  ' ' || v_rec_employees.surname || ' '  || v_rec_employees.salary || ' ' || v_salary);
                    END IF;
                EXIT WHEN cr%NOTFOUND;
            END LOOP;
        CLOSE cr;
        EXIT WHEN cr_emp%NOTFOUND;
    END LOOP;
    CLOSE cr_emp;
END;
/
EXEC avg_salary;
/
--2. Przygotuj procedurę PL/SQL, która z wykorzystaniem jawnego kursora wyświetli p_no_dept departamenty największych budżetach, gdzie p_no_dept
--to parametr wejściowy procedury. Następnie wyświetl dane kierowników tych departamentów.
CREATE OR REPLACE PROCEDURE depr_max_budget (p_no_dept IN INTEGER)
AS
    CURSOR cr IS SELECT * FROM departments ORDER BY year_budget DESC FETCH FIRST p_no_dept ROWS WITH TIES;
    v_depts departments%ROWTYPE;
BEGIN
    OPEN cr;
    LOOP
        FETCH cr INTO v_depts;
        dbms_output.put_line(v_depts.name || ' ' || v_depts.year_budget);
        EXIT WHEN cr%NOTFOUND;
    END LOOP;
END;
/
EXEC depr_max_budget(4);
/
--3. Wykorzystując niejawny kursor oraz deklaracje zmiennych/stałych podnieś o 2% pensje wszystkim pracownikom zatrudnionym w przeszłości (tzn. przed aktualnym stanowiskiem pracy) na co najmniej jednym stanowisku pracy.
CREATE OR REPLACE PROCEDURE raisesal
AS
    v_count INTEGER;
BEGIN
    FOR r_emp IN (SELECT * FROM employees)
    LOOP
        SELECT count(position_id) INTO v_count FROM positions_history WHERE employee_id = r_emp.employee_id;
        IF v_count >= 1 THEN UPDATE employees SET salary = salary*1.02 WHERE employee_id = r_emp.employee_id; END IF;
    END LOOP;
END;
/
EXEC raisesal;
--6. Stwórz tabelę projects_history a następnie zrealizuj wyzwalacz, który będzie logował każdą zmianę (tylko update) w tabeli projects. Zapisz starą i nową wartość każdej kolumny.
