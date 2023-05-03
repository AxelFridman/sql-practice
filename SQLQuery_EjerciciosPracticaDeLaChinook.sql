-- query 1
SELECT t.Name, g.Name , m.Name FROM 
Track t
JOIN Genre g on g.GenreId = t.GenreId
JOIN MediaType m on m.MediaTypeId = t.MediaTypeId ;

-- query 2
SELECT 
    g.Name
    ,tablaGeneroId.CantidadGenero
from Genre g 
INNER JOIN 

(SELECT GenreId, COUNT(TrackId) as CantidadGenero  FROM
Track
GROUP BY GenreId) as tablaGeneroId

 on g.GenreId = tablaGeneroId.GenreId

-- query 3 version 1 
SELECT Name FROM Artist WHERE ArtistId NOT IN (
SELECT
a.ArtistId
FROM 
Artist a 
INNER JOIN
Album on a.ArtistId = Album.ArtistId)

-- query 3 version 2

-- query 4
--  Genero la respuesta de artista, track

SELECT art.name, tablaIdArtCantTracks.CantidadTracks FROM
Artist as art
INNER JOIN
(SELECT 
    art.ArtistId, 
    COUNT(t.TrackId) AS CantidadTracks
FROM Track t
INNER JOIN Album al on al.AlbumId = t.AlbumId
INNER JOIN Artist art on art.ArtistId = al.ArtistId
GROUP BY art.ArtistID) AS tablaIdArtCantTracks on tablaIdArtCantTracks.ArtistId = art.ArtistId
WHERE CantidadTracks>50
ORDER by CantidadTracks DESC


-- query 5 
-- NUEVO QUERY 5 
SELECT COUNT(DISTINCT AUX1.EmployeeId) as CantidadEmpleadosEnMismaCiudad, cus2.CustomerId FROM
(SELECT cus.CustomerId, emp.EmployeeId, CUS.City FROM --cus.CustomerId, COUNT(DISTINCT emp.City)  
Customer cus
INNER JOIN Employee emp on emp.City = cus.City) AS AUX1
RIGHT JOIN Customer cus2 on AUX1.CustomerId = cus2.CustomerId
GROUP BY cus2.CustomerId

-- query 6 dinero recadudado por cada empleado en cada fecha.
SELECT YEAR(inv.InvoiceDate) AS anio, SUM(inv.Total) as sumaRecaudada, emp.EmployeeId 
FROM Customer cus
INNER JOIN Employee emp on emp.EmployeeId = cus.SupportRepId
INNER JOIN Invoice inv on inv.CustomerId = cus.CustomerId
GROUP BY YEAR(inv.InvoiceDate), emp.EmployeeId



-- query 7 todas las pistas de audio que sean mayor al promedio de duracion de pistas de audio
SELECT *
FROM Track t2
WHERE t2.Milliseconds >=
(SELECT AVG(Milliseconds) AS promedioDuracion
FROM Track t)

-- Adem´as, obtener la sumatoria de la duraci´on de todas esas pistas en minutos.
SELECT SUM(Milliseconds)/(1000*60) as DuracionEnMinutosTotal
FROM Track t2
WHERE t2.Milliseconds >=
(SELECT AVG(Milliseconds) AS promedioDuracion
FROM Track t)

-- QUERY 8. (a) Crear una vista que devuelva las playlists que tienen al menos una
-- pista del g´enero “Rock”.
SELECT DISTINCT PlaylistId
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId
INNER JOIN Genre g on g.GenreId = t.GenreId
WHERE g.Name = 'Rock'


--(b) Obtener de forma concisa la cantidad de playlists que no poseen
--pistas de dicho g´enero.
SELECT pl2.PlaylistId
FROM Playlist pl2
WHERE pl2.PlaylistId NOT IN

(SELECT DISTINCT PlaylistId
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId
INNER JOIN Genre g on g.GenreId = t.GenreId
WHERE g.Name = 'Rock')

-- QUERY 9 Obtener las playlists m´as caras. (Ayuda: primero obtener el ‘precio’
-- de cada playlist.)


SELECT DISTINCT pl2.PlaylistId 
FROM PlaylistTrack pl2
WHERE pl2.PlaylistId NOT IN

(SELECT DISTINCT aux1.PlaylistId
FROM
(SELECT plt.PlaylistId, SUM(t.UnitPrice) as precioTodaPlaylist
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId
GROUP BY plt.PlaylistId) AS aux1
CROSS JOIN 
(SELECT plt.PlaylistId, SUM(t.UnitPrice) as precioTodaPlaylist
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId
GROUP BY plt.PlaylistId) AS aux2
WHERE aux1.precioTodaPlaylist < aux2.precioTodaPlaylist) 


-- Auxiliar para el 9 
SELECT plt.PlaylistId, SUM(t.UnitPrice) as precioTodaPlaylist
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId
GROUP BY plt.PlaylistId