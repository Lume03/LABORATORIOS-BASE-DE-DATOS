UPDATE employees
SET salary = salary + 500
WHERE employee_id = 103;


UPDATE employees
SET salary = salary + 100
WHERE employee_id = 103;


ROLLBACK; 

a. La segunda sesión quedó bloqueada porque la fila EMPLOYEE_ID=103 estaba bloqueada por la transacción abierta de la sesión 1 (bloqueo de fila por DML sin confirmar).

b. COMMIT o ROLLBACK de la sesión que posee el bloqueo liberan los bloqueos.

c. Puedes ver bloqueos con V$LOCK, sesiones con V$SESSION, y relaciones bloqueador/bloqueado con DBA_BLOCKERS y DBA_WAITERS (si tienes privilegios).