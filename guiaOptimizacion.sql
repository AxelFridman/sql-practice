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
    and object_name(cols.object_id) LIKE 'Person'
    order by object_name(cols.object_id), ind.name;

SELECT TABLE_NAME, COLUMN_NAME, IS_NULLABLE, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'Person';


-- 0.1. Explique el funcionamiento de las siguientes consultas
-- y por qu´e los planes de ejecuci´on
-- son diferentes.

SELECT P.Name , P.ProductNumber
FROM Production.Product P
WHERE ProductNumber ='EC-R098'

-- En la primer query hace un index seek entre los product numbers que 
-- tienen indice unclustered en producto y una vez que tiene el
--  product number debe buscar con keylookup en el indice clustered 
-- ya que en la tabla del indice unclustered de product number no estaba 
-- toda la informacion del registro. En definitiva hace 2 busquedas, la 
-- primera para buscar el product number EC-R098 y la segunda para dar con el
-- product name que tiene ese number.

SELECT P.ProductID , P.ProductNumber
FROM Production.Product P
WHERE ProductNumber ='EC-R098'

-- En el indice unclustered ya esta ambas informaciones que me piden. enronces solo con ese indice basta

--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------

--0.2. Estas dos consultas son similares sin embargo los planes son diferentes.
-- Explique lo que esta ocurriendo



SELECT SalesOrderID , SalesOrderDetailID
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = 58950
-- Notando que devuelve 28 SalesOrderDetailID distintos en la query 1 mientras que solo 1 en la query 2.
-- Eso es porque cada salesOrderId puede tener muchos SalesOrderDetailID y cada SalesOrderDetailID tiene unico salesOrderId.
-- decide hacer un clustered index seek por salesOrderid. 

SELECT SalesOrderID, SalesOrderDetailID
FROM Sales.SalesOrderDetail
WHERE SalesOrderDetailID = 68531
-- como no esta ordenedo por esa clave primaria en ese orden. (salesOrderid, salesorderdetailid) 
-- no puede hacer lo mismo que en la query 1
-- entonces tiene que hacer un scan usando el indice unclustered no unico. que tiene salesorderdetailid, salesorderid y productid.
-- es mas barato porque si bien productid no nos interesa, la alternativa seria
-- el clustered tiene el scan mas caro porque trae todas las columnas del registro, por eso es usa el unclustered


-- 0.3. Mire detalladamente estas consultas y explique los planes de ejecuci´on

SELECT SalesOrderID, SalesOrderDetailID
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = 43683 AND SalesOrderDetailID = 240
-- Hace un seek en el clustered index ya que puede ir recorriendo la estructura por el orden primero 
-- hasta que sales order id sea 43683 y despues filtrando que salesorderdetailid sea 240. obviamente esto es rapido porque es 
-- un solo seek. En contraste la query 2 tiene un OR entonces ya no sabe exactamente en que 
-- lugar de la estructura puede estar el registro deseado entonces debe recurrir a escanearla.
-- decide escanear por el indice unclustered ya que tiene menos columnas y es mas rapido

SELECT SalesOrderID, SalesOrderDetailID
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = 43683 OR SalesOrderDetailID = 240

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

-- 0.4. Compare los planes de ejecuci´on de las siguientes tres consultas.
-- Explique que hace cada uno y por qu´e se eligen mecanismos de junta diferentes.

SELECT ProductID, PV.BusinessEntityID, Name
FROM Purchasing.ProductVendor PPV 
JOIN Purchasing.Vendor PV ON (PPV.BusinessEntityID =PV.BusinessEntityID)
-- merge join porque como ambas tablas tienen a buisnessentitiyid ordenado pueden unirse recorriendo solo ese idnice. 
-- podemos ver que como en vendor necesitamos name que no esta en ningun otro indice usamos el clustered index scan
-- mientras que en productVendor como existe el indice unclustered que contiene a buisnessentitiyId y es mas barato porque
-- tiene menos columnas/registros usa ese. finalmente como ambos estan ordenados por buisness entitiy id podemos usar un merge
-- join para tener las tablas unidas.

SELECT ProductID, PV.BusinessEntityID, Name
FROM Purchasing.ProductVendor PPV 
JOIN Purchasing.Vendor PV ON (PPV.BusinessEntityID =PV.BusinessEntityID)
WHERE StandardPrice > $10
-- Hace un hash match en vez de merge join, posiblemente porque estima que tendra mas registros que 
-- cumplan esas condiciones de standar price y por lo tanto es mas barato que hacer un nested loop join. 
-- y ya no se puede hacer un merge porque hay que filtrar la condicion. 
-- esto lo podemos ver empiricamente porque si cambiamos el valor del where por 0 hace un innerjoin ya que son 
-- todos y no hay que filtrarlos. Mientras que si cambiamos el valor por 300 hace un nested loop ya que estima
-- que son pocos registros y consecuentemente no vale la pena crear la estructura del hash.
-- y ahora cambia que hacemos un clustered index scan en product vendor (en vez de unclustered como la anterior)
-- porque necesitamos la informacion del standarPrice que solo se encuentra en el indice clustered para poder filtrar

