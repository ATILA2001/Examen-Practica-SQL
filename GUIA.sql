
--1. Vistas
CREATE VIEW NombreVista AS
SELECT columnas
FROM tablas
WHERE condiciones;

--2. Procedimientos Almacenados
CREATE PROCEDURE NombreProcedimiento
(@Parametro1 Tipo, @Parametro2 Tipo)
AS
BEGIN
    -- Sentencias SQL
END;

--3. Transacciones
BEGIN TRANSACTION;

UPDATE Cuentas SET Saldo = Saldo - 100 WHERE ID = 1;
INSERT INTO RegistroTransacciones (IDCuenta, Monto, Fecha) VALUES (1, -100, GETDATE());

COMMIT;

--4. Triggers
CREATE TRIGGER NombreTrigger
ON NombreTabla
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Lógica del trigger
END;
