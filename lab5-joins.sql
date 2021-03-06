-- zlaczenia kartezjanskie
SELECT e.employee_id, g.grade, g.description
FROM employees e
CROSS JOIN grades g;

SELECT e.employee_id, g.grade, g.description
FROM employees e CROSS JOIN grades g
WHERE e.department_id IS NULL or e.department_id IN (101, 102, 103);

-- zlaczenia wewnetrzne
SELECT *
FROM employees e JOIN positions p ON (e.position_id = p.position_id)
WHERE e.salary NOT BETWEEN p.min_salary AND p.max_salary;

SELECT e.*, p.*, d.name
FROM employees e JOIN positions p ON (e.position_id = p.position_id) JOIN departments d ON(d.department_id = e.department_id)
WHERE e.salary NOT BETWEEN p.min_salary AND p.max_salary;

SELECT *
FROM departments d JOIN employees e ON (d.manager_id = e.employee_id)
WHERE d.year_budget BETWEEN 5000000 AND 10000000;

SELECT d.name
FROM departments d JOIN addresses a ON (d.address_id = a.address_id) JOIN countries c ON (a.country_id = c.country_id)
WHERE c.name LIKE 'Polska';

SELECT *
FROM departments d JOIN employees e ON (d.manager_id = e.employee_id) JOIN addresses a ON (d.address_id = a.address_id) JOIN countries c ON (a.country_id = c.country_id)
WHERE (d.year_budget BETWEEN 5000000 AND 10000000) AND c.name LIKE 'Polska';

SELECT e.name, e.surname, g.grade, g.description
FROM employees e JOIN emp_grades eg ON (eg.employee_id = e.employee_id) JOIN grades g ON (eg.grade_id = g.grade_id)
WHERE e.manager_id IS NULL;

SELECT c.name, r.name
FROM reg_countries rc  NATURAL JOIN regions r JOIN countries c ON(c.country_id = rc.country_id);

--zlaczenia zewnetrzne
SELECT e.surname, p.name, e.salary, p.min_salary, p.max_salary
FROM employees e LEFT JOIN positions p ON (e.position_id = p.position_id);

SELECT p.position_id, AVG(e.salary), COUNT(e.employee_id)
FROM positions p LEFT JOIN employees e ON (e.position_id = p.position_id)
GROUP BY p.position_id;

SELECT p.project_id, COUNT(*)
FROM projects p LEFT JOIN emp_projects ep ON (p.project_id = ep.project_id)
GROUP BY p.project_id;

SELECT d.department_id, d.name, AVG(g.grade)
FROM departments d LEFT JOIN employees e ON (e.department_id = d.department_id) JOIN emp_grades eg ON (e.employee_id = eg.employee_id) JOIN grades g ON (g.grade_id = eg.grade_id)
GROUP BY d.department_id, d.name;

--zlaczenia i grupowanie

SELECT e.name, COUNT(*), AVG(salary)
FROM employees e JOIN departments d ON(e.department_id = d.department_id)
WHERE d.name IN ('Administracja', 'Marketing')
GROUP BY e.name;

SELECT e.name, e.surname, COUNT(*)
FROM employees e JOIN positions_history ph ON (e.employee_id = ph.employee_id)
GROUP BY e.employee_id, e.name, e.surname
HAVING COUNT(ph.position_id) > 2
ORDER BY COUNT(ph.position_id) DESC;

SELECT man.employee_id, man.surname, COUNT(*)
FROM employees man JOIN employees e ON (man.employee_id = e.manager_id)
GROUP BY man.employee_id, man.surname
ORDER BY COUNT (*) DESC;

SELECT c.name, c.population, COUNT(*)
FROM departments d JOIN addresses a ON (d.address_id = a.address_id) RIGHT JOIN countries c ON (a.country_id = c.country_id)
GROUP BY c.country_id, c.name, c.population;

SELECT r.region_id, r.name, COUNT(*)
FROM departments d JOIN addresses a ON (d.address_id = a.address_id)
RIGHT JOIN countries c ON (a.country_id = c.country_id)
RIGHT JOIN reg_countries rc ON (rc.country_id = c.country_id)
RIGHT JOIN regions r ON (r.region_id = rc.region_id)
GROUP BY r.region_id, r.name
ORDER BY COUNT(*) DESC;

-- PRACA DOMOWA

--1. Napisz zapytanie znajduj??ce liczb?? zmian stanowisk pracownika Jan Kowalski.
SELECT e.employee_id, COUNT(*)
FROM employees e LEFT JOIN positions_history ph ON (e.employee_id = ph.employee_id)
WHERE e.name LIKE 'Jan' AND e.surname LIKE 'Kowalski'
GROUP BY e.employee_id;
--2. Napisz zapytanie znajduj??ce ??redni?? pensj?? dla ka??dego ze stanowisk. Wynik
--powinien zawiera?? nazw?? stanowiska i zaokr??glon?? ??redni?? pensj??.
SELECT p.name, ROUND(AVG(e.salary))
FROM employees e JOIN positions p ON (e.position_id = p.position_id)
GROUP BY p.position_id, p.name;
--3. Pobierz wszystkich pracownik??w zak??adu Kadry lub Finanse wraz z informacj?? w
--jakim zak??adzie pracuj??.
SELECT *
FROM employees e JOIN departments d ON (e.department_id = d.department_id)
WHERE d.name IN ('Kadry', 'Finanse');
--4. Znajd?? pracownik??w, kt??rych zarobki nie s?? zgodne z ???wide??kami??? na jego
--stanowisku. Zwr???? imi??, nazwisko, wynagrodzenie oraz nazw?? stanowiska.
--Zrealizuj za pomoc?? z????czenia nier??wno??ciowego.
SELECT *
FROM employees e LEFT JOIN positions p ON (e.position_id = p.position_id AND e.salary NOT BETWEEN p.min_salary AND p.max_salary);
--5. Poka?? nazwy region??w w kt??rych nie ma ??adnego kraju.
SELECT r.name
FROM regions r LEFT JOIN reg_countries rc ON (r.region_id = rc.region_id)
WHERE rc.country_id IS NULL;
--6. Wykonaj z????czenie naturalne mi??dzy tabelami countries a regions. Jaki wynik
--otrzymujemy i dlaczego?
SELECT *
FROM countries c NATURAL JOIN regions r;
-- mamy pust?? tabl?? z wynikami, poniewa?? ??aczymy tabl?? countries i regions po ws??lnej kolumnie, czyli 'name', a nie ma regioniu z tak?? sam?? nazw?? kraju.

--7. Jaki otrzymamy wynik je??li zrobimy NATURAL JOIN na tabelach bez wsp??lnej
--kolumny? Sprawd?? i zastan??w si?? nad przyczyn??
SELECT *
FROM positions p NATURAL JOIN grades g;
-- otrzymujemy wszytskie mo??liwe rekordy, poniewa?? nie by??o wsp??lnej kolumny, wykona?? si?? CROSS JOIN.