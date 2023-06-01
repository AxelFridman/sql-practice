-- Auxiliar
SELECT 
    object_name(cols.object_id) tabla
    ,cols.name columna
    ,ind.name indice
    ,ind.type_desc tipo
    ,ind.is_unique 
    FROM 
    sys.columns cols, sys.indexes ind , sys.index_columns ind_cols
    where 
    cols.object_id = ind.object_id
    and cols.object_id = ind_cols.object_id
    and cols.column_id = ind_cols.column_id
    and ind.index_id = ind_cols.index_id
    and object_name(cols.object_id) LIKE 'ProductInventory'
    order by object_name(cols.object_id), ind.name;

SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'ProductInventory';

--1. Explique las diferencias entre los planes de ejecuci´on de las siguientes consultas:
SELECT Name FROM Production.Culture;

SELECT Name,ModifiedDate FROM Production.Culture;
-- En ambas se pide el name de la misma tabla, pero en la segunda ademas se pide el ModifiedDate.
-- Ahora en la tabla culture tenes el cultureid, name y modifiedDate pero ademas del indice clustered
-- solo tenes un indice unclustered con nombre (y ningun otro indice con modified date). 
-- con lo cual en el primer caso puede hacer un index scan por el nombre utilizando el indice unclustered 
-- de nombre (que es mas barato que el clustered porque tiene menos registros). Mientras que en el segundo 
-- caso como tambien queres modified date si o si tenes que ir a buscarlo al indice clustered. es scan para 
-- tener todos.




-- 2. Compare y explique los planes de las siguientes consultas:
SELECT PhoneNumber, PhoneNumberTypeID
FROM Person.PersonPhone WHERE PhoneNumberTypeID =3

SELECT PhoneNumber, ModifiedDate
FROM Person.PersonPhone WHERE PhoneNumberTypeID =3

-- en el primer caso utiliza el indice unclustered ya que ese indice contiene toda la informacion que 
-- se pide, el  PhoneNumber y PhoneNumberTypeID. y es mas barato que utlizar el clustered que contiene
-- mas registros como el modifieddate. en el segundo caso modified date no es parte del indice
--  unclustered con lo cual debo 
-- usar el clustered. No puedo usar el PhoneNumberTypeID =3 porque la estructura no esta ordenada 
-- en ese orden sino en el orden (Buisnessentitiyid, PhoneNumber, phonenumbertypeid ) con lo cual el 
-- hecho de que PhoneNumberTypeID =3 podria estar en cualquier lugar de la estructura, debo hacer scan.

-- 3. Explique por qu´e se usan planes distintos en las dos consultas siguientes:
SELECT Shelf
FROM Production.ProductInventory ORDER BY Shelf, ProductID

SELECT Shelf
FROM Production.ProductInventory ORDER BY ProductID, Shelf

-- En la tabla productinventory no hay indices unclustered. Parecen dar mismos resultados.
-- ademas en la tabla no hay columnas nulleables.
-- uno pensaria que como esta ordenado por productId y luego por locationId en el indice clustered
-- que la segunda query deberia ser mas rapida ya que podria utilizar el ordenamiento del indice clustered
-- y luego ordenar por shelf. mientras que en la query 1 como el primer criterio es shelf ya no podes usar el
-- previo ordenamiento que te da el clustered index scan por ProductId y Locationid. Termina haciendo
-- lo mismo para ambas porque considera que de todas formas un poco vas a ordenar a ambas, asi que no aprovecha
-- el hecho de que al hacer el clustered index scan en la segunda query ya tenes la parte del ordenamiento por productid
-- resuelta (y solo te va quedar ordenar las shelf en cada productid)  


-- 4. Explique el uso de ´ındices en las siguientes consultas:

Select AddressLine1, AddressLine2, City from Person.Address where
AddressLine1 like '1%'
-- La query 1 utiliza el indice unclustered ordenado por addess line 1 porque al
-- pedirle en el like que empieze con caracter 1 el addresline1 eso nos permite hacer un
--  SEEK en el indice, y si usaramos otro indice ordenado por otro criterio no podriamos.
-- ademas trae a stateprovinceid y postalcode que no son necesarios pero es de todas formas el mas barato.

-- si hubiera (y no lo hay) un indice unclustered que solo contenga a las 3 columnas pedidas ordenadas por 
-- address line 1 se usaria ese. ya que no traeria a state y postalcode innecesariamente.

