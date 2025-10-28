SET SERVEROUTPUT ON
DECLARE
  v_a NUMBER; v_b NUMBER; v_del NUMBER;
BEGIN
  UPDATE employees SET salary = salary * 1.08 WHERE department_id = 100;
  v_a := SQL%ROWCOUNT;
  SAVEPOINT A;

  UPDATE employees SET salary = salary * 1.05 WHERE department_id = 80;
  v_b := SQL%ROWCOUNT;
  SAVEPOINT B;

  DELETE FROM employees WHERE department_id = 50;
  v_del := SQL%ROWCOUNT;

  ROLLBACK TO B; -- Revierte la eliminación y cualquier cambio tras B

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('+8% D100: '||v_a||' filas | +5% D80: '||v_b||' filas | Eliminados D50 (revertidos): '||v_del);
END;
/


a. Quedan persistentes: el +8% del depto 100 y el +5% del depto 80 (porque el rollback fue “hasta B”, no antes).

b. Las filas eliminadas del depto 50 se recuperan (la eliminación se deshace con ROLLBACK TO B).

c. Puedes verificar con SELECT antes/después y, si quieres ver DML no confirmados en tu sesión, usar vistas como FLASHBACK (si habilitado) o simplemente revisar en otra sesión tras el COMMIT.