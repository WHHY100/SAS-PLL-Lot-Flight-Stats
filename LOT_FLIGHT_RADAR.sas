%let downloadFile =  "/home/u45585517/sasuser.v94/FLIGHT_RADAR_LOT/DATA/driving_license.csv";

filename tempFile &downloadFile encoding="utf-8";
proc http
url='https://whhy.ct8.pl/FLIGHT_LOT/FILES_CSV/all_data_flight.csv'
method="get" out=tempFile;
run;

proc import datafile=&downloadFile
out=tab_entry
dbms=csv
replace;
delimiter=';';
run;

data tab_entry_date_flight;
retain flight_date;
format flight_date date9.;
set tab_entry;
flight_date = datepart(datetime);
run;

/*simple stats*/
proc sql;
create table tab_stats_flight_per_day as
select
	flight_date
	,count(*) as flights_per_day
from tab_entry_date_flight
group by flight_date
order by flight_date
;quit;

proc sql;
create table tab_stats_flight_per_plane as
select
	substr(model_plane, 1, index(model_plane, '(')-2) as model_plane_name
	,count(*) as count_plane
from tab_entry_date_flight
where
	/*missing data*/
	model_plane <> 'null'
group by model_plane
;quit;

proc sql;
create table tab_stats_flight_per_city_start as
select
	city_start
	,count(*) as count_city_start
from tab_entry_date_flight
group by city_start
;quit;

proc sql;
create table tab_stats_flight_per_city_end as
select
	city_end
	,count(*) as count_city_end
from tab_entry_date_flight
where
	/*missing data*/
	city_end <> 'false'
group by city_end
;quit;
/*end simple stats*/

/*use distance determination service (distance.to) to determine the distance beetwen 
city A and B*/

/*lib with saving distance*/
libname datadist "/home/u45585517/sasuser.v94/FLIGHT_RADAR_LOT/DATA";

data tab_city_link_all;
set tab_entry_date_flight;
link = cats("https://pl.distance.to/", city_start, "/", city_end);
where city_end <> 'false';
run;

/*cities that are not in the archive*/
proc sql;
create table tab_city_link as
select
	a.*
from tab_city_link_all a
where
	catx(' ', a.city_start, a.city_end) not in (
		select catx(' ', city_start, city_end) from  datadist.tab_data_distance
	)
;quit;

/*add id*/
data tab_city_link;
retain id;
set tab_city_link;
id = _n_;
run;

proc sql noprint;
select max(id) into: maxId from tab_city_link
;quit;

%macro takeDistance(maxId);
%do i = 1 %to &maxId;
%put loop number: &i;
	proc sql noprint;
	select cats("'", link, "'") into: linkDistance from tab_city_link where id = &i;
	;quit;
	
	filename src temp;
	proc http
	url=&linkDistance
	method="get" out=src;
	run;
	
	data html_code;
	infile src length=len;
	input line $varying32767. len;
	line=strip(line);
	run;
	
	data tab_distance;
	set html_code;
	line_clean = tranwrd(line, '<span class="headerAirline">Odległość: <span class=', '');
	line_clean = tranwrd(line_clean, "</span> <span class='unit km'>km</span></span>", '');
	line_clean = tranwrd(line_clean, "'value km'>", '');
	line_clean = tranwrd(line_clean, '.', '');
	line_clean = compress(strip(tranwrd(line_clean, ',', '.')));
	distance = round(input(line_clean, 10.), .01);
	where line contains('<span class="headerAirline">Odległość:');
	run;
	
	%if &i = 1 %then %do;
		proc sql;
		create table tab_distance_id as
		select
			&i as id
			,distance
		from tab_distance
		;quit;
	%end;
	%else %do;
		proc sql;
		create table tab_distance_id_new as
		select
			&i as id
			,distance
		from tab_distance
		;quit;
		
		data tab_distance_id;
		set tab_distance_id tab_distance_id_new;
		run;
	%end;
	
	/*to fast to get request from http server - solved by sleep function*/
	data _null_;
	rc=SLEEP(0.5);
	run;
%end;

proc sql;
create table tab_distance_save as
select
	a.city_start
	,a.city_end
	,b.distance
from tab_city_link a
left join tab_distance_id b on a.id = b.id
where a.city_end <> 'false'
;quit;

%mend;

%takeDistance(&maxId);

/*use proc sql, union all and distinct to remove duplicats from archive*/
proc sql;
create table tab_distance_work as
select distinct * from 
(
	select * from datadist.tab_data_distance
	union all
	select * from tab_distance_save
)
;quit;

