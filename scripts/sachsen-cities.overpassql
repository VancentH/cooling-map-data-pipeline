[out:json][timeout:120];
area["name"="Sachsen"]["boundary"="administrative"]["admin_level"="4"]->.searchArea;
(
  relation["boundary"="administrative"]["admin_level"="6"](area.searchArea);
  relation["boundary"="administrative"]["admin_level"="8"](area.searchArea);
);
out tags center;
