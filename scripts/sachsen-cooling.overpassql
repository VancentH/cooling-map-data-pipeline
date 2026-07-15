[out:json][timeout:90];
area["name"="Sachsen"]["boundary"="administrative"]["admin_level"="4"]->.searchArea;
(
  nwr["air_conditioning"="yes"](area.searchArea);
  nwr["shop"="mall"](area.searchArea);
  nwr["amenity"="cinema"](area.searchArea);
  nwr["shop"="department_store"](area.searchArea);
  nwr["shop"="supermarket"](area.searchArea);
);

out center;