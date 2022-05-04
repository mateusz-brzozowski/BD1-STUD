-- podzapytanie zwraca jeden wiersz danych

--1. Napisz zapytanie, które wyświetli imię, nazwisko oraz nazwy zakładów, w których pracownicy mają większe zarobki niż minimalne zarobki na stanowisku o nazwie ‘Konsultant’.
SELECT e.employee_id, e.name, e.salary, d.name as dep_name
FROM employees e JOIN departments d ON (e.department_id = d.department_id)
WHERE e.salary > (SELECT MIN(e.salary)
FROM employees e join positions p USING (position_id)
where p.name LIKE 'Konsultant');
--2. Napisz zapytanie, które zwróci dane najmłodszego wśród dzieci pracowników. (Skorzystaj z podzapytań. Jaki jest inny sposób na osiągnięcie tego wyniku?)
SELECT *
FROM dependents d
WHERE d.birth_date = (SELECT MIN(birth_date) FROM dependents);

--3. Napisz zapytanie, które zwróci dane dzieci najstarszego pracownika z zakładu 102.
SELECT d.name, d.surname, d.birth_date, d.gender
FROM employees e JOIN dependents d USING(employee_id)
WHERE department_id = 102 AND e.birth_date = (SELECT MIN(birth_date)
FROM employees
WHERE department_id = 102);

SELECT MIN(birth_date)
FROM employees
WHERE department_id = 102;

--4. Napisz zapytanie, które wyświetli wszystkich pracowników,
--którzy zostali zatrudnieni nie wcześniej niż najwcześniej zatrudniony pracownik w zakładzie o id 101
--i nie później niż najpóźniej zatrudniony pracownik w zakładzie o id 107.
SELECT *
FROM employees
WHERE date_employed BETWEEN (SELECT MIN(date_employed) FROM employees WHERE department_id = 101) AND (SELECT MAX(date_employed) FROM employees WHERE department_id = 107);

--5. Wyświetl średnie zarobki dla każdego ze stanowisk, o ile średnie te są większe od średnich zarobków w departamencie “Administracja”.
SELECT position_id, p.name, ROUND(AVG(salary))
FROM employees JOIN positions p USING (position_id)
WHERE position_id IS NOT NULL
GROUP BY position_id, p.name;

-- podzapytanie zwraca wiele wierszy danych

--1. Napisz zapytanie, które zwróci informacje o pracownikach zatrudnionych po zakończeniu wszystkich projektów (tabela projects). Zapytanie zrealizuj na 2 sposoby i porównaj wyniki
SELECT *
FROM projects;

SELECT *
FROM employees
WHERE date_employed < (SELECT MAX(date_end) FROM projects);

SELECT *
FROM employees
WHERE date_employed > ALL (SELECT DISTINCT date_end FROM projects WHERE date_end IS NOT NULL);

--2. Napisz zapytanie, które wyświetli wszystkich pracowników, których zarobki są co najmniej czterokrotnie większe od zarobków jakiegokolwiek innego pracownika.
SELECT *
FROM employees
WHERE salary >= ANY (SELECT 4 * salary FROM employees);

SELECT salary
FROM employees;
--3. Korzystając z podzapytań napisz zapytanie które zwróci pracowników departamentów mających siedziby w Polsce.
SELECT *
FROM employees
WHERE department_id IN (SELECT department_id
FROM departments JOIN addresses USING (address_id) JOIN countries c USING(country_id)
WHERE c.name LIKE 'Polska');

--4. Zmodyfikuj poprzednie zapytania tak, żeby dodatkowo pokazać maksymalną pensję per departament.
SELECT department_id, MAX(salary)
FROM employees
WHERE department_id IN (SELECT department_id
FROM departments JOIN addresses USING (address_id) JOIN countries c USING(country_id)
WHERE c.name LIKE 'Polska')
GROUP BY department_id;

--podzapytania skorelowane

--1. Napisz zapytanie, które zwróci pracowników zarabiających więcej niż średnia w ich departamencie.
SELECT salary, (SELECT AVG(salary) FROM employees inner WHERE outer.department_id = inner.department_id)
FROM employees outer
WHERE salary > (SELECT AVG(salary) FROM employees inner WHERE outer.department_id = inner.department_id);

SELECT AVG(salary) FORM employees;
--2. Napisz zapytanie które zwróci regiony nieprzypisane do krajów.
SELECT r.region_id, r.name, (SELECT rc.region_id FROM reg_countries rc WHERE r.region_id = rc.region_id)
FROM regions r
WHERE NOT EXISTS (SELECT rc.region_id FROM reg_countries rc WHERE r.region_id = rc.region_id);
--3. Napisz zapytanie które zwróci kraje nieprzypisane do regionów.
SELECT c.country_id, c.name, (SELECT rc.country_id FROM reg_countries rc WHERE c.country_id = rc.country_id)
FROM countries c
WHERE NOT EXISTS (SELECT rc.country_id FROM reg_countries rc WHERE c.country_id = rc.country_id);
--4. Napisz zapytanie, które zwróci wszystkich pracowników niebędących managerami.
SELECT *
FROM employees e1
WHERE NOT EXISTS (SELECT e2.employee_id FROM employees e2 WHERE e1.employee_id = e2.manager_id);
--5. Napisz zapytanie, które zwróci dane pracowników, którzy zarabiają więcej niż średnie zarobki na stanowisku, na którym pracują .
SELECT e1.name
FROM employees e1
WHERE salary > AVG(SELECT e2.salary FROM employees e2 WHERE e1.position_id = e2.position_id);
--6. Za pomocą podzapytania skorelowanego sprawdź, czy wszystkie stanowiska zdefiniowane w tabeli Positions są aktualnie zajęte przez pracowników.
SELECT COUNT(*)
FROM positions p1
WHERE NOT EXISTS (SELECT * FROM employees WHERE position_id = p1.position_id);

