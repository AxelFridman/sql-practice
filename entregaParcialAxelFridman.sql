--1. Cuántos empleados fueron contratados por año (HireDate es la
--fecha de contratación).
SELECT COUNT(EmployeeId) as CantidadEmpleadosContratados, YEAR(HireDate) as anioDeContratacion
FROM Employee
GROUP BY YEAR(HireDate)

--2. Escriba una consulta que devuelva el nombre del artista y el
--número total de canciones de los grupos de rock.
SELECT COUNT(t.TrackId) as cantidadCancionesRock, art.Name
FROM Track t 
INNER JOIN Album alb on alb.AlbumId = t.AlbumId
INNER JOIN Artist art on art.ArtistId = alb.ArtistId
INNER JOIN Genre g on g.GenreId = t.GenreId
WHERE g.Name = 'Rock'
GROUP BY art.ArtistId, Art.Name

-- En este caso agrupe por nombre de artista y no por su id ya que sino 
-- estaba forzado a hacer un join mas y como muestro aca abajo NO hay 2 artistas distintos con 
-- el mismo nombre

-- DEMOSTRACION ARTISTAS TODOS DISTINTOS NOMBRE
SELECT *
FROM 
Artist art1
INNER JOIN Artist art2 on Art1.Name = art2.Name AND art1.ArtistId != art2.ArtistId

--3. Cuales son los artistas que han ganado más de $100 en total.
SELECT art2.Name, art2.ArtistId, gananciaArtista.Ganancia
FROM
(SELECT SUM(invl.UnitPrice * invl.Quantity) as Ganancia, art.ArtistId
FROM InvoiceLine invl
INNER JOIN Track t on invl.TrackId = t.TrackId
INNER JOIN Album alb on alb.AlbumId = t.AlbumId
INNER JOIN Artist art on art.ArtistId = alb.ArtistId
GROUP BY art.ArtistId) as gananciaArtista
INNER JOIN Artist art2 on art2.ArtistId = gananciaArtista.ArtistId
WHERE gananciaArtista.Ganancia > 100


--4. Calcular para cada artista, la duración en segundos de su canción
--más extensa junto con la diferencia contra su canción más corta

SELECT art.ArtistId, art.Name, MAX(Milliseconds)/1000 as cancionMasLarga, MIN(Milliseconds)/1000 as cancionMasCorta, (MAX(Milliseconds) - MIN(Milliseconds))/1000 as DiferenciaLongitudSeg
FROM Track t 
INNER JOIN Album alb on alb.AlbumId = t.AlbumId
INNER JOIN Artist art on art.ArtistId = alb.ArtistId
GROUP BY art.ArtistId, art.Name

--5. Cuánto gastó cada cliente en cada género.

SELECT  inv.CustomerId, g.GenreId, SUM(invl.UnitPrice*Quantity) as GastosCantidadPorCosto
FROM InvoiceLine invl
INNER JOIN Invoice inv on inv.InvoiceId = invl.InvoiceId
INNER JOIN Track t on t.TrackId = invl.TrackId
INNER JOIN Genre g on t.GenreId = g.GenreId
GROUP BY inv.CustomerId, g.GenreId

--6. Obtener las playlists que contengan a los tracks de mayor duración
SELECT pl.PlaylistId, pl.Name
FROM Track t1
INNER JOIN PlaylistTrack plt on plt.TrackId = t1.TrackId
INNER JOIN Playlist pl on pl.PlaylistId = plt.PlaylistId
WHERE t1.Milliseconds >= 
    (SELECT MAX(t0.Milliseconds)
    FROM Track t0)
-- Responde 2 playlist id que contienen al track mas largo (en este caso es solo 1 el track que cumple el where) 
-- pero las playlist tienen el mismo nombre aunque distinto id