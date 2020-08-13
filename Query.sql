--1
--List the following details of each employee: employee number, last name, first name, sex, and salary.

select employees.emp_no, first_name, last_name, sex, salary
from employees, salaries
where employees.emp_no=salaries.emp_no

--2
--List first name, last name, and hire date for employees who were hired in 1986.
select first_name, last_name, hire_date 
from employees
where hire_date between '1986-01-01' and '1987-01-01'

--3
--List the manager of each department with the following information: department number, 
--department name, the manager's employee number, last name, first name.
select dept_man.dept_no, dept_name, dept_man.emp_no, irst_name, last_name
from employees, dept_man, departments
where dept_man.emp_no=employees.emp_no and dept_man.dept_no=departments.dept_no

--4
--List the department of each employee with the following information: employee number, last name, first name, and department name.
select dept_name, employees.emp_no, last_name, first_name
from departments, employees, dept_emp
where dept_emp.emp_no= employees.emp_no and dept_emp.dept_no=departments.dept_no

--5
select first_name, last_name, sex
from employees
where first_name='Hercules' and last_name like 'B%'

--6
--List all employees in the Sales department, including their employee number, last name, first name, and department name.
select employees.emp_no, first_name, last_name, dept_name
from dept_emp
inner join departments
on departments.dept_no=dept_emp.dept_no
inner join employees
on dept_emp.emp_no=employees.emp_no
where dept_name='Sales'



--7
--List all employees in the Sales and Development departments, including their employee number, 
--last name, first name, and department name.
select employees.emp_no, first_name, last_name, dept_name
from dept_emp
inner join departments
on departments.dept_no=dept_emp.dept_no
inner join employees
on dept_emp.emp_no=employees.emp_no
where dept_name='Sales' or dept_name='Development'


--8

SELECT last_name, COUNT(last_name)AS Frequency FROM employees
GROUP BY last_name
ORDER BY COUNT(last_name) DESC

