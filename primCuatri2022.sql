
-- 1 Obtener la cantidad de álbumes por género.
SELECT AUX2.GenreId, g2.Name,aux2.CantidadAlbumesConTrackDeGenero
FROM
(SELECT aux1.GenreId, COUNT(aux1.AlbumId) as CantidadAlbumesConTrackDeGenero
FROM
(SELECT DISTINCT g.GenreId, al.AlbumId
FROM Track t
INNER JOIN Album al on t.AlbumId = al.AlbumId
INNER JOIN Genre g on t.GenreId = g.GenreId) as aux1
GROUP BY aux1.GenreId) as aux2
INNER JOIN Genre g2 on g2.GenreId = aux2.GenreId

-- 2 Encontrar las facturas que tengan un importe total mayor al promedio de todas las facturas(invoices).
SELECT * 
FROM Invoice inv2 
WHERE
inv2.Total >
(SELECT AVG(inv.Total) as facturaPromedio
FROM Invoice inv)

-- 3 Obtener el género de los tracks que están contenidos en la mayor cantidad de playlist.
SELECT DISTINCT g.Name
FROM
(SELECT plt.TrackId, COUNT(plt.PlaylistId) as cantidadPlaylists
FROM PlaylistTrack plt
GROUP BY plt.TrackId) as aux1
INNER JOIN Track t on t.TrackId = aux1.TrackId
INNER JOIN Genre g on t.GenreId = g.GenreId 
WHERE aux1.cantidadPlaylists >= 
    (SELECT MAX(trackCantidadPlay.cantidadPlaylists) as MaxCantPlay
    FROM
    (SELECT plt.TrackId, COUNT(plt.PlaylistId) as cantidadPlaylists
    FROM PlaylistTrack plt
    GROUP BY plt.TrackId) as trackCantidadPlay)

-- 4 Encontrar los nombres de géneros para los cuales sus tracks fueron vendidos más de dos veces.
SELECT DISTINCT g.Name
FROM
(SELECT TrackId, COUNT(InvoiceLineId) as CantidadCompras
FROM InvoiceLine invl
GROUP BY TrackId) as trackCompra
INNER JOIN Track t on t.TrackId = trackCompra.TrackId
INNER JOIN Genre g on g.GenreId = t.GenreId
WHERE trackCompra.CantidadCompras >= 2

-- 5 Realizar una consulta correlacionada que me devuelva, si es que lo hubiera, todos las playlists que tengan algún track del álbum “Afrociberdelia”.
SELECT DISTINCT plt.PlaylistId
FROM Track t 
INNER JOIN Album alb on alb.AlbumId = t.AlbumId
INNER JOIN PlaylistTrack plt on plt.TrackId = t.TrackId
WHERE alb.Title = 'Afrociberdelia'

-- 6 Listar las playlists cuyos tracks sean de no más que dos álbumes.
SELECT pl.PlaylistId, pl.Name
FROM
(SELECT PlaylistAlbum.PlaylistId, COUNT(PlaylistAlbum.AlbumId) as CantidadAlbumesDistintos
FROM
(SELECT DISTINCT plt.PlaylistId, t.AlbumId
FROM PlaylistTrack plt
INNER JOIN Track t on t.TrackId = plt.TrackId) as PlaylistAlbum
GROUP BY PlaylistAlbum.PlaylistId) as playCantAlb
INNER JOIN Playlist pl on pl.PlaylistId = playCantAlb.PlaylistId
WHERE playCantAlb.CantidadAlbumesDistintos <= 2

