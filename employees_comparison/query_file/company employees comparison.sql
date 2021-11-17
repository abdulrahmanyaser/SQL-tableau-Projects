use employees_mod ;	

# at first let's look at the number of employees joined the company starting from the year 1990  
SELECT 
    YEAR(td.from_date) AS calender_Year,
    te.gender,
    COUNT(te.emp_no) AS number_of_employees
FROM
    t_dept_emp td
        JOIN
    t_employees te 
	ON td.emp_no = te.emp_no
GROUP BY calender_Year , te.gender
HAVING calender_Year >= 1990
ORDER BY td.from_date;

# now let's check how many male and female managers at each department and which years they worked in .

SELECT 
    d.dept_name,
    ee.gender,
    dm.emp_no,
    dm.from_date,
    dm.to_date,
    e.calendar_year,
    CASE
        WHEN
            YEAR(dm.to_date) >= e.calendar_year
                AND YEAR(dm.from_date) <= e.calendar_year
        THEN 1
        ELSE 0
    END AS active
FROM
    (SELECT 
        YEAR(hire_date) AS calendar_year
    FROM
        t_employees
    GROUP BY calendar_year) e
        CROSS JOIN # the cross join is to show all the available years and which of 'em the employee worked in 
    t_dept_manager dm
        JOIN
    t_departments d ON dm.dept_no = d.dept_no
        JOIN
    t_employees ee ON dm.emp_no = ee.emp_no
ORDER BY dm.emp_no , calendar_year;

# comparing between average salary for males and females in each department untill 2002
SELECT 
    td.dept_name,
    te.gender,
    ROUND(AVG(ts.salary), 2) average_salary,
    YEAR(tde.from_date) calendar_year
FROM
    t_departments td
        JOIN
    t_dept_emp tde ON td.dept_no = tde.dept_no
        JOIN
    t_salaries ts ON ts.emp_no = tde.emp_no
        JOIN
    t_employees te ON ts.emp_no = te.emp_no
GROUP BY td.dept_name , te.gender , calendar_year
HAVING calendar_year >= 1990
ORDER BY calendar_year , td.dept_name;


# creating a procedure filter to compare between male and female salary based on provided  salary  range

DROP PROCEDURE IF EXISTS filter_salary;

DELIMITER $$
CREATE PROCEDURE filter_salary (IN p_min_salary FLOAT, IN p_max_salary FLOAT)
BEGIN
SELECT 
    te.gender, 
    td.dept_name, 
    AVG(ts.salary) as avg_salary
FROM
    t_salaries ts
        JOIN
    t_employees te ON ts.emp_no = te.emp_no
        JOIN
    t_dept_emp tde ON tde.emp_no = te.emp_no
        JOIN
    t_departments td ON td.dept_no = tde.dept_no
    WHERE ts.salary BETWEEN p_min_salary AND p_max_salary
GROUP BY td.dept_no, te.gender;
END$$
DELIMITER ;

CALL filter_salary(50000, 90000); # u can simply change the comparison range and have fun :)


