CREATE OR REPLACE PACKAGE PKG_EMP AS
  -- CRUD
  PROCEDURE create_emp(
    p_first_name    IN EMPLOYEES.FIRST_NAME%TYPE,
    p_last_name     IN EMPLOYEES.LAST_NAME%TYPE,
    p_email         IN EMPLOYEES.EMAIL%TYPE,
    p_phone         IN EMPLOYEES.PHONE_NUMBER%TYPE,
    p_hire_date     IN DATE,
    p_job_id        IN EMPLOYEES.JOB_ID%TYPE,
    p_salary        IN EMPLOYEES.SALARY%TYPE,
    p_commission    IN EMPLOYEES.COMMISSION_PCT%TYPE,
    p_manager_id    IN EMPLOYEES.MANAGER_ID%TYPE,
    p_department_id IN EMPLOYEES.DEPARTMENT_ID%TYPE,
    p_employee_id   OUT EMPLOYEES.EMPLOYEE_ID%TYPE
  );

  PROCEDURE read_emp(p_employee_id IN NUMBER, p_rc OUT SYS_REFCURSOR);
  PROCEDURE update_emp(
    p_employee_id   IN EMPLOYEES.EMPLOYEE_ID%TYPE,
    p_first_name    IN EMPLOYEES.FIRST_NAME%TYPE DEFAULT NULL,
    p_last_name     IN EMPLOYEES.LAST_NAME%TYPE  DEFAULT NULL,
    p_email         IN EMPLOYEES.EMAIL%TYPE      DEFAULT NULL,
    p_phone         IN EMPLOYEES.PHONE_NUMBER%TYPE DEFAULT NULL,
    p_job_id        IN EMPLOYEES.JOB_ID%TYPE     DEFAULT NULL,
    p_salary        IN EMPLOYEES.SALARY%TYPE     DEFAULT NULL,
    p_commission    IN EMPLOYEES.COMMISSION_PCT%TYPE DEFAULT NULL,
    p_manager_id    IN EMPLOYEES.MANAGER_ID%TYPE DEFAULT NULL,
    p_department_id IN EMPLOYEES.DEPARTMENT_ID%TYPE DEFAULT NULL
  );
  PROCEDURE delete_emp(p_employee_id IN NUMBER);

  -- 3.1.1: Top 4 con más rotación de puesto (retorna cursor)
  PROCEDURE top4_job_rotation(p_rc OUT SYS_REFCURSOR);

  -- 3.1.2: Promedio de contrataciones por MES (muestra y retorna total meses)
  FUNCTION avg_hires_by_month RETURN NUMBER;

  -- 3.1.3: Gastos y estadística por región (retorna cursor)
  PROCEDURE region_payroll_stats(p_rc OUT SYS_REFCURSOR);

  -- 3.1.4: Tiempo de servicio y costo total de vacaciones (muestra y retorna total S/.)
  FUNCTION vacation_total_cost RETURN NUMBER;

END PKG_EMP;
/

