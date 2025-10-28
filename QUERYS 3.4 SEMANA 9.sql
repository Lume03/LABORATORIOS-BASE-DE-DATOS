CREATE OR REPLACE TRIGGER TRG_ASIS_VENTANA_INGRESO
BEFORE INSERT ON ASISTENCIA_EMPLEADO
FOR EACH ROW
DECLARE
  v_hini DATE; v_hfin DATE;
  v_fecha DATE := TRUNC(:NEW.FECHA_REAL);
  v_ok_window BOOLEAN := FALSE;
BEGIN
  -- obtener hora de inicio/fin del turno (el primero del día)
  SELECT h.HORA_INICIO, h.HORA_TERMINO
    INTO v_hini, v_hfin
  FROM EMPLEADO_HORARIO eh
  JOIN HORARIO h ON h.DIA_SEMANA=eh.DIA_SEMANA AND h.TURNO=eh.TURNO
  WHERE eh.EMPLOYEE_ID=:NEW.EMPLOYEE_ID AND eh.DIA_SEMANA=:NEW.DIA_SEMANA
  FETCH FIRST 1 ROWS ONLY;

  -- construir la hora exacta del día real
  v_hini := v_fecha + (v_hini - TRUNC(v_hini));
  v_hfin := v_fecha + (v_hfin - TRUNC(v_hfin));

  -- ventana: -30 a +30 minutos respecto a inicio
  IF :NEW.HORA_INICIO_REAL BETWEEN (v_hini - (30/1440)) AND (v_hini + (30/1440)) THEN
    v_ok_window := TRUE;
  END IF;

  IF NOT v_ok_window THEN
    :NEW.STATUS := 'INASISTENTE';
    :NEW.HORA_INICIO_REAL  := v_fecha; -- neutraliza
    :NEW.HORA_TERMINO_REAL := v_fecha;
  END IF;
END;
/