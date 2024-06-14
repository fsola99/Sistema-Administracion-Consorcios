SELECT id_consorcio,expensas_total FROM Consorcios;
CALL ActualizarExpensasConsorcio(5,1000000);
SELECT id_consorcio,expensas_total FROM Consorcios;
SELECT * FROM Propietarios