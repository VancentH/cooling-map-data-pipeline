# cooling-map-data-pipeline

A automated pipeline that fetches locations of air-conditioned facilities
in Saxony (Sachsen), Germany from OpenStreetMap and exports them as GeoJSON.

---

## Data Attribution

This project uses data from **[OpenStreetMap](https://www.openstreetmap.org/)**.

> © OpenStreetMap contributors

OpenStreetMap data is made available under the
**[Open Database License (ODbL) v1.0](https://opendatacommons.org/licenses/odbl/1-0/)**.

Any **derivative data** produced by this pipeline (e.g. the exported GeoJSON files)
is also subject to the ODbL. This means:

- You must **attribute** OpenStreetMap and its contributors.
- Any further distribution of the data (or derivatives) must remain under the **same ODbL license** (share-alike).
- You may not apply additional legal or technological restrictions that limit these rights.

For the full copyright notice, see: <https://www.openstreetmap.org/copyright>

---

## License

| What | License |
|------|---------|
| **Source code** (scripts, workflows, config) | [MIT](./LICENSE) |
| **Output data** (GeoJSON derived from OSM) | [ODbL v1.0](https://opendatacommons.org/licenses/odbl/1-0/) |

The MIT License applies **only to the code** in this repository.
All data files produced by this pipeline inherit the ODbL from OpenStreetMap
and must be treated accordingly — they are **not** covered by MIT.

