-- 1 Obtener la cantidad de Invoices por track, deberá responder el identificador de track, el nombre y la cantidad de Invoices donde participa.
SELECT t2.TrackId, t2.Name, aux1.CantidadInvoices
FROM Track t2 
LEFT JOIN
(SELECT t.TrackId, COUNT( invl.InvoiceId) as CantidadInvoices
FROM Track T
LEFT JOIN InvoiceLine invl on invl.TrackId = t.TrackId
GROUP BY t.TrackId) as aux1
on aux1.TrackId = t2.TrackId
ORDER BY t2.TrackId

-- La siguiente query muestra que hay muchas canciones distitnas con el mismo nombre, luego no se podria haber agrupado por nombre ademas de id, se debia hacer otro join.
SELECT *
FROM Track t1 
INNER JOIN Track t2 on t2.TrackId < t1.TrackId AND t2.Name = t1.Name

-- 2 Listar todos los datos de los tracks cuya duración sea mayor al promedio de la duración de los tracks de Rock.

SELECT * 
FROM Track t2
WHERE t2.Milliseconds >
(SELECT AVG(Milliseconds) as DuracionPromedioRock
FROM Track T
INNER JOIN Genre g on g.GenreId = T.GenreId
WHERE g.Name = 'Rock')

-- 3 Obtener el nombre y apellido de los clientes que son atendidos por los empleados que atienden a la mayor cantidad de clientes. La relación entre empleado y cliente se da por la clave foránea en cliente SupportRepId.
SELECT cus3.FirstName, cus3.LastName
FROM Customer cus3
INNER JOIN 
(SELECT aux1.empleadosId, aux1.CantidadClientes  FROM
(SELECT SupportRepId as empleadosId, COUNT(CustomerId) as CantidadClientes
FROM Customer
GROUP BY SupportRepId) AS aux1
        WHERE 
        aux1.CantidadClientes = 
            (SELECT MAX(aux1.CantidadClientes) 
            FROM (SELECT SupportRepId as empleadosId, COUNT(CustomerId) as CantidadClientes
            FROM Customer
            GROUP BY SupportRepId) AS aux1 )) as empleadosMasDemandado
on empleadosMasDemandado.empleadosId = cus3.SupportRepId

-- 4 Listar los tracks más vendidos. Es decir aquellos tales que no hay un track que tenga más ventas.
SELECT * FROM
(SELECT t.TrackId, COUNT(InvoiceId) as cantVentas 
FROM InvoiceLine invl 
INNER JOIN Track t on t.TrackId = invl.TrackId
GROUP BY t.TrackId) as trackventas
WHERE trackventas.cantVentas >= 

(SELECT MAX(ventas.cantVentas) as maximaCantidad FROM
(SELECT t.TrackId, COUNT(InvoiceId) as cantVentas 
FROM InvoiceLine invl 
INNER JOIN Track t on t.TrackId = invl.TrackId
GROUP BY t.TrackId) as ventas)

-- 5 Realizar una consulta corrrelacionada que me devuelva las invoices (ID, Fecha y BillingAddress) tales que en sus ítems (InvoiceLine) no haya ningún precio unitario de 0.99
SELECT inv2.InvoiceId, inv2.InvoiceDate, inv2.BillingAddress
FROM Invoice inv2
WHERE inv2.InvoiceId NOT IN 
(SELECT DISTINCT inv.InvoiceId
FROM InvoiceLine invl 
INNER JOIN Invoice inv on inv.InvoiceId = INVL.InvoiceId
WHERE invl.UnitPrice = 0.99)

-- 6 Realizar una consulta que devuelva todos los empleados contratados después que Park Margaret. La fecha de contratación es HireDate.
SELECT * 
FROM Employee emp2
WHERE emp2.HireDate >
(SELECT HireDate
FROM Employee emp
WHERE emp.LastName = 'Park' AND emp.FirstName = 'Margaret')
