/*Each patient needs to be assigned a zip code on the basis of most common zip code of the patient?s visit provider.*/
libname one "/schhome/users/QiaohongHu";
libname two "/schaeffer-a/data";

proc sql;
	create table want as
		select count(facility_location) as comzip,facility_location,providerid,year(admit_date) as prov_year
		from two.encounter
		group by providerid,facility_location,prov_year
		order by providerid,comzip desc,prov_year desc
		;
quit;

data want1;
set want;
by providerid descending comzip descending prov_year;
if first.providerid;
keep facility_location providerid;
run;