CREATE OR REPLACE PACKAGE BODY PKG_EMP AS
  PROCEDURE assert_salary_in_range(p_job_id JOBS.JOB_ID%TYPE, p_salary NUMBER) IS
    v_min JOBS.MIN_SALARY%TYPE; v_max JOBS.MAX_SALARY%TYPE;
  BEGIN
    SELECT MIN_SALARY, MAX_SALARY INTO v_min, v_max FROM JOBS WHERE JOB_ID = p_job_id;
    IF p_salary < NVL(v_min,p_salary) OR p_salary > NVL(v_max,p_salary) THEN
      RAISE_APPLICATION_ERROR(-20001,'Salario fuera de rango para '||p_job_id);
    END IF;
  END;

  PROCEDURE create_emp( ... ) IS
  BEGIN
    SELECT NVL(MAX(EMPLOYEE_ID),0)+1 INTO p_employee_id FROM EMPLOYEES;
    assert_salary_in_range(p_job_id,p_salary);
    INSERT INTO EMPLOYEES(
      EMPLOYEE_ID,FIRST_NAME,LAST_NAME,EMAIL,PHONE_NUMBER,HIRE_DATE,JOB_ID,SALARY,COMMISSION_PCT,MANAGER_ID,DEPARTMENT_ID
    ) VALUES(
      p_employee_id,p_first_name,p_last_name,p_email,p_phone,TRUNC(p_hire_date),p_job_id,p_salary,p_commission,p_manager_id,p_department_id
    );
  END;

  PROCEDURE read_emp(p_employee_id IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR SELECT * FROM EMPLOYEES WHERE EMPLOYEE_ID = p_employee_id;
  END;

  PROCEDURE update_emp( ... ) IS
  BEGIN
    IF p_job_id IS NOT NULL AND p_salary IS NOT NULL THEN
      assert_salary_in_range(p_job_id,p_salary);
    END IF;
    UPDATE EMPLOYEES
    SET FIRST_NAME    = COALESCE(p_first_name, FIRST_NAME),
        LAST_NAME     = COALESCE(p_last_name,  LAST_NAME),
        EMAIL         = COALESCE(p_email,      EMAIL),
        PHONE_NUMBER  = COALESCE(p_phone,      PHONE_NUMBER),
        JOB_ID        = COALESCE(p_job_id,     JOB_ID),
        SALARY        = COALESCE(p_salary,     SALARY),
        COMMISSION_PCT= COALESCE(p_commission, COMMISSION_PCT),
        MANAGER_ID    = COALESCE(p_manager_id, MANAGER_ID),
        DEPARTMENT_ID = COALESCE(p_department_id, DEPARTMENT_ID)
    WHERE EMPLOYEE_ID = p_employee_id;
  END;

  PROCEDURE delete_emp(p_employee_id IN NUMBER) IS
  BEGIN
    DELETE FROM EMPLOYEES WHERE EMPLOYEE_ID = p_employee_id;
  END;

  ----------------------------------------------------------------------------
  -- 3.1.1  Top 4 con más cambios de puesto desde su ingreso
  ----------------------------------------------------------------------------
  PROCEDURE top4_job_rotation(p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR
    WITH rot AS (
      SELECT eh.EMPLOYEE_ID,
             COUNT(*) AS changes_cnt
      FROM JOB_HISTORY eh
      GROUP BY eh.EMPLOYEE_ID
    )
    SELECT e.EMPLOYEE_ID,
           e.LAST_NAME    AS APELLIDO,
           e.FIRST_NAME   AS NOMBRE,
           e.JOB_ID       AS JOB_ACTUAL,
           (SELECT j.JOB_TITLE FROM JOBS j WHERE j.JOB_ID = e.JOB_ID) AS NOMBRE_PUESTO_ACTUAL,
           NVL(r.changes_cnt,0) AS ROTACIONES
    FROM EMPLOYEES e
    LEFT JOIN rot r ON r.EMPLOYEE_ID = e.EMPLOYEE_ID
    ORDER BY NVL(r.changes_cnt,0) DESC, e.EMPLOYEE_ID
    FETCH FIRST 4 ROWS ONLY;
  END;

  ----------------------------------------------------------------------------
  -- 3.1.2  Función: promedio de contrataciones por mes (muestra y retorna N° meses)
  ----------------------------------------------------------------------------
  FUNCTION avg_hires_by_month RETURN NUMBER IS
    v_months NUMBER := 0;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('MES                         PROMEDIO_CONTRATACIONES');
    FOR r IN (
      SELECT TO_CHAR(HIRE_DATE,'TMMonth','NLS_DATE_LANGUAGE=English') AS mes,
             ROUND(AVG(cnt),2) AS prom
      FROM (
        SELECT EXTRACT(YEAR FROM HIRE_DATE) AS anio,
               EXTRACT(MONTH FROM HIRE_DATE) AS mes_num,
               COUNT(*) AS cnt
        FROM EMPLOYEES
        GROUP BY EXTRACT(YEAR FROM HIRE_DATE), EXTRACT(MONTH FROM HIRE_DATE)
      )
      JOIN (
        SELECT LEVEL AS mes_num FROM DUAL CONNECT BY LEVEL<=12
      ) m USING(mes_num)
      GROUP BY mes
      ORDER BY TO_DATE(mes,'Month')
    ) LOOP
      v_months := v_months + 1;
      DBMS_OUTPUT.PUT_LINE(RPAD(r.mes,28)||LPAD(r.prom,10));
    END LOOP;
    RETURN v_months;
  END;

  ----------------------------------------------------------------------------
  -- 3.1.3  Gastos/estadística por región
  ----------------------------------------------------------------------------
  PROCEDURE region_payroll_stats(p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR
      SELECT reg.REGION_NAME,
             SUM(e.SALARY)                 AS SUM_SALARY,
             COUNT(e.EMPLOYEE_ID)          AS EMP_COUNT,
             MIN(e.HIRE_DATE)              AS OLDEST_HIRE_DATE
      FROM REGIONS reg
      JOIN COUNTRIES c   ON c.REGION_ID = reg.REGION_ID
      JOIN LOCATIONS l   ON l.COUNTRY_ID = c.COUNTRY_ID
      JOIN DEPARTMENTS d ON d.LOCATION_ID = l.LOCATION_ID
      LEFT JOIN EMPLOYEES e ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
      GROUP BY reg.REGION_NAME
      ORDER BY reg.REGION_NAME;
  END;

  ----------------------------------------------------------------------------
  -- 3.1.4  Función: tiempo de servicio y costo total de vacaciones
  -- Regla: 1 mes de vacaciones por AÑO de servicio. Costo = (SALARY/12)*años.
  ----------------------------------------------------------------------------
  FUNCTION vacation_total_cost RETURN NUMBER IS
    v_total NUMBER := 0;
    v_years NUMBER;
    v_cost  NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('EMP_ID  AÑOS_SERVICIO  VACACIONES_MES  COSTO_VACACIONES');
    FOR r IN (SELECT EMPLOYEE_ID, HIRE_DATE, SALARY FROM EMPLOYEES) LOOP
      v_years := FLOOR(MONTHS_BETWEEN(TRUNC(SYSDATE), TRUNC(r.HIRE_DATE))/12);
      v_cost  := v_years * (NVL(r.SALARY,0)/12);
      v_total := v_total + v_cost;
      DBMS_OUTPUT.PUT_LINE(
        LPAD(r.EMPLOYEE_ID,6)||LPAD(v_years,15)||LPAD(v_years,16)||LPAD(TO_CHAR(ROUND(v_cost,2)),20)
      );
    END LOOP;
    RETURN ROUND(v_total,2);
  END;

END PKG_EMP;
/

-- 1) Maestro de horarios (hora de inicio/fin con fecha base 2000-01-01)
CREATE TABLE HORARIO (
  DIA_SEMANA    NUMBER(1)      NOT NULL,  -- 1=Lunes ... 7=Domingo
  TURNO         VARCHAR2(1)    NOT NULL,  -- M/T/N (Mañana/Tarde/Noche)
  HORA_INICIO   DATE           NOT NULL,  -- usar fecha base y solo la hora
  HORA_TERMINO  DATE           NOT NULL,
  CONSTRAINT PK_HORARIO PRIMARY KEY (DIA_SEMANA, TURNO)
);

-- 2) Asignación de horario a empleado
CREATE TABLE EMPLEADO_HORARIO (
  EMPLOYEE_ID   NUMBER(6)      NOT NULL,
  DIA_SEMANA    NUMBER(1)      NOT NULL,
  TURNO         VARCHAR2(1)    NOT NULL,
  CONSTRAINT PK_EMPL_HOR PRIMARY KEY (EMPLOYEE_ID, DIA_SEMANA, TURNO),
  CONSTRAINT FK_EH_EMP FOREIGN KEY (EMPLOYEE_ID) REFERENCES EMPLOYEES(EMPLOYEE_ID),
  CONSTRAINT FK_EH_HOR FOREIGN KEY (DIA_SEMANA, TURNO) REFERENCES HORARIO(DIA_SEMANA, TURNO)
);

-- 3) Registro de asistencia (agrego STATUS para 3.4)
CREATE TABLE ASISTENCIA_EMPLEADO (
  EMPLOYEE_ID        NUMBER(6) NOT NULL,
  DIA_SEMANA         NUMBER(1) NOT NULL,
  FECHA_REAL         DATE      NOT NULL,   -- fecha del día trabajado
  HORA_INICIO_REAL   DATE      NOT NULL,   -- fecha+hora
  HORA_TERMINO_REAL  DATE      NOT NULL,   -- fecha+hora
  STATUS             VARCHAR2(12) DEFAULT 'PRESENTE' NOT NULL, -- PRESENTE / INASISTENTE
  CONSTRAINT PK_ASIS PRIMARY KEY (EMPLOYEE_ID, FECHA_REAL),
  CONSTRAINT FK_ASIS_EMP FOREIGN KEY (EMPLOYEE_ID) REFERENCES EMPLOYEES(EMPLOYEE_ID)
);


