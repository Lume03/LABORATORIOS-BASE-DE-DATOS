SET SERVEROUTPUT ON
DECLARE
  v_rows_90 NUMBER;
  v_rows_60 NUMBER;
BEGIN
  -- +10% al depto 90
  UPDATE employees SET salary = salary * 1.10 WHERE department_id = 90;
  v_rows_90 := SQL%ROWCOUNT;

  SAVEPOINT punto1;

  -- +5% al depto 60 (se deshará)
  UPDATE employees SET salary = salary * 1.05 WHERE department_id = 60;
  v_rows_60 := SQL%ROWCOUNT;

  -- Reversión parcial
  ROLLBACK TO punto1;

  COMMIT;

  DBMS_OUTPUT.PUT_LINE('Afectados D90: '||v_rows_90||' | Afectados D60 (revertidos): '||v_rows_60);
END;
/

a. El departamento 90 mantiene el +10% (se confirmó).

b. El ROLLBACK TO punto1 deshizo solo lo hecho después del savepoint (el +5% del depto 60), dejando intacto el +10% del 90.

c. Un ROLLBACK total (sin savepoint) desharía toda la transacción pendiente, incluyendo el +10% del 90, quedando como al inicio.