SELECT ProductID, PV.BusinessEntityID, Name
FROM Purchasing.ProductVendor PPV JOIN Purchasing.Vendor PV
ON (PPV.BusinessEntityID =PV.BusinessEntityID)
WHERE StandardPrice > $10 AND Name LIKE N'F%'
-- standarprice viene de productvendor y name de vendor. y name no tiene ningun indice en vendor.
-- tampoco tiene otro indice standar price, asi que debo usar el clustered tambien.
-- luego hare un indice scan clustered en ambos porque no tengo opcion, filtrando los que cumplan condiciones.
-- luego estima que tiene pocos registros entonces hace un inner join en vez de hash.
-- no podria haber hecho un merge join ya que no tengo todos los indices de ambos (el where es no nulo).
-- De hecho en la query 2 tenia 400 registros mientras que en la 3 solo por agregar la restriccion del que empieze
-- con f ahora solo me quedan 8 registros.


-- 0.5. Compare los planes de ejecuci´on de las siguientes consultas. Explique que hace cada uno
-- y en que se basa la elecci´on del optimizador
SELECT P.Name, PSC.Name SubCatrom
FROM Production.Product P
JOIN Production.ProductSubcategory PSC
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
-- de product tengo el indice clustered que me da todo ya que no tengo otra forma de conseguir productsubcategoryid 
-- en product. Mientras que en productsubcategory puedo usar el indice unclustered scan que tiene su name y su id. y es 
-- mas barato porque tiene menos columnas. Ahora como no necesito ordenarlos y estimo que son muchos hago un hash match.
-- y no hace un merge join porque no tengo ordenados el productsubcategoryid en ninguno de los 2.

SELECT P.Name, PSC.Name SubCatrom
FROM Production.Product P
JOIN Production.ProductSubcategory PSC
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
ORDER BY psc.ProductSubcategoryID
-- ahora como los quiero ordenados puedo aprovechar para ya ordenar sus partes antes de unirla. el merge join
-- ya me lo devuelve ordenado. y ahora ademas se modifica que como yo quiero el productsubcategoryid ordenado
-- puedo en vez de usar el indice unclustered que me da name que no me lo da ordenado puedo usar el clustered 
-- y hacer un scan ahi sobre la tabla de product subcategory.
-- ademas como previo al merge sort ambas partes deben estar ordenadas el resultado del scan en product debe ordenarse.
-- esto seria mas barato que agarrar y unirlos como en query 1 y posteriormente ordenarlo.

--0.6. Compare las siguientes dos consultas y explique la diferencia de planes

SELECT count(NameStyle) FROM Person.Person
-- no tengo ninguna en ningun indice mas que el clustered, sin embargo title es nulleable mientras que
-- namestyle es no nulleable, luego como namestyle es no nulleable podria en vez de contar el indice
-- unclustered mas chico que tenga que sea no nulleable y contar la cantidad ya que eso equivale a contar
-- la cantidad del id de persona que es buisnessentityid. en este caso usa el idncie unclstered de rowguid

SELECT count(Title) FROM Person.Person
-- como es nulleable no sabe cunato realmente hay (no cuenta nulos) entonces debe hacer un clustered index scan
-- ya que es la unica forma de recuperar la informacion del title

-- 0.7. Analice los planes de las siguientes consultas4

SELECT jc.Resume FROM HumanResources.JobCandidate jc
INNER JOIN HumanResources.Employee e on jc.BusinessEntityID =e.BusinessEntityID
ORDER BY e.BusinessEntityID,jc.JobCandidateID
-- La unica diferencia es lo que pide en el select, hace un clustered index scan en jobcandidate porque no
-- hay otro indice para resumen, entonces etsamos forzados a usar el clustered. ahora que usamos el clustered tenemos 
-- tambien el buisnessentityid y como lo queremos ordenado por buisness entitiy id ordenamos ese scan.
-- luego como son pocos (en este caso 2) aquellos buisnessentityid puedo hacer un seek en vez de scanear toda la 
-- tabla de employee. y eso sera mas barato. para hacer el seek uso el clustered.

SELECT JobCandidateID FROM HumanResources.JobCandidate jc
INNER JOIN HumanResources.Employee e on jc.BusinessEntityID =e.BusinessEntityID
ORDER BY e.BusinessEntityID,jc.JobCandidateID
-- indice unclustered para tener buisnessentityid porque es mas barato que el unclustered.
-- como son pocos es mas barato unir con un nested loop, ya que crear la estructura del hash seria caro. 
-- y para obtener el jobcandidateId hago un seek 
-- no hace sort pq ya esta ordenado
