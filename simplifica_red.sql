-- Nota: en mayusculas se indican lo campos que pueden variar 
-- red = red sin simplificar
-- red_2 = red simplificada

--- preparacion de tabla de nodos
--- centroide ciudades 
create table puntos_ciudades as 
select id, st_centroid (geom) as geom
from ciudades

create table nodos as (select id, geom from puntos_ciudades);
alter table nodos add column tipo_nodo text;
update nodos set tipo_nodo = 'ciudad'

INSERT INTO nodos (id, geom, tipo_nodo) 
SELECT id, geom, tipo_nodo
from
(select rp.id, rp.geom, rp.tipo_nodo from 
(select * from terminal_carrusel) as rp
left join (select * from ciudades) as c
on st_intersects (rp.geom, c.geom) 
where c.id is null) as tc


INSERT INTO nodos (id, geom, tipo_nodo) 
SELECT id, geom, tipo_nodo
from
(select rp.id, rp.geom, rp.tipo_nodo from 
(select * from puertos_imp) as rp
left join (select * from ciudades) as c
on st_intersects (rp.geom, c.geom) 
where c.id is null ) as pu

INSERT INTO nodos (id, geom, tipo_nodo) 
SELECT id, geom, tipo_nodo
from
(select rp.id, rp.geom, rp.tipo_nodo from 
(select * from parques) as rp
left join (select * from ciudades) as c
on st_intersects (rp.geom, c.geom) 
where c.id is null ) as pi

--- costos red base
--- Calcula la longitud de los de la red ---- 
alter table red add column length float;
update red set length = st_length(geom)

--- Asigna costos o jerarquias 
Update red set --este qry es para red vial-- 
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

-- Topología red
alter table red add column source integer;
alter table red add column target integer;
 
select pgr_createTopology ('red', 0.0001, 'geom', 'id');

--select pgr_analyzeGraph('red', .0001,'geom', 'id','source','target')

---asgnacion de cada punto de la tabla nodos al nodo más cercano de la red 
alter table nodos add column nodo int;	
update nodos set nodo = foo.closest_node
	from
 	(select c.id as nodo, 
	(select n.id
  	from red_vertices_pgr as n
  	order by c.geom <-> n.the_geom LIMIT 1)as closest_node
	from  nodos c) as foo
where foo.nodo = nodos.id

--- simplificar la red
create table red_2 as 
select r.*, foo.edge
from	 
(select distinct edge 
from 
(select * from pgr_dijkstra('select id, source, target, costo as cost from red',
	array(select nodo from nodos),
	array(select nodo from nodos), 
	directed:=false)) as i) as foo
join red r 
on r.id = foo.edge

---recalcula la topologia de la red_2
alter table red_2 add column source int; 
alter table red_2 add column target int;
select pgr_createTopology ('red_2', 0.0001, 'geom', 'id');
 
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







