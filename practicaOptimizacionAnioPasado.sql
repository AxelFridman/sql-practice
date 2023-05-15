SELECT *
FROM Purchasing.ShipMethod
ORDER BY Name

SELECT *
FROM Purchasing.ShipMethod
WHERE Name IS NOT null

--En este caso La segunda query es mucho más rápida. 
--Para empezar el atributo Name es no nulo, por lo que el pedido en la segunda query de que el atributo sea nulo es innecesario y 
--automáticamente optimizado por el motor ya que no modifica el output de la consulta.

-- Por otro lado la primer consulta requiere que los atributos están ordenados por el campo Name 
-- (recordemos que ShipMethod tiene su índice cluster ordenado por ShipMethodID) por lo que usa el índice non clustered ordenado por Name y
-- con eso consigue ordenarlo rápidamente. Como ese índice solo tiene dicho atributo de orden y las claves para buscar en el índice cluster, 
-- utiliza Key Lookup en el Cluster para obtener el resto de atributos, y unirlos con Nested Loops para devolver la solución final Ordenada.

SELECT CardType
FROM Sales.CreditCard
GROUP BY CardType

SELECT CardNumber
FROM Sales.CreditCard
GROUP BY CardNumber

-- Es claro ver que a pesar que la primera query tiene pocos outputs, debido a que no hay un índice para dicho atributo, 
-- el motor optimiza de la mejor forma que tiene, viéndose obligado a usar el único índice que tiene CardType (el cluster) a pesar de su mayor tamaño. 
-- Procede a un Hash Match donde matchea los outputs según su card type para responder a la query.

-- Esto resulta muy costoso simplemente por verse obligado a usar el índice Cluster que es muy grande con datos que no estamos usando para esta query.

-- En la segunda query, si bien su output es mucho mayor, existe un índice ordenado por dicho campo (AK_CreditCard_CardNumber),
-- el cual simplemente extrayendo las entradas del índice se obtiene la solución buscada.
--  Por tanto el motor decide escanear dicho índice retornando sus entradas. 
-- Como dicho índice es más chico (tiene menos columnas), el tiempo de ejecución es bastante menor.

SELECT *
FROM sales.SalesOrderDetail
WHERE UnitPrice > ALL (
  SELECT UnitPrice 

  FROM Sales.SalesOrderDetail 

  WHERE OrderQty >12

)

SELECT *
FROM sales.SalesOrderDetail
WHERE UnitPrice > (
SELECT MAX(UnitPrice)
FROM Sales.SalesOrderDetail
WHERE OrderQty >12
)

-- Si bien ambas queries dan la misma respuesta (en la primera pide los que son mayores a todos los que cumplen tener más de 12 ventas, en la segunda se pide que sea solo mayor al máximo de todos ellos, claramente es lo mismo pero el motor no se da cuenta de esto), la segunda usa una propiedad que el motor no logra inferir y que logra aumentar el performance considerablemente.
-- En la primera debe guardar en una tabla temporal en memoria todos los UnitPrice lo que perjudica enormemente el performance, 
-- pero con el objetivo de optimizar el Nested Loop donde va a tener que comparar la tabla con todos los UnitPrice que cumplen, la propiedad. 
--El resultado es que el Nested Loop en ambos casos tiene el mismo costo,
-- pero en la primer query conseguir guardar todos los UnitPrice que cumplen en una tabla en memoria perjudica enormemente el performance mientras que en la primera solo
--  se hace una función de agregación de poco costo,
-- y se compara con dicho valor en un nested loop más chico.

SELECT AddressID, City, StateProvinceID, ModifiedDate
FROM Person.Address
WHERE StateProvinceID = 32

SELECT AddressID, City, StateProvinceID, ModifiedDate
FROM Person.Address
WHERE StateProvinceID = 20

El motor tiene estadísticas de ambas respuestas, y estima que para la primera query solo va a encontrar un resultado (osea una cantidad que no es perjudicial para hacer key lookups), esto quiere decir que buscar en un índice por estado y posteriormente hacer un key look up le es más barato.

Esto no vuelve a suceder con el estado 20. Es así porque el motor estima que recibirá más de 300 respuestas para la segunda query. Si bien hacer key lookups son mucho más baratos que hacer un completo scan del índice clustered, para este caso en particular solo es 40 veces más rápido, y la mitad de dicho costo corresponde al key look up, por lo que podemos suponer que en este caso en particular, a partir de los 80 key lookups es preferible hacer un scan antes de hacer tantos key lookups (y particularmente hubiera terminado haciendo 300 key look ups, por lo que por estadísticas decidió el otro camino).

SELECT COUNT(UnitPrice)
FROM sales.SalesOrderDetail

SELECT SUM(UnitPrice)
FROM sales.SalesOrderDetail

UnitPrice es un atributo no nulo. Esto quiere decir que para la primera query la consulta es equivalente a devolver el número de filas que tiene la tabla. Debido a esto, cualquier índice que al menos sea completo (tenga todas las filas) va a ser suficiente para resolver la consulta. En particular el motor toma el más chico ya que al tener menos columnas, recorrerlo le será más rápido que por ejemplo si recorriera el cluster index. En particular esto hace que la respuesta se devuelva en un tercio del tiempo.
 En la segunda query, lo que hicimos antes no es posible, porque requerimos sumar el valor exacto de cada uno de los campos. Para peor, no existe ningún indice en SalesOrderDetail que contenga al precio más que el cluster, por lo que se ve obligado a tomar el índice más grande. Esto hace que la respuesta sea algo más lenta que en el anterior caso, pero es necesario para conseguir una respuesta correcta.

SELECT *
FROM Person.Person
WHERE LastName Like 'Duffy%'

SELECT *
FROM Person.Person
WHERE LastName Like '%Duffy'

Si bien ambas consultas son similares, recorren el mismo índice, y ejecutan un plan con algoritmos muy similares (ambos hacen Nested Loops y requieren hacer Key Look Up para recuperar el resto de campos de la tabla y cuestan lo mismo), mientras que la primera query es SARGeable, la segunda no lo es debido a que 'Duffy%' se puede buscar alfabéticamente (las palabras que sigan ese criterio estarían juntas en el índice), '%Duffy' no (las palabras que cumplen el segundo criterio podrían encontrarse en cualquier parte del índice). Esto obliga al motor en el segundo caso a hacer una búsqueda total del índice haciendo un scan completo, de palabras que cumplan, costoso. En cambio el DBMS puede en el primer caso hacer un seek sencillo que usa la estructura del índice y llega a las hojas que cumplan hasta llegar a la última coincidencia, las cuales se encontrarán todas juntas en bloques de página contiguos.