-- Helpers para hora base
VAR d1 DATE
EXEC :d1 := TO_DATE('2000-01-01','YYYY-MM-DD');

-- HORARIO (Lunes-Viernes, dos turnos; Sábado medio turno)
INSERT INTO HORARIO VALUES (1,'M', :d1 +  9/24, :d1 + 13/24);
INSERT INTO HORARIO VALUES (1,'T', :d1 + 14/24, :d1 + 18/24);
INSERT INTO HORARIO VALUES (2,'M', :d1 +  9/24, :d1 + 13/24);
INSERT INTO HORARIO VALUES (2,'T', :d1 + 14/24, :d1 + 18/24);
INSERT INTO HORARIO VALUES (3,'M', :d1 +  9/24, :d1 + 13/24);
INSERT INTO HORARIO VALUES (3,'T', :d1 + 14/24, :d1 + 18/24);
INSERT INTO HORARIO VALUES (4,'M', :d1 +  9/24, :d1 + 13/24);
INSERT INTO HORARIO VALUES (4,'T', :d1 + 14/24, :d1 + 18/24);
INSERT INTO HORARIO VALUES (5,'M', :d1 +  9/24, :d1 + 13/24);
INSERT INTO HORARIO VALUES (5,'T', :d1 + 14/24, :d1 + 18/24);
INSERT INTO HORARIO VALUES (6,'M', :d1 +  9/24, :d1 + 12/24); -- sábado
-- (11 filas)

-- Empleados de ejemplo
DEFINE EMP1 = 100
DEFINE EMP2 = 101
DEFINE EMP3 = 102
DEFINE EMP4 = 103
DEFINE EMP5 = 104

-- EMPLEADO_HORARIO (asignar de lunes a viernes turno M)
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP1,1,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP1,2,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP1,3,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP1,4,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP1,5,'M');

INSERT INTO EMPLEADO_HORARIO VALUES (&EMP2,1,'T');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP2,2,'T');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP2,3,'T');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP2,4,'T');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP2,5,'T');

INSERT INTO EMPLEADO_HORARIO VALUES (&EMP3,1,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP3,3,'M');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP3,5,'M');

INSERT INTO EMPLEADO_HORARIO VALUES (&EMP4,2,'T');
INSERT INTO EMPLEADO_HORARIO VALUES (&EMP4,4,'T');

INSERT INTO EMPLEADO_HORARIO VALUES (&EMP5,6,'M');
-- (15+ filas)

-- ASISTENCIA_EMPLEADO (10+ filas, ejemplo en un mes)
-- Supón registros de julio 2025
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP1,1, DATE '2025-07-07', DATE '2025-07-07' + 9/24,  DATE '2025-07-07' + 13/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP1,2, DATE '2025-07-08', DATE '2025-07-08' + 9/24,  DATE '2025-07-08' + 13/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP1,3, DATE '2025-07-09', DATE '2025-07-09' + 9/24,  DATE '2025-07-09' + 13/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP1,4, DATE '2025-07-10', DATE '2025-07-10' + 9/24,  DATE '2025-07-10' + 13/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP1,5, DATE '2025-07-11', DATE '2025-07-11' + 9/24,  DATE '2025-07-11' + 13/24, 'PRESENTE');

INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP2,1, DATE '2025-07-07', DATE '2025-07-07' + 14/24, DATE '2025-07-07' + 18/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP2,2, DATE '2025-07-08', DATE '2025-07-08' + 14/24, DATE '2025-07-08' + 18/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP2,3, DATE '2025-07-09', DATE '2025-07-09' + 14/24, DATE '2025-07-09' + 18/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP2,4, DATE '2025-07-10', DATE '2025-07-10' + 14/24, DATE '2025-07-10' + 18/24, 'PRESENTE');
INSERT INTO ASISTENCIA_EMPLEADO VALUES (&EMP2,5, DATE '2025-07-11', DATE '2025-07-11' + 14/24, DATE '2025-07-11' + 18/24, 'PRESENTE');
COMMIT;


CREATE OR REPLACE FUNCTION FN_HORAS_TRABAJADAS(
  p_employee_id IN NUMBER,
  p_mes         IN NUMBER,  -- 1..12
  p_anio        IN NUMBER
) RETURN NUMBER IS
  v_total NUMBER := 0;
BEGIN
  SELECT NVL(SUM(
           (HORA_TERMINO_REAL - HORA_INICIO_REAL) * 24
         ),0)
  INTO v_total
  FROM ASISTENCIA_EMPLEADO
  WHERE EMPLOYEE_ID = p_employee_id
    AND EXTRACT(MONTH FROM FECHA_REAL) = p_mes
    AND EXTRACT(YEAR  FROM FECHA_REAL) = p_anio
    AND STATUS = 'PRESENTE';

  RETURN ROUND(v_total,2);
END;
/


CREATE OR REPLACE FUNCTION FN_HORAS_FALTA(
  p_employee_id IN NUMBER,
  p_mes         IN NUMBER,
  p_anio        IN NUMBER
) RETURN NUMBER IS
  v_prog NUMBER := 0;
  v_trab NUMBER := 0;
BEGIN
  -- Horas programadas = sumatoria por cada día del mes que coincide con el día de semana asignado
  SELECT NVL(SUM(
           -- cantidad de ocurrencias del día de semana en el mes * duración del turno
           (
             -- ocurrencias del día de semana:
             (SELECT COUNT(*)
              FROM (
                SELECT TRUNC(ADD_MONTHS(DATE '2000-01-01', (p_anio-2000)*12 + (p_mes-1)) + LEVEL - 1) AS d
                FROM DUAL
                CONNECT BY LEVEL <= TO_NUMBER(TO_CHAR(LAST_DAY(TO_DATE(p_anio||'-'||p_mes||'-01','YYYY-MM-DD')),'DD'))
              )
              WHERE TO_CHAR(d,'D','NLS_DATE_LANGUAGE=AMERICAN') = TO_CHAR(TO_DATE(eh.DIA_SEMANA,'D'),'D','NLS_DATE_LANGUAGE=AMERICAN')
                 AND EXTRACT(MONTH FROM d + (DATE '2000-01-01' - DATE '2000-01-01')) = p_mes
             )
             *
             -- duración del turno en horas
             ((h.HORA_TERMINO - h.HORA_INICIO) * 24)
           )
         ),0)
  INTO v_prog
  FROM EMPLEADO_HORARIO eh
  JOIN HORARIO h ON (h.DIA_SEMANA=eh.DIA_SEMANA AND h.TURNO=eh.TURNO)
  WHERE eh.EMPLOYEE_ID = p_employee_id;

  -- Horas efectivamente trabajadas
  v_trab := FN_HORAS_TRABAJADAS(p_employee_id,p_mes,p_anio);

  RETURN GREATEST(ROUND(v_prog - v_trab,2),0);
END;
/

CREATE OR REPLACE PROCEDURE SP_PAGO_MENSUAL(
  p_mes  IN NUMBER,
  p_anio IN NUMBER,
  p_rc   OUT SYS_REFCURSOR
) AS
BEGIN
  OPEN p_rc FOR
  WITH prog AS (
    SELECT e.EMPLOYEE_ID,
           FN_HORAS_TRABAJADAS(e.EMPLOYEE_ID,p_mes,p_anio) AS hrs_trab,
           CASE
             WHEN (SELECT COUNT(*) FROM EMPLEADO_HORARIO x WHERE x.EMPLOYEE_ID=e.EMPLOYEE_ID)=0 THEN 0
             ELSE FN_HORAS_FALTA(e.EMPLOYEE_ID,p_mes,p_anio) +
                  FN_HORAS_TRABAJADAS(e.EMPLOYEE_ID,p_mes,p_anio)
           END AS hrs_prog
    FROM EMPLOYEES e
  )
  SELECT e.FIRST_NAME AS NOMBRE,
         e.LAST_NAME  AS APELLIDO,
         e.SALARY,
         p.hrs_trab,
         p.hrs_prog,
         CASE WHEN p.hrs_prog=0 THEN 0
              ELSE ROUND(e.SALARY * (p.hrs_trab/p.hrs_prog),2)
         END AS SUELDO_MES
  FROM EMPLOYEES e
  JOIN prog p ON p.EMPLOYEE_ID = e.EMPLOYEE_ID
  ORDER BY SUELDO_MES DESC, e.LAST_NAME;
END;
/