data datadist.tab_data_distance;
set tab_distance_work;
where distance ne .;
run;

proc sql;
create table tab_flight_distance_fin as
select
	a.*
	,b.distance as distance_km
from tab_entry_date_flight a
left join datadist.tab_data_distance b on a.city_start = b.city_start and 
										  a.city_end = b.city_end
where 
	a.city_end <> 'false' and b.distance is not null
;quit;
/*end determining distance*/

/*mean distance by plane*/
proc sql;
create table tab_mean_distance_plane as
select
	substr(model_plane, 1, index(model_plane, '(')-2) as model_plane_name
	,round(mean(distance_km), .01) as mean_distance_km
from tab_flight_distance_fin
group by model_plane
;quit;
/*end mean distance*/

/*the most popular travel destination by plane*/
proc sql;
create table tab_trvl_dest_by_plane as
select
	substr(model_plane, 1, index(model_plane, '(')-2)  as model_plane_name
	,city_start
	,city_end
	,count(city_end) as count_of_flights
from tab_flight_distance_fin
where
	city_start = 'Warsaw'
group by model_plane, city_start, city_end
order by model_plane
;quit;

proc sql;
create table tab_most_popular_dest_plane as
select
	a.*
	,b.distance as distance_km
from tab_trvl_dest_by_plane a
left join datadist.tab_data_distance b on a.city_start = b.city_start and 
										  a.city_end = b.city_end
group by model_plane_name
having count_of_flights = max(count_of_flights)
order by model_plane_name
;quit;
/*end*/

/*export img*/
%let pathImgExport = "/home/u45585517/sasuser.v94/FLIGHT_RADAR_LOT/img";

%macro createChartHbar(imgName, titlePlot, clrPlot, xName, dataPlot, cY, cX, order, showLabel);
	ods graphics on/ reset=index imagename=&imgName imagefmt=jpg;
	ods listing gpath=&pathImgExport;
	proc sgplot data = &dataPlot;
	title color="#0000ff" &titlePlot;
	hbar &cY / response=&cX dataskin=crisp 
	
	%if &showLabel = 1 %then %do;
		datalabel
	%end;
	
	%if &order = 1 %then %do;
		categoryorder=RespDesc
	%end;
	
	fillattrs=(color=&clrPlot);
	xaxis label = &xName;
	yaxis grid display=(nolabel);
	run;
	ods graphics off;
	ods listing close;
%mend;

%createChartHbar(
	'STATS_FLIGHTS_PER_DAY', 
	'LOT flights stats at 12:00 p.m.', 
	'#0000ff',
	'Number of flights per day',
	tab_stats_flight_per_day,
	flight_date,
	flights_per_day,
	0,
	1
);
	
%createChartHbar(
	'STATS_FLIGHTS_PER_PLANE', 
	'LOT flying plane at 12:00 p.m.', 
	'#0000ff',
	'Count of type plane',
	tab_stats_flight_per_plane,
	model_plane_name,
	count_plane,
	1,
	1
);

%createChartHbar(
	'STATS_FLIGHTS_PER_CITY_START', 
	'LOT flying plane by start city at 12:00 p.m.', 
	'#0000ff',
	'Count of city start',
	tab_stats_flight_per_city_start,
	city_start,
	count_city_start,
	1,
	0
);

%createChartHbar(
	'STATS_FLIGHTS_PER_CITY_END', 
	'LOT flying plane by end city at 12:00 p.m.', 
	'#0000ff',
	'Count of city end',
	tab_stats_flight_per_city_end,
	city_end,
	count_city_end,
	1,
	0
);

%createChartHbar(
	'MEAN_DISTANCE_PER_PLANE', 
	'Mean distance by model plane in PLL LOT', 
	'#0000ff',
	'Mean distance (km)',
	tab_mean_distance_plane,
	model_plane_name,
	mean_distance_km,
	1,
	1
);

data tab_tmp_export_img;
expPathEntr = &pathImgExport;
expPathOut = cats(expPathEntr, '/', 'POPULAR_DESTINATION_FLIGHTS.jpg');
run;

proc sql noprint;
select cats('"', expPathOut, '"') into: imgProcPrintExp from tab_tmp_export_img
;quit;

title color="#0000ff" "The most popular destination of flights PLL LOT";
ods graphics on / width=672px imagefmt=jpg imagemap=on imagename="POPULAR_DESTINATION_FLIGHTS" border=off;
options printerpath=png nodate nonumber;
ods printer file=&imgProcPrintExp style=barrettsblue;
proc print noobs data=tab_most_popular_dest_plane;
run;
ods printer close;