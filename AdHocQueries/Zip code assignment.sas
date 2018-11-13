/*Each patient needs to be assigned a zip code on the basis of most common zip code of the patient?s visit provider.*/
libname output "/sch/QiaohongHu/Opioid";
libname indata "/sch/data";

proc sql;
	create table want as
		select count(facility_location) as comzip,facility_location,providerid,year(admit_date) as prov_year
		from indata.encounter
		group by providerid,facility_location,prov_year
		order by providerid,comzip desc,prov_year desc
		;
quit;

data want1;
	set want;
	by providerid descending comzip descending prov_year;
	if first.providerid;
run;

proc sql;
	create table pat as
		select encounter.patid,providerid,want1.facility_location
		from indata.encounter want1
		where encounter.providerid=want1.providerid
		order by patid;
quit;

proc sql;
	create table pat1 as
		select count(facility_location) as count,patid,providerid,facility_location
		from pat
		group by patid,providerid,facility_location
		order by patid,count desc;
quit;

data output.profilling2;
	set pat1;
	by patid;
	if first.patid;
	keep patid facility_location;
run;