-- podzapytania w SELECT/FROM

--1. Napisz zapytanie, które dla wszystkich pracowników posiadających pensję zwróci informację o różnicy między ich pensją, a średnią pensją pracowników.
--Różnicę podaj jako zaokrągloną wartość bezwzględną.
SELECT name, surname, salary, ROUND(ABS(salary - (SELECT AVG(salary) FROM employees))) as diff
FROM employees
WHERE salary IS NOT NULL;

SELECT e.name, e.surname, e.salary, ABS(avg_salary.sal - e.salary)
FROM employees e, (SELECT ROUND(AVG(salary)) sal FROM employees) avg_salary
WHERE e.salary IS NOT NULL;
--2. Korzystając z poprzedniego rozwiązania, napisz zapytanie, które zwróci tylko tych pracowników, którzy są kobietami i dla których różnica do wartości średniej jest powyżej 1000.
SELECT e.name, e.surname, e.salary, ABS(avg_salary.sal - e.salary)
FROM employees e, (SELECT ROUND(AVG(salary)) sal FROM employees) avg_salary
WHERE e.salary IS NOT NULL AND e.gender LIKE 'K' AND ABS(avg_salary.sal - e.salary) > 1000;
--3. Zmodyfikuj poprzednie zapytanie tak aby obliczyć liczbe pracowników. (skorzystaj z podzapytania)
SELECT COUNT(*) FROM (
SELECT e.name, e.surname, e.salary, ABS(avg_salary.sal - e.salary)
FROM employees e, (SELECT ROUND(AVG(salary)) sal FROM employees) avg_salary
WHERE e.salary IS NOT NULL AND e.gender LIKE 'K' AND ABS(avg_salary.sal - e.salary) > 1000);
--4. Napisz zapytanie które zwróci informacje o pracownikach zatrudnionych po zakończeniu wszystkich projektów (tabela projects). W wynikach zapytania umieść jako kolumnę datę graniczną.
SELECT *
FROM employees
WHERE date_employed > (SELECT MAX(date_end) FROM projects);
--5. Napisz zapytanie które zwróci pracowników którzy uzyskali w 2019 oceny wyższe niż średnia w swoim departamencie. Pokaż średnią departamentu jako kolumnę.
SELECT e1.name, e1.surname, g.grade, (SELECT AVG(grade) FROM employees e2 LEFT JOIN emp_grades eg USING(employee_id) JOIN grades g USING (grade_id) WHERE e1.department_id = e2.department_id GROUP BY e2.department_id) AS avg_grade
FROM employees e1 LEFT JOIN emp_grades eg USING(employee_id) JOIN grades g USING (grade_id)
WHERE EXTRACT(year FROM eg.inspection_date) = 2019 AND g.grade > (SELECT AVG(grade) FROM employees e2 LEFT JOIN emp_grades eg USING(employee_id) JOIN grades g USING (grade_id) WHERE e1.department_id = e2.department_id GROUP BY e2.department_id);
-- Praca domowa

--1. Skonstruuj po jednym zapytaniu, które będzie zawierać w klauzuli WHERE:
--a. podzapytanie zwracające tylko jedną wartość;
SELECT *
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);
--b. podzapytanie zwracające jeden wiersz danych, ale wiele kolumn;
SELECT *
FROM employees
WHERE (name, gender) = (SELECT name, gender FROM employees ORDER BY salary FETCH NEXT 1 ROWS ONLY);
--c. podzapytanie zwracające jedną kolumnę danych;
SELECT *
FROM employees
WHERE salary > ANY (SELECT salary FROM employees);
--d. podzapytanie zwracające tabelę danych.
SELECT *
FROM employees
WHERE (name, gender) IN (SELECT name, gender FROM employees ORDER BY salary FETCH NEXT 5 ROWS ONLY);
--2. Napisz zapytanie, które zwróci pracowników będących kierownikami zakładów, o ile ich zarobki są większe niż średnia zarobków dla wszystkich pracowników.
SELECT *
FROM departments d LEFT JOIN employees e1 ON (d.manager_id = e1.employee_id)
WHERE salary > (SELECT AVG(salary) FROM employees);
--3. Zmodyfikuj powyższe zapytanie tak, aby wyświetlało wszystkich pracowników będących kierownikami zakładów, o ile ich zarobki są większe niż średnia zarobków na stanowisku które zajmują.
SELECT *
FROM departments d LEFT JOIN employees e1 ON (d.manager_id = e1.employee_id)
WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e1.position_id = e2.position_id);
--4. Wyszukaj informacje w Internecie, dokumentacji bazy danych Oracle lub w dostarczonych materiałach Oracle Academy o sposobie wykonywania podzapytań skorelowanych.
--5. W których klauzulach polecenia SELECT możemy wykorzystać podzapytania nieskorelowane?
-- WHERE, FROM, HAVING, SELECT
--6. W których klauzulach polecenia SELECT możemy wykorzystać podzapytania skorelowane?
-- WHERE, HAVING, SELECT
