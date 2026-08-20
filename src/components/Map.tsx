import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import { divIcon } from "leaflet";
import "leaflet/dist/leaflet.css";

const position: [number, number] = [45.8150, 15.9819]; // Zagreb

// Leaflet's default marker resolves marker-icon.png relative to the document and the
// bundler never emits it there, so every pin renders as a broken image. An inline SVG
// has no asset to resolve. className is cleared because Leaflet otherwise wraps a
// divIcon in .leaflet-div-icon, which paints a white box behind the pin.
const pinIcon = divIcon({
  className: "",
  html:
    '<svg xmlns="http://www.w3.org/2000/svg" width="28" height="40" viewBox="0 0 28 40">' +
    '<path d="M14 1C6.8 1 1 6.8 1 14c0 9.8 13 25 13 25s13-15.2 13-25c0-7.2-5.8-13-13-13z" ' +
    'fill="#00FF55" stroke="#0B1F12" stroke-width="1.5"/>' +
    '<circle cx="14" cy="14" r="5" fill="#0B1F12"/>' +
    "</svg>",
  iconSize: [28, 40],
  iconAnchor: [14, 40],
  popupAnchor: [0, -36],
});

export default function Map({ products }: { products: any[] }) {
  return (
    <MapContainer
      center={position}
      zoom={8}
      style={{ height: "520px", width: "100%" }}

    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      {products?.filter((p) => p?.latitude != null && p?.longitude != null).map((p) => (

        <Marker
          key={p.advertisementId}
          position={[p.latitude, p.longitude]}
          icon={pinIcon}
        >
          <Popup>
            <a href={`/advertisement/${p.advertisementId}`}>
              <strong className="text-black">{p.itemName ?? "Oglas"}</strong>
            </a>
            <br />
            {p.advertisementLocationTakeover ?? ""}
          </Popup>
        </Marker>

      ))}
    </MapContainer>
  );
}
