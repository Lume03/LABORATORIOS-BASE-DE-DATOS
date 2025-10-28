SET SERVEROUTPUT ON
DECLARE
  v_emp_id   employees.employee_id%TYPE := 104;
  v_new_dept employees.department_id%TYPE := 110;
  v_old_dept employees.department_id%TYPE;
  v_job_id   employees.job_id%TYPE;
  v_start    DATE;
BEGIN
  -- Tomamos datos actuales del empleado
  SELECT department_id, job_id, hire_date
  INTO   v_old_dept,  v_job_id, v_start
  FROM   employees
  WHERE  employee_id = v_emp_id
  FOR UPDATE; -- asegura consistencia

  -- Actualizamos el departamento
  UPDATE employees
  SET department_id = v_new_dept
  WHERE employee_id = v_emp_id;

  -- Registramos el movimiento en JOB_HISTORY
  INSERT INTO job_history(employee_id, start_date, end_date, job_id, department_id)
  VALUES (v_emp_id, v_start, SYSDATE, v_job_id, v_old_dept);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Transferencia OK: Emp '||v_emp_id||' -> Dept '||v_new_dept);
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Error, se revirtió: '||SQLERRM);
END;
/

a. Se requiere atomicidad: o se actualiza EMPLOYEES y se inserta JOB_HISTORY juntas, o no se hace nada; así el historial refleja la realidad.

b. Si hay error antes del COMMIT, el ROLLBACK vuelve todo al estado previo (no hay cambio de departamento ni registro en JOB_HISTORY).

c. La integridad se asegura con la transacción única y las FK (JOB_HISTORY.DEPARTMENT_ID y EMPLOYEE_ID) además del manejo de errores que hace ROLLBACK ante fallos.