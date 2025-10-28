CREATE OR REPLACE TRIGGER TRG_ASIS_VALIDACION
BEFORE INSERT ON ASISTENCIA_EMPLEADO
FOR EACH ROW
DECLARE
  v_dia_sem NUMBER;
  v_hini DATE; v_hfin DATE;
BEGIN
  -- (a) día de semana
  v_dia_sem := TO_NUMBER(TO_CHAR(:NEW.FECHA_REAL,'D','NLS_DATE_LANGUAGE=AMERICAN')); -- 1..7
  IF :NEW.DIA_SEMANA <> v_dia_sem THEN
    RAISE_APPLICATION_ERROR(-20030,'Día de la semana no coincide con FECHA_REAL.');
  END IF;

  -- (b) obtener horario del empleado (puede tener varios turnos; tomamos el primero que calce por hora real)
  SELECT h.HORA_INICIO, h.HORA_TERMINO
    INTO v_hini, v_hfin
  FROM EMPLEADO_HORARIO eh
  JOIN HORARIO h ON h.DIA_SEMANA = eh.DIA_SEMANA AND h.TURNO = eh.TURNO
  WHERE eh.EMPLOYEE_ID = :NEW.EMPLOYEE_ID
    AND eh.DIA_SEMANA  = :NEW.DIA_SEMANA
    FETCH FIRST 1 ROWS ONLY;

  -- (c) validar que las horas reales caen dentro del turno programado
  IF (TO_CHAR(:NEW.HORA_INICIO_REAL,'HH24:MI') < TO_CHAR(v_hini,'HH24:MI')
      OR TO_CHAR(:NEW.HORA_TERMINO_REAL,'HH24:MI') > TO_CHAR(v_hfin,'HH24:MI')
      OR :NEW.HORA_TERMINO_REAL <= :NEW.HORA_INICIO_REAL) THEN
    RAISE_APPLICATION_ERROR(-20031,'Horas reales fuera del rango de turno o inconsistentes.');
  END IF;
END;
/