Select AddressLine1, AddressLine2, City from Person.Address where
AddressLine1 NOT like '1%'
-- es similar al anterior y usa el mismo indice pero aca como le estamos pidiendo que NO empieze con 1 entonces 
-- no sabe en que parte de la estructura de la base esta, solo sabe donde no buscar (y no donde si). entonces 
-- tiene que hacer un scan por todo el indice. usa el unclustered y no el clustered porque tiene menos registros 
-- y asi recorrerlo es mas barato.

Select AddressLine1, AddressLine2, City, ModifiedDate from Person.Address
where AddressLine1 like '1%'

-- notese que es identico a el primero PERO ahora tambien nos piden modified date. nos encantaria usar el
-- indice unclustered para poder tener menos registros que el clustered y ademas para tenerlo ordenado por
-- addressline1 y asi agararnos rapido con un seek a los que empiezen con 1 pero no podemos hacer eso.
-- no podemos hacer eso, que seria ideal, porque modified date NO esta en ese indice unclustered con lo cual 
-- estamos obligados a usar el indice clustered que es el indice mas chico que los contiene a todos. 
-- como no sabemos en que parte del clustered estan los que su addressline1 arranca en 1 tenemos 
-- que hacer un scan. 

-- 5. Explique por qu´e las siguientes consultas tienen planes diferentes:
select ShipDate, sc.AccountNumber 
from Sales.SalesOrderHeader sh
inner join Sales.Customer sc on sh.CustomerID =sc.CustomerID;

-- en la primer query realiza scan en un indice unclustered de territoryId (por performance segun sus estadisticas)
--  y desde eso deduce a partir de cuentas el accountNumber, 
-- ahora que de de customer tiene accountNumber y customerID.
-- Esta bueno porque es rapido al no tener que usar el clustered pero lo malo es que al usar el unclustered ya
-- no los tenes ordenados por customerId, con lo cual a la hora de joinear no podrias hacer un mergesort como en 
-- la otra query de abajo. 
-- Mientras tanto por el lado de las salesOrder hace un clustered index scan para obtener el customerId y shipdate
-- ya que es el unico indice que contiene a ambas columnas. 
-- ahora que tiene ambos pero no ambos ordenados por customer id hace un hash match para joinearlos porque seria
-- mas barato hacer el hash match que ordenarlos ambos y hacer un mergesort u otra cosa.


select sh.SalesOrderNumber, sc.AccountNumber 
from Sales.SalesOrderHeader sh
inner join Sales.Customer sc on sh.CustomerID =sc.CustomerID;

-- la segunda pide SalesOrderNumber y AccountNumber. como salesordernumber esta presente en el indice unclustered
-- de customerid (que esta ordenado por customer id) es muy provechoso ya que no traigo muchos registros demas 
-- y los tengo ordenados por customer id que es por lo que voy a joinear
-- para customer en esta ocasion si decide usar el clustered que nos los dara la informacion que queremos por parte 
-- de customer que es customeriD Y account number y nos la dara ordenados por customerid.
-- y porque al ya tenerlos ordenados en el otro lado
-- al tener ambos ordenados puede usar un merge join que es barato. y no tengo que inicializar la estructura de memoria
-- para el hash por ejemplo.

--6. Compare las siguientes consultas:

SELECT count(OrderQty) FROM Sales.SalesOrderDetail;

-- order qty es no nulleable pero no esta presente en ningun indice unclustered, entonces como 
-- productId tambien es no nulleable pero si tiene indice unclustered, puedo contar esas y 
-- son equivalentes. para contarlas va por el indice unclustered de productId e ir sumando la 
-- cantidad de productId. va por el indice unclustered ya que esto es mas barato que ir por el clustered 
-- al tener menos registros. luego como la cantidad de productId es igual a la de orderqty devuelvo ese numero.

SELECT sum(OrderQty) FROM Sales.SalesOrderDetail;

-- en el segundo caso no importa que haya la misma cantidad de registros, yo quiero sumarlas, y para sumarlas necesito
-- poder acceder al dato. para acceder al dato de Orderqty si o si necesito el indice clustered. entonces hace
-- un scan ahi y va sumando order qty. es pesado pero no queda otra porque no esta en otro lado.