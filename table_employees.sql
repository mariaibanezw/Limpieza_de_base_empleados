----------------------------------------------------
------------ PROYECTO LIMPIEZA DE DATOS ------------
----------------------------------------------------

-- Creación de la base de datos
CREATE DATABASE CleanDatabase;
USE CleanDatabase;

-- Importacion de archivo CSV. Creación de tabla principal

-- Duplicado de tabla 
SELECT * INTO Employees FROM Original;


-- Ver la tabla
SELECT * FROM Employees; 

-- Cambiar los nombres de las columnas
EXEC sp_rename 'Employees.[Id?empleado]', 'Id', 'COLUMN';

EXEC sp_rename 'Employees.[Apellido]', 'Last_Name', 'COLUMN'

EXEC sp_rename 'Employees.[birth_date]', 'Birth_Date', 'COLUMN';

EXEC sp_rename 'Employees.[género]', 'Gender', 'COLUMN';

EXEC sp_rename 'Employees.[area]', 'Area', 'COLUMN';

EXEC sp_rename 'Employees.[salary]', 'Salary', 'COLUMN';

EXEC sp_rename 'Employees.[star_date]', 'Star_Date', 'COLUMN';

EXEC sp_rename 'Employees.[finish_date]', 'Finish_Date', 'COLUMN';

EXEC sp_rename 'Employees.[promotion_date]', 'Promotion', 'COLUMN';

EXEC sp_rename 'Employees.[type]', 'Type', 'COLUMN';


-- Contar la cantidad de filas (22.223) y cantidad de valores distintos para saber si hay duplicados (22.214)
SELECT COUNT(*)
FROM Employees;

SELECT COUNT(DISTINCT Id)
FROM Employees;

-- Identidicar cuales son los id duplicados y cuantas veces se repiten
SELECT Id,
COUNT(*) AS Cantidad_duplicados
FROM Employees
GROUP BY Id
HAVING COUNT (*)>1;

-- Subconsulta para contar el total de duplicados usando la consulta del item anterior
SELECT COUNT(*) AS Cantidad_duplicados
FROM( 
	SELECT Id,
	COUNT(*) AS Cantidad_duplicados
	FROM Employees
	GROUP BY Id
	HAVING COUNT (*)>1
) AS Subconsulta;


-- Renombrar la tabla
EXEC sp_rename 'Employees', 'EmployeesConDuplicados'

-- Selecciona todos los valores unicos de la tabla con duplicados y crea una tabla temporal con dichos valores
SELECT DISTINCT * INTO #Temp_Limpieza FROM EmployeesConDuplicados;

SELECT * FROM #Temp_Limpieza;

-- Se crea la tabla Limpieza seleccionando todos los valores de la tabla temporal
SELECT * INTO Employees FROM #Temp_Limpieza;

-- VER TABLA 
SELECT * FROM Employees;


-- Se analizan los nombres y apellidos que tienen espacio adelante y atras
SELECT Name FROM Employees
WHERE LEN(Name) - LEN(TRIM(Name)) > 0;

SELECT Last_Name FROM Employees
WHERE LEN(Last_Name) - LEN(TRIM(Last_Name)) > 0;

-- Antes de hacer la correccion de los nombres, verificar si la sintaxis esta bien
SELECT
Name,
TRIM(Name) AS Name
FROM Employees
WHERE LEN(Name) - LEN(TRIM(Name)) > 0;

SELECT
Last_Name,
TRIM(Last_Name) AS Last_Name
FROM Employees
WHERE LEN(Last_Name) - LEN(TRIM(Last_Name)) > 0;

-- Una vez que vimos que la sintaxis funciona, corregimos los datos de nombre y apellido. 
UPDATE Employees SET Name = TRIM(Name)
WHERE LEN(Name) - LEN(TRIM(Name)) > 0;

UPDATE Employees SET Last_Name = TRIM(Last_Name)
WHERE LEN(Last_Name) - LEN(TRIM(Last_Name)) > 0;

-- Si tenemos varios espacios entre palabras.
SELECT Area 
FROM Employees
WHERE PATINDEX('%  %', Area) > 0;

-- Cambiar los datos de la columna Type.
SELECT Type,
    CASE 
        WHEN Type = '1' THEN 'Remote'
        WHEN Type = '0' THEN 'Hybrid'
        ELSE 'Otro'
    END AS Ejemplo
FROM Employees;

UPDATE Employees SET Type = CASE 
        WHEN Type = '1' THEN 'Remote'
        WHEN Type = '0' THEN 'Hybrid'
        ELSE 'Otro'
    END;

-- Cambiar los datos de la columna Gender. 
SELECT Gender,
    CASE 
        WHEN Gender = 'hombre' THEN 'male'
        WHEN Gender = 'mujer' THEN 'female'
        ELSE 'Other'
    END AS Ejemplo
FROM Employees;

UPDATE Employees SET Gender =
	CASE 
        WHEN Gender ='hombre' THEN 'male'
        WHEN Gender = 'mujer' THEN 'female'
        ELSE 'Other'
    END;


-- La columna de salario esta en formato varchar y tenemos que pasarla a decimal.
SELECT Salary, 
	TRIM(REPLACE(REPLACE(Salary,'$', ''), ',','')) AS Salary_Update
FROM Employees;

UPDATE Employees SET Salary = TRIM(REPLACE(REPLACE(Salary,'$', ''), ',',''));


-- Cambiar el tipo de dato de Salary, varchar a Decimal. 
select * FROM Employees  
WHERE TRY_CAST(Salary AS DECIMAL(10,2)) IS NULL AND Salary IS NOT NULL;

ALTER TABLE Employees
ALTER COLUMN Salary int;


--Cambiar el tipo de dato, de varchar a date de la columna de star date
ALTER TABLE Employees  
ALTER COLUMN Star_Date date;

EXEC sp_help Employees;


-- Tanto la columna de Birth_Date y Finish_Date tiene varias fechas con formatos diferentes, por lo tanto tenemos que corregir dichos datos para poder pasar de varchar a date
SELECT Birth_Date
FROM Employees
WHERE 
    TRY_CONVERT(DATE, Birth_Date, 103) IS NULL 
    AND TRY_CONVERT(DATE, Birth_Date, 101) IS NULL;

UPDATE Employees
SET Birth_Date = 
    CASE 
        WHEN TRY_CONVERT(DATE, Birth_Date, 103) IS NOT NULL 
             THEN FORMAT(TRY_CONVERT(DATE, Birth_Date, 103), 'yyyy-MM-dd') 
        WHEN TRY_CONVERT(DATE, Birth_Date, 101) IS NOT NULL 
             THEN FORMAT(TRY_CONVERT(DATE, Birth_Date, 101), 'yyyy-MM-dd') 
        ELSE NULL 
    END;

-- Tranformo el tipo de dato de Birth_Date de varchar a date
ALTER TABLE Employees  
ALTER COLUMN Birth_Date DATE;


-- Contar la cantidad de filas que tienen un espacio y no lo toma como nulo: 18282
SELECT 
COUNT(Finish_Date)
FROM Employees 
WHERE Finish_Date = '';


-- Contar las cantidad de filas que tienen fechas: 3932
SELECT 
COUNT(*) AS Cantidad
FROM Employees
WHERE Finish_Date IS NOT NULL AND Finish_Date <> '';

-- Pasar todos los registros que tienen espacio vacio a null. 
UPDATE Employees
SET Finish_Date = NULL
WHERE LTRIM(RTRIM(Finish_Date)) = '';

-- Verificar el cambio de formato de fecha.
SELECT Finish_Date, TRY_CONVERT(DATE, LEFT(Finish_Date, 10), 120) AS New_Date
FROM Employees; -- como funciona bien ahora hacemos la actualizacion  del dato

UPDATE Employees
SET Finish_Date = TRY_CONVERT(DATE, LEFT(Finish_Date, 10), 120);


---------------------------------------------
SELECT * FROM Employees;
---------------------------------------------


-- Contar la cantidad de filas que hay fecha.
SELECT COUNT(*) AS fechas
FROM Employees
WHERE ISDATE(Promotion) = 1;

SELECT *
FROM Employees
WHERE ISDATE(Promotion) = 1;

-- Cambiar el formato de la fecha. Primero verificamos si lo hicimos bien 
SELECT Promotion AS FechaOriginal, 
       CONVERT(DATE, Promotion, 107) AS FechaConvertida
FROM Employees
WHERE ISDATE(Promotion) = 1; 

UPDATE Employees
SET Promotion = CONVERT(DATE, Promotion, 107)
WHERE ISDATE(Promotion) = 1;


-- Cambiar las filas vacias a nulas
SELECT 
id,
promotion,
NULLIF(Promotion, '') AS PROMOTION
FROM Employees;

 UPDATE Employees
 SET Promotion = NULL
 WHERE Promotion = ' ';

 -- Ver las columnas que tienen fecha en la columna Promotion
 SELECT
 id,
 Promotion
 FROM Employees
 WHERE ISDATE(Promotion) = 1;

 
-- Calcular la edad de los empleados
ALTER TABLE Employees  
ADD Age INT;

SELECT
Id,
Birth_Date,
DATEDIFF(year, Birth_Date, GETDATE()) AS Edad
FROM Employees;

UPDATE Employees
SET Age = DATEDIFF(year, Birth_Date, GETDATE());


-- Calcular los años trabajados
ALTER TABLE Limpieza
ADD Antigüedad int;

SELECT 
Name, 
Star_Date,
DATEDIFF(YEAR, Star_Date, GETDATE()) AS Antiguedad
FROM Employees;

UPDATE Employees
SET Antigüedad = DATEDIFF(YEAR, Star_Date, GETDATE());

