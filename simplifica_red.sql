-- Nota: en mayusculas se indican lo campos que pueden variar 
-- RED_1 = red sin simplificar
-- RED_2 = red simplificada

--- preparacion de tabla de PUNTOS
--- centroide ciudades 
create table CENTROIDE_POLIGONOS as 
select id, st_centroid (geom) as geom
from POLIGONOS


--- agrega valores de distancia a la RED_1 ---- 
alter table RED_1 add column length float;
update RED_1 set length = st_length(geom)

--------- asigna costos o jerarquias a RED_1
Update RED_1 set --este qry es para red vial-- 
costo = case 
when(   --carreteras de cuota, con mas de 2 carriles estatales o federales ---      
	estatus = 'Habilitado'       
	and tipo_vial = 'Carretera'  	  
	and cond_pav = 'Con pavimento'      
	and carriles::int > 3	  
	and peaje = 'Si'      
	and condicion = 'En operacion'      
	and administra = 'Federal' 
	or administra = 'Estatal'      
	and velocidad::int > 70 ) then 1
when( --caminos con mas de 2 carriles estatales o federales ---	      
	estatus = 'Habilitado'       
	and tipo_vial = 'Camino' 	  
	and cond_pav = 'Con pavimento'      
	and recubri = 'Asfalto' 
	or recubri = 'Concreto'      
	and carriles::int > 2     
	and condicion = 'En operacion'     
	and administra = 'Federal' 
	or administra = 'Estatal') then 2	  
else 3  
end;

-- Topología RED_1
alter table RED_1 add column source integer;
alter table RED_1 add column target integer;
 
select pgr_createTopology ('RED_1', 0.0001, 'geom', 'id');
select pgr_analyzeGraph('RED_1', .0001,'geom', 'id','source','target')

---asgnacion de puntos al nodo más cercano de la RED_1 
alter table PUNTOS add column nodo int;	
update PUNTOS set nodo = foo.closest_node
	from
 	(select c.id as PUNTO, 
	(select n.id
  	from RED_1_vertices_pgr as n
  	order by c.geom <-> n.the_geom LIMIT 1)as closest_node
	from  PUNTOS c) as foo
where foo.PUNTO = PUNTOS.id

--- simplificar la red
create table RED_2 as 
(
select * from pgr_dijkstra('select id, source, target, costo as cost from red',
	array(select nodo from PUNTOS),
	array(select nodo from PUNTOS) 
	directed:=false))

select r.*, foo.edge
from	 
(select distinct edge from RED_2) as foo
join red r 
on r.id = foo.edge

---recalcula la topologia de la RED_2
alter table RED_2 add column source int; 
alter table RED_2 add column target int;
select pgr_createTopology ('RED_2', 0.0001, 'geom', 'id');
 
---Interseccion de caminos con ciudades
select rp.id, rp.geom 
from RED_2 as r2
join (select * from POLIGONOS where id = '11') as p
on st_crosses (r2.geom, p.geom)

---- mejora el calculo del numero de segmentos que cruzan por un poligono de ciudad ---
update ciudades 
set grado_carretera = j.count
from
(select h.id_c, count(h.nombre)
from
(select gu.id_c, nombre
from
(select c.id as id_c, rp.id, rp.geom, rp.nombre, rp.codigo from red_primaria as rp
join ciudades as c
on st_crosses (rp.geom, c.geom)) as gu 
group by nombre, id_c ) as h
group by id_c) as j
where ciudades.id = j.id_c

------ asigna el grado de conectividad
update parques_industriales set grado_ferrocarril=g.cnt
from
(select f.id_parque, c.cnt
from 
(select p.id as id_parque, (
select n.id 
from via_ferrea_vertices_pgr As n
order by p.geom <-> n.the_geom LIMIT 1
)as closest_node 
from  
(select * from parques_industriales 
where grado_ferrocarril is null ) as p ) as f
join via_ferrea_vertices_pgr as c
on c.id = f.closest_node) as g
where g.id_parque = parques_industriales.id

update parques_industriales set grado_total = grado_carretera + grado_ferrocarril







