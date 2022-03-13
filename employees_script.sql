USE employees;

-- 1. Find the average salary of the male and female employees in each department.
SELECT e.gender, ROUND(AVG(s.salary), 2) AS avg_salary, d.dept_name
  FROM employees AS e
	   INNER JOIN salaries AS s
       ON e.emp_no = s.emp_no
       INNER JOIN dept_emp AS de
       ON s.emp_no = de.emp_no
       INNER JOIN departments AS d
       ON de.dept_no = d.dept_no
 GROUP BY d.dept_name, e.gender;


-- 2. Find the lowest department number encountered in the 'dept_emp' table. Then, find the highest department number.
SELECT MIN(dept_no) AS lowest_dept_num, MAX(dept_no) AS highest_dept_num
  FROM dept_emp;

  
-- 3. Obtain a table containing the following three fields for all individuals whose employee number is not greater than 10040:
-- 		- employee number
-- 		- the lowest department number among the departments where the employee has worked in
-- 		- assign '110022' as 'manager' to all individuals whose employee number is lower than or equal to 10020, and '110039' to those whose number is between 10021 and 10040 inclusive.
-- Use a CASE statement to create the third field.
SELECT emp_no, MIN(dept_no) AS dept_no,
  CASE
	   WHEN emp_no <= 10020 THEN 110022
       WHEN emp_no BETWEEN 10021 AND 10040 THEN 110039
   END AS manager
  FROM dept_emp
 WHERE emp_no <= 10040
 GROUP BY emp_no;


-- 4. Retrieve a list of all employees that have been hired in 2000.
SELECT first_name, last_name, hire_date
  FROM employees
 WHERE YEAR(hire_date) = 2000;


-- 5. Retrieve a list of all employees from the ‘titles’ table who are engineers.
-- Retrieve a list of all employees from the ‘titles’ table who are senior engineers.
SELECT emp_no, title
  FROM titles
 WHERE title LIKE '%engineer%';
 
 SELECT emp_no, title
   FROM titles
 WHERE title LIKE '%senior engineer%';


-- 6. Create a procedure that asks you to insert an employee number and that will obtain an output containing the same number, as well as the number and name of the last department the employee has worked in.
-- Finally, call the procedure for employee number 10010.
DROP PROCEDURE IF EXISTS emp_department;

DELIMITER //

CREATE PROCEDURE emp_department(IN p_emp_no INT)
BEGIN
	SELECT de.emp_no, de.dept_no, d.dept_name
      FROM dept_emp AS de
		   INNER JOIN departments AS d
           ON de.dept_no = d.dept_no
	 WHERE de.emp_no = p_emp_no
	   AND de.from_date =
		   (SELECT MAX(from_date)
              FROM dept_emp
			 WHERE emp_no = p_emp_no)
	 GROUP BY de.emp_no;
END//

DELIMITER ;

CALL emp_department(10010);


-- 7. How many contracts have been registered in the ‘salaries’ table with duration of more than one year and of value higher than or equal to $100,000?
SELECT COUNT(salary) AS total_contracts
  FROM salaries
 WHERE TIMESTAMPDIFF(YEAR, from_date, to_date) > 1
   AND salary >= 100000;


-- 8.Create a trigger that checks if the hire date of an employee is higher than the current date. If true, set the hire date to equal the current date. Format the output appropriately (YY-mm-dd).
-- Extra challenge: You can try to declare a new variable called 'today' which stores today's data, and then use it in your trigger!
-- After creating the trigger, execute the following code to see if it's working properly (refers to code after trigger creation).
SET @today = SYSDATE();

DROP TRIGGER IF EXISTS t_emp_hire_date;

DELIMITER //

CREATE TRIGGER t_emp_hire_date 
BEFORE INSERT ON employees 
FOR EACH ROW
BEGIN
	IF NEW.hire_date > @today THEN
		SET NEW.hire_date = @today;
	END IF;
END//

DELIMITER ;

-- After creating the trigger, execute the following code to see if it's working properly.
INSERT employees 
VALUES ('999904', '1970-01-31', 'John', 'Johnson', 'M', '2025-01-01');  

SELECT *
  FROM employees
 ORDER BY emp_no DESC;


-- 9. Define a function that retrieves the largest contract salary value of an employee. Apply it to employee number 11356. In addition, what is the lowest contract salary value of the same employee? 
-- You may want to create a new function to obtain the result.
DROP FUNCTION IF EXISTS f_largest_salary;

DELIMITER //

# Return an integer because the salary column in the salaries table is an integer data type
CREATE FUNCTION f_largest_salary(p_emp_no INT) RETURNS INT
BEGIN
    DECLARE max_salary INT;
    SELECT MAX(salary) INTO max_salary
      FROM salaries
	 WHERE emp_no = p_emp_no;
	RETURN max_salary;
END//


DROP FUNCTION IF EXISTS f_lowest_salary//

# Return an integer rather than a decimal because the salary column in the salaries table is an integer data type
CREATE FUNCTION f_lowest_salary(p_emp_no INT) RETURNS INT
BEGIN
	DECLARE min_salary INT;
    SELECT MIN(salary) INTO min_salary
      FROM salaries
	 WHERE emp_no = p_emp_no;
	RETURN min_salary;
END//

DELIMITER ;

SELECT f_largest_salary(11356) AS largest_salary;
SELECT f_lowest_salary(11356) AS lowest_salary;


-- 10. Based on the previous exercise, you can now try to create a third function that also accepts a second parameter. Let this parameter be a character sequence. Evaluate if its value is 'min' or 'max' 
-- and based on that retrieve either the lowest or the highest salary, respectively (using the same logic and code structure from Exercise 9). If the inserted value is any string value different from 
-- ‘min’ or ‘max’, let the function return the difference between the highest and the lowest salary of that employee.
DROP FUNCTION IF EXISTS f_salary_size;

DELIMITER //

# Return an integer rather than a decimal because the salary column in the salaries table is an integer data type
CREATE FUNCTION f_salary_size(p_emp_no INT, p_min_or_max CHAR(3)) RETURNS INT
BEGIN
	DECLARE salary_size INT;
    SELECT 
	  CASE
		   WHEN p_min_or_max = 'min' THEN MIN(salary)
           WHEN p_min_or_max = 'max' THEN MAX(salary)
           ELSE MAX(salary) - MIN(salary)
	   END AS salary_boundary INTO salary_size
	  FROM salaries
	 WHERE emp_no = p_emp_no;
	RETURN salary_size;
END//

DELIMITER ;

SELECT f_salary_size(11356, 'max') AS max_salary;
SELECT f_salary_size(11356, 'min')  AS min_salary;
SELECT f_salary_size(11356, 'abc') AS salary_difference;