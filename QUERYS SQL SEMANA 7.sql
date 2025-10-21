-- 1. Obtenga el color y ciudad para las partes que no sON de París, cON un peso mayor de diez.

SELECT color, city
FROM P
WHERE city <> 'Paris' AND weight > 10;

-- 2. Para todas las partes, obtenga el número de parte y el peso de dichas partes en gramos.

SELECT "P#" AS part_no, weight*453.592 AS weight_grams
FROM P;

-- 3. Obtenga el detalle completo de todos los proveedores.

SELECT *
FROM S;

-- 4. Obtenga todas las combinaciONes de proveedores y partes para aquellos proveedores y partes co-localizados.

SELECT s."S#", p."P#"
FROM S s JOIN P p
  ON s.city = p.city;

-- 5. Obtenga todos los pares de nombres de ciudades de tal forma que el proveedor localizado en la primera ciudad del par abastece una parte almacenada en la segunda ciudad del par.

SELECT DISTINCT s.city AS supplier_city, p.city AS part_city
FROM S s
JOIN SP sp ON sp."S#" = s."S#"
JOIN P  p  ON p."P#"  = sp."P#";

-- 6. Obtenga todos los pares de número de proveedor tales que los dos proveedores del par estén co-localizados.

SELECT DISTINCT s1."S#" AS supplier1, s2."S#" AS supplier2
FROM S s1
JOIN S s2 ON s1.city = s2.city AND s1."S#" < s2."S#";

-- 7. Obtenga el número total de proveedores.

SELECT COUNT(*) AS total_suppliers
FROM S;

-- 8. Obtenga la cantidad mínima y la cantidad máxima para la parte P2.

SELECT MIN(qty) AS min_qty, MAX(qty) AS max_qty
FROM SP
WHERE "P#" = 'P2';

-- 9. Para cada parte abastecida, obtenga el número de parte y el total despachado.

SELECT "P#" AS part_no, SUM(qty) AS total_qty
FROM SP
GROUP BY "P#";

-- 10. Obtenga el número de parte para todas las partes abastecidas por más de un proveedor.

SELECT "P#" AS part_no
FROM SP
GROUP BY "P#"
HAVING COUNT(DISTINCT "S#") > 1;

-- 11. Obtenga el nombre de proveedor para todos los proveedores que abastecen la parte P2.

SELECT DISTINCT s.sname
FROM S s
JOIN SP sp ON sp."S#" = s."S#"
WHERE sp."P#" = 'P2';

-- 12. Obtenga el nombre de proveedor de quienes abastecen por lo menos una parte.

SELECT sname
FROM S s
WHERE EXISTS (SELECT 1 FROM SP sp WHERE sp."S#" = s."S#");

-- 13. Obtenga el número de proveedor para los proveedores cON estado menor que el máximo valor de estado en la tabla S. 

SELECT "S#"
FROM S
WHERE status = (SELECT MAX(status) FROM S);

-- 14. Obtenga el nombre de proveedor para los proveedores que abastecen la parte P2 (aplicar EXISTS en su solución).

SELECT sname
FROM S s
WHERE EXISTS (
  SELECT 1 FROM SP sp
  WHERE sp."S#" = s."S#" AND sp."P#" = 'P2'
);

-- 15. Obtenga el nombre de proveedor para los proveedores que no abastecen la parte P2.

SELECT sname
FROM S s
WHERE NOT EXISTS (
  SELECT 1 FROM SP sp
  WHERE sp."S#" = s."S#" AND sp."P#" = 'P2'
);

-- 16. Obtenga el nombre de proveedor para los proveedores que abastecen todas las partes. 

SELECT sname
FROM S s
WHERE NOT EXISTS (
  SELECT 1 FROM P p
  WHERE NOT EXISTS (
    SELECT 1 FROM SP sp
    WHERE sp."S#" = s."S#" AND sp."P#" = p."P#"
  )
);

-- 17. Obtenga el número de parte para todas las partes que pesan más de 16 libras ó sON abastecidas por el proveedor S2, ó cumplen cON ambos criterios.

SELECT "P#" AS part_no
FROM P p
WHERE p.weight > 16
   OR EXISTS (
        SELECT 1 FROM SP sp
        WHERE sp."P#" = p."P#" AND sp."S#" = 'S2'
    );