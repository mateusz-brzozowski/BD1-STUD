-- grupowanie

SELECT COUNT(*), status_id
FROM employees
GROUP BY status_id;

SELECT COUNT(*), status_id
FROM employees
WHERE gender LIKE 'K'
GROUP BY status_id;

SELECT MIN(salary), MAX(salary), AVG(salary), MEDIAN(salary), STDDEV(salary), status_id
FROM employees
GROUP BY status_id;

SELECT COUNT(*), language
FROM countries
GROUP BY language;

SELECT AVG(salary) avg_salary, AVG(FLOOR(MONTHS_BETWEEN(SYSDATE, birth_date)/12)), AVG(FLOOR(MONTHS_BETWEEN(SYSDATE, date_employed)/12)), gender
FROM employees
GROUP BY gender
ORDER BY avg_salary DESC;

SELECT COUNT(*), EXTRACT(year from established)
FROM departments
GROUP BY EXTRACT(year from established);

SELECT COUNT(*), EXTRACT(month from established)
FROM departments
GROUP BY EXTRACT(month from established);

-- HAVING
SELECT COUNT(*), language
FROM countries
GROUP BY language
HAVING COUNT(*) >= 2;

SELECT AVG(salary), status_id
FROM employees
GROUP BY status_id
HAVING AVG(salary) > 2000;

SELECT AVG(salary), COUNT(*), status_id
FROM employees
GROUP BY status_id
HAVING AVG(salary) > 2000 AND COUNT(*) >1;

SELECT AVG(salary), department_id, status_id
FROM employees
WHERE status_id IN (301, 304)
GROUP BY department_id, status_id;

SELECT AVG(salary), department_id, status_id
FROM employees
GROUP BY department_id, status_id
HAVING status_id IN (301, 304);

-- operatory UNION (ALL), INTERSECT, MINUS
SELECT name, shortname, 'R' FROM regions
UNION
SELECT name, code, 'K' FROM countries;

SELECT name, surname, FLOOR(MONTHS_BETWEEN(SYSDATE, birth_date)/12), 'P' FROM employees
UNION
SELECT name, surname, FLOOR(MONTHS_BETWEEN(SYSDATE, birth_date)/12), 'D' FROM dependents;

SELECT employee_id, name, surname, department_id FROM employees WHERE department_id = 101
UNION
SELECT employee_id, name, surname, department_id FROM employees WHERE department_id = 103;

SELECT employee_id, name, surname, department_id
FROM employees
WHERE department_id IN (101, 103);

SELECT * FROM positions WHERE name LIKE 'P%' or name LIKE 'K%' or name LIKE 'A%'
INTERSECT
SELECT * FROM positions WHERE min_salary >= 1500;

SELECT AVG(salary), position_id FROM employees GROUP BY position_id
MINUS
SELECT AVG(salary), position_id FROM employees GROUP BY position_id HAVING position_id = 102
ORDER BY 1 DESC;

-- PRACA DOMOWA !
-- 1. Zapoznaj si?? z materia??ami Oracle Academy dotycz??cymi grupowania oraz operacji na zbiorach.
-- 2. Wyznacz ??rednie zarobki pracownik??w ze wzgl??du na zak??ady, o ile s?? to pracownicy zatrudnieni przed 01.01.2020.
--      Nast??pnie dodatkowo ogranicz powy??sze zapytanie do tych zak??ad??w, kt??re zatrudniaj?? wi??cej ni?? 2 takie osoby.
SELECT AVG(salary), COUNT(*), department_id
FROM employees
WHERE date_employed < '01/01/2020'
GROUP BY department_id
HAVING COUNT(*) > 2;

-- 3. * Wyznacz ??rednie zarobki pracownik??w ze wzgl??du na zak??ady, o ile s?? to pracownicy zatrudnieni przed 01.01.2010.
--      Dodatkowo ogranicz powy??sze zapytanie do tych zak??ad??w, kt??re zatrudniaj?? wi??cej ni?? 2 osoby (w og??le, a nie tylko takie, kt??re zosta??y zatrudnione przed 01.01.2010)
SELECT AVG(salary), COUNT(*), department_id
FROM employees
WHERE date_employed < '01/01/2010'
GROUP BY department_id
MINUS
SELECT AVG(salary), COUNT(*), department_id
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 2;

-- 4. Napisz zapytanie kt??re dla ka??dego departamentu wy??wietli ??redni?? pensj?? w zale??no??ci od p??ci.
SELECT AVG(salary), department_id, gender
FROM employees
GROUP BY department_id, gender;
-- 5. Napisz zapytanie kt??re pogrupuje liczby kraj??w ze wzgl??du na pierwsz?? liter?? nazwy j??zyka u??ywanego w danym kraju.?
SELECT COUNT(*), SUBSTR(language,0,1)
FROM countries
GROUP BY SUBSTR(language,0,1);
-- 6. Polecenie SELECT name, surname, COUNT(*) FROM employees GROUP BY name HAVING COUNT(*) >=2; jest niepoprawne. Dlaczego?
SELECT name, surname, COUNT(*)
FROM employees
GROUP BY name
HAVING COUNT(*) >=2;
-- Dane grupujemy wzgl??dem imienia, nie mo??emy potem wy??wietli?? nawisk, poniewa?? do jednego imienia jest przypisane kilka nazwisk
-- 7. Dla ka??dego departamentu zwr???? informacj?? o maksymalnej pensji pracownika z tego departamentu.
SELECT MAX(salary), department_id
FROM employees
GROUP BY department_id;
-- 8. * Ile walut jest oficjaln?? walut?? wykorzystywan?? w wiecej ni?? 1 kraju??
SELECT COUNT(COUNT(*))
FROM countries
GROUP BY currency
HAVING COUNT(*) > 1;
-- 9. * Ile jest ??rednio zmian na stanowiskach (skorzystaj z positions_history)?
SELECT AVG(COUNT(*) - 1)
FROM positions_history
GROUP BY position_id;
-- 10. Przy grupowaniu danych wykorzystuj??c jedn?? kolumn??, ile powstanie grup danych?
Tyle ile jest unikalnych rekord??w w kolumnie