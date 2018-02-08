--CREA RED--

alter table red_primaria add column source integer;
alter table red_primaria add column target integer;

--CREA LA TOPOLOGIA--
 
select pgr_createTopology ('red_primaria', 0.0001, 'geom', 'id');
 
 

create table centro_ciudades as select id, st_centroid (geom) as geom
 from ciudades



alter table centro_ciudades add column nodo int;
	
update centro_ciudades set nodo = foo.closest_node
	
from
 (select c.id as ciudad, (
SELECT n.id
  FROM red_primaria_vertices_pgr 
As n
  ORDER BY c.geom <-> n.the_geom LIMIT 1
)as closest_node

from  centro_ciudades c) as foo

where foo.ciudad = centro_ciudades.id



select * from centro_ciudades


ALTER TABLE cultivo
    
ALTER COLUMN geom
  
TYPE Geometry(MultiPoint, 32615)
   
USING ST_Transform(geom, 32615);
	





alter table red_primaria add column length float;

update red_primaria set length = st_length(geom)



create table intento as 
(
SELECT * FROM pgr_dijkstra(
'select id, source, target, length as cost from red_primaria',
    
		array(select nodo from centro_ciudades),
    
		array(select nodo from centro_ciudades),
	 
		directed:=false))

select r.*, foo.edge
		
from	 
		
(select distinct edge from intento)as foo

		in red_primaria r
on r.id = foo